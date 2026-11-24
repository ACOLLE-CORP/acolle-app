import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    hide NotificationSettings;
import 'package:flutter/foundation.dart';

import '../shared/acolle_design.dart';

class NotificacaoService {
  NotificacaoService._();

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  static StreamSubscription<String>? _tokenSubscription;
  static Future<void> _fila = Future.value();
  static bool suspenderLembretes = false;

  static bool get _suportaAlarmes =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> inicializar() async {
    if (!_suportaAlarmes) return;
    await Alarm.init();
    // Aviso mostrado quando o app é fechado: troca o texto padrão em inglês
    // ("Your alarms may not ring") por uma mensagem simples em português.
    await Alarm.setWarningNotificationOnKill(
      'Abra o Acolle novamente',
      'O app foi fechado. Toque aqui para abrir e garantir que '
          'seus lembretes de remédio toquem.',
    );
  }

  static Future<void> _serializar(Future<void> Function() tarefa) {
    final operacao = _fila.then((_) => tarefa());
    _fila = operacao.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operacao;
  }

  static Future<void> cancelarTodosLembretes() {
    if (!_suportaAlarmes) return Future.value();
    return _serializar(Alarm.stopAll);
  }

  static Future<void> cancelarLembrete(String uid, String docId) {
    if (!_suportaAlarmes) return Future.value();
    return _serializar(() async {
      final prefixo = 'remedio:$uid:$docId:';
      for (final alarme in await Alarm.getAlarms()) {
        if (alarme.payload?.startsWith(prefixo) == true) {
          if (!await Alarm.stop(alarme.id)) {
            throw StateError('Não foi possível cancelar o alarme.');
          }
        }
      }
    });
  }

  static Future<void> sincronizarLembretes(String uid) {
    if (!_suportaAlarmes) return Future.value();
    return _serializar(() async {
      if (suspenderLembretes || FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('remedios')
          .where('usuarioId', isEqualTo: uid)
          .get(const GetOptions(source: Source.server));
      if (suspenderLembretes || FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      final agora = DateTime.now();
      final desejados = <String, ({String nome, DateTime data})>{};
      final ativos = <String>{};
      for (final doc in snapshot.docs) {
        final dados = doc.data();
        if (dados['ativo'] == false || dados['frequencia'] == 'Sob demanda') {
          continue;
        }
        final horario = dados['horario'];
        final nome = dados['nome'];
        if (horario is! String || nome is! String) continue;
        final ancora = dados['criadoEm'];
        final prefixo = 'remedio:$uid:${doc.id}:';
        ativos.add(prefixo);
        for (final data in proximasOcorrencias(
          horario: horario,
          frequencia: dados['frequencia']?.toString() ?? 'Diário',
          ancora: ancora is Timestamp ? ancora.toDate() : agora,
          agora: agora,
        )) {
          desejados['$prefixo${data.millisecondsSinceEpoch}'] = (
            nome: nome,
            data: data,
          );
        }
      }

      final existentes = await Alarm.getAlarms();
      final usados = existentes.map((alarme) => alarme.id).toSet();
      final tocando = Alarm.ringing.value.alarms
          .map((alarme) => alarme.id)
          .toSet();
      for (final alarme in existentes) {
        final chave = alarme.payload;
        if (chave != null) {
          final desejado = desejados[chave];
          if (desejado != null &&
              alarme.dateTime == desejado.data &&
              alarme.notificationSettings.body == _mensagem(desejado.nome)) {
            desejados.remove(chave);
            continue;
          }
          final separador = chave.lastIndexOf(':');
          if (separador >= 0 &&
              ativos.contains(chave.substring(0, separador + 1)) &&
              (tocando.contains(alarme.id) ||
                  alarme.dateTime.isAfter(
                        agora.subtract(const Duration(minutes: 1)),
                      ) &&
                      !alarme.dateTime.isAfter(agora))) {
            continue;
          }
        } else if (tocando.contains(alarme.id)) {
          // Um alarme da versão anterior ainda pode estar tocando na migração.
          continue;
        }
        if (!await Alarm.stop(alarme.id)) {
          throw StateError('Não foi possível cancelar o alarme.');
        }
      }

      // Os IDs são locais ao aparelho. O payload identifica cada ocorrência
      // entre sessões e permite manter alarmes que já estão agendados.
      var id = 10000000;
      final novos = desejados.entries.toList()
        ..sort((a, b) => a.value.data.compareTo(b.value.data));
      for (final entrada in novos) {
        if (suspenderLembretes ||
            FirebaseAuth.instance.currentUser?.uid != uid) {
          return;
        }
        if (!entrada.value.data.isAfter(DateTime.now())) continue;
        while (usados.contains(id)) {
          id++;
        }
        final alarme = AlarmSettings(
          id: id++,
          dateTime: entrada.value.data,
          payload: entrada.key,
          assetAudioPath: 'assets/alarme.mp3',
          androidStopAlarmOnTermination: false,
          allowSameSecondScheduling: true,
          allowAlarmOverlap: true,
          volumeSettings: const VolumeSettings.fixed(
            volumeEnforced: false,
            showSystemUI: false,
          ),
          notificationSettings: NotificationSettings(
            title: 'Hora do remédio 💊',
            body: _mensagem(entrada.value.nome),
            stopButton: 'Já tomei',
            iconColor: AcolleDesign.roxo,
          ),
        );
        try {
          final agendado = await Alarm.set(alarmSettings: alarme);
          if (!agendado) throw StateError('Não foi possível agendar o alarme.');
        } catch (_) {
          await Alarm.stop(alarme.id);
          rethrow;
        }
      }
    });
  }

  static String _mensagem(String nome) => 'Está na hora de tomar: $nome';

  @visibleForTesting
  static List<DateTime> proximasOcorrencias({
    required String horario,
    required String frequencia,
    required DateTime ancora,
    required DateTime agora,
  }) {
    final partes = horario.split(':');
    if (partes.length != 2 || frequencia == 'Sob demanda') return [];
    final hora = int.tryParse(partes.first);
    final minuto = int.tryParse(partes.last);
    if (hora == null ||
        hora < 0 ||
        hora > 23 ||
        minuto == null ||
        minuto < 0 ||
        minuto > 59) {
      return [];
    }

    final inicio = ancora.toLocal();
    var primeiroDia = DateTime(
      inicio.year,
      inicio.month,
      inicio.day,
      hora,
      minuto,
    );
    if (primeiroDia.isBefore(inicio)) {
      primeiroDia = DateTime(
        inicio.year,
        inicio.month,
        inicio.day + 1,
        hora,
        minuto,
      );
    }
    if (frequencia == 'Semanal') {
      final diasAte = (primeiroDia.weekday - agora.weekday) % 7;
      var proximo = DateTime(
        agora.year,
        agora.month,
        agora.day + diasAte,
        hora,
        minuto,
      );
      if (!proximo.isAfter(agora)) {
        proximo = DateTime(
          proximo.year,
          proximo.month,
          proximo.day + 7,
          hora,
          minuto,
        );
      }
      return List.generate(
        8,
        (semana) => DateTime(
          proximo.year,
          proximo.month,
          proximo.day + semana * 7,
          hora,
          minuto,
        ),
      );
    }

    final intervalo = switch (frequencia) {
      'A cada 8 horas' => 8,
      'A cada 12 horas' => 12,
      _ => 24,
    };
    return [
          for (var dia = 0; dia <= 15; dia++)
            for (var fase = 0; fase < 24 ~/ intervalo; fase++)
              DateTime(
                agora.year,
                agora.month,
                agora.day + dia,
                (hora % intervalo) + fase * intervalo,
                minuto,
              ),
        ]
        .where((data) => data.isAfter(agora) && !data.isBefore(primeiroDia))
        .take(14 * (24 ~/ intervalo))
        .toList();
  }

  static Future<void> pararRegistroToken() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }

  static Future<String?> registrarTokenUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return null;
    }

    final perfil = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid);
    final token = await _messaging.getToken();
    if (FirebaseAuth.instance.currentUser?.uid != user.uid) return null;
    if (token != null) await perfil.update({'fcmToken': token});

    await pararRegistroToken();
    _tokenSubscription = _messaging.onTokenRefresh.listen((novoToken) async {
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
      try {
        await perfil.update({'fcmToken': novoToken});
      } on FirebaseException catch (erro) {
        debugPrint('Falha ao atualizar token de notificações: ${erro.code}');
      }
    });
    return token;
  }

  static Future<void> inscreverTopicoSeguranca() async {
    await _messaging.subscribeToTopic('avisos_seguranca');
  }
}

@pragma('vm:entry-point')
Future<void> notificacaoBackgroundMessageHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('Background message recebida: ${message.messageId}');
  }
}
