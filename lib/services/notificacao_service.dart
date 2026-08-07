import 'package:alarm/alarm.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    hide NotificationSettings;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/foundation.dart';

class NotificacaoService {
  NotificacaoService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _inicializado = false;

  static const int _diasAntecedencia = 14;
  static const int _semanasAntecedencia = 8;
  static const int _maxOcorrenciasPorLembrete = 60;

  static Future<void> inicializar() async {
    if (_inicializado) return;
    await Alarm.init();
    _inicializado = true;
  }

  static int _gerarId(String docId, int ocorrencia) {
    final base = docId.hashCode.abs() % 100000;
    return base * 100 + ocorrencia;
  }

  static Future<void> agendarLembrete({
    required String docId,
    required String nome,
    required String horario,
    required String frequencia,
  }) async {
    if (!_inicializado) {
      await inicializar();
    }

    await cancelarLembrete(docId);

    final partes = horario.split(':');
    final hora = int.parse(partes[0]);
    final minuto = int.parse(partes[1]);

    final agora = DateTime.now();

    var primeiroHorario = DateTime(
      agora.year,
      agora.month,
      agora.day,
      hora,
      minuto,
    );

    if (primeiroHorario.isBefore(agora)) {
      primeiroHorario = primeiroHorario.add(const Duration(days: 1));
    }

    switch (frequencia) {
      case 'Diário':
        await _agendarRecorrenteDias(
          docId: docId,
          nome: nome,
          primeiroHorario: primeiroHorario,
          intervaloDias: 1,
          quantidade: _diasAntecedencia,
        );
        break;

      case 'A cada 8 horas':
        await _agendarMultiplasVezesAoDia(
          docId: docId,
          nome: nome,
          primeiroHorario: primeiroHorario,
          intervaloHoras: 8,
          dias: _diasAntecedencia,
        );
        break;

      case 'A cada 12 horas':
        await _agendarMultiplasVezesAoDia(
          docId: docId,
          nome: nome,
          primeiroHorario: primeiroHorario,
          intervaloHoras: 12,
          dias: _diasAntecedencia,
        );
        break;

      case 'Semanal':
        await _agendarRecorrenteDias(
          docId: docId,
          nome: nome,
          primeiroHorario: primeiroHorario,
          intervaloDias: 7,
          quantidade: _semanasAntecedencia,
        );
        break;

      case 'Sob demanda':
        break;

      default:
        await _criarAlarme(
          id: _gerarId(docId, 0),
          nome: nome,
          dateTime: primeiroHorario,
        );
    }
  }

  static Future<void> _agendarRecorrenteDias({
    required String docId,
    required String nome,
    required DateTime primeiroHorario,
    required int intervaloDias,
    required int quantidade,
  }) async {
    for (var i = 0; i < quantidade; i++) {
      final dataHora = primeiroHorario.add(
        Duration(days: i * intervaloDias),
      );

      await _criarAlarme(
        id: _gerarId(docId, i),
        nome: nome,
        dateTime: dataHora,
      );
    }
  }
    static Future<void> _agendarMultiplasVezesAoDia({
    required String docId,
    required String nome,
    required DateTime primeiroHorario,
    required int intervaloHoras,
    required int dias,
  }) async {
    final vezesAoDia = (24 / intervaloHoras).floor();
    var ocorrencia = 0;
    final agora = DateTime.now();

    for (var dia = 0; dia < dias; dia++) {
      for (var vez = 0; vez < vezesAoDia; vez++) {
        final dataHora = primeiroHorario.add(
          Duration(
            days: dia,
            hours: vez * intervaloHoras,
          ),
        );

        if (dataHora.isBefore(agora)) continue;

        await _criarAlarme(
          id: _gerarId(docId, ocorrencia),
          nome: nome,
          dateTime: dataHora,
        );

        ocorrencia++;
      }
    }
  }

  static Future<void> _criarAlarme({
    required int id,
    required String nome,
    required DateTime dateTime,
  }) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: 'assets/alarme.mp3',
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(seconds: 3),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: 'Hora do remédio 💊',
        body: 'Está na hora de tomar: $nome',
        stopButton: 'Já tomei',
        iconColor: const Color(0xFF773FD1),
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);

    if (kDebugMode) {
      debugPrint('Alarme criado: id=$id em $dateTime');
    }
  }

  static Future<void> cancelarLembrete(String docId) async {
    for (var i = 0; i < _maxOcorrenciasPorLembrete; i++) {
      final id = _gerarId(docId, i);

      try {
        await Alarm.stop(id);
      } catch (_) {}
    }
  }

  // ============================================================
  // FIREBASE CLOUD MESSAGING
  // ============================================================

  static Future<String?> registrarTokenUsuario() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (defaultTargetPlatform == TargetPlatform.android &&
        settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return null;
    }

    final token = await _messaging.getToken();

    if (token != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .set(
        {
          'fcmToken': token,
        },
        SetOptions(merge: true),
      );
    }

    _messaging.onTokenRefresh.listen((novoToken) {
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .set(
        {
          'fcmToken': novoToken,
        },
        SetOptions(merge: true),
      );
    });

    return token;
  }
    static Future<void> inscreverTopicoSeguranca() async {
    await _messaging.subscribeToTopic('avisos_seguranca');
  }
}

@pragma('vm:entry-point')
Future<void> notificacaoBackgroundMessageHandler(
  RemoteMessage message,
) async {
  if (kDebugMode) {
    debugPrint(
      'Background message recebida: ${message.messageId}',
    );
  }
}