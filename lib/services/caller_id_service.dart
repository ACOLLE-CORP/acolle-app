import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:phone_state/phone_state.dart';

/// Usa a lista de suspeitos sincronizada no Android e grava o histórico.
class CallerIdService {
  static StreamSubscription? _subscription;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _suspeitosSubscription;
  static const _canalNativo = MethodChannel('acolle/caller_id');
  static bool suspenderHistorico = false;

  static Future<void> iniciarMonitoramento(
    Function(String numero) onNumeroSuspeito,
  ) async {
    await _subscription?.cancel();
    _subscription = PhoneState.stream.listen((event) async {
      if (event.status == PhoneStateStatus.CALL_INCOMING &&
          event.number != null) {
        final numero = event.number!.trim();
        if (normalizarNumero(numero).isEmpty) return;
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null || suspenderHistorico) return;
        final suspeito = await _verificarNumero(numero);
        if (suspenderHistorico ||
            FirebaseAuth.instance.currentUser?.uid != uid) {
          return;
        }

        try {
          await FirebaseFirestore.instance.collection('chamadas').add({
            'usuarioId': uid,
            'numero': numero,
            'suspeito': suspeito,
            'data': FieldValue.serverTimestamp(),
          });
        } catch (_) {}

        if (suspeito) {
          onNumeroSuspeito(numero);
        }
      }
    });
  }

  static Future<void> sincronizarNumerosSuspeitos() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_suspeitosSubscription != null) return;

    try {
      _suspeitosSubscription = FirebaseFirestore.instance
          .collection('numeros_suspeitos')
          .snapshots(includeMetadataChanges: true)
          .listen(
            (snapshot) async {
              // Um cache local vazio não invalida a última lista persistida.
              if (snapshot.metadata.isFromCache && snapshot.docs.isEmpty) {
                return;
              }
              final numeros = snapshot.docs
                  .map((doc) => doc.data()['numero']?.toString() ?? '')
                  .map(normalizarNumero)
                  .where((numero) => numero.isNotEmpty)
                  .toSet()
                  .toList();
              try {
                await _canalNativo.invokeMethod<bool>('syncSuspectNumbers', {
                  'numbers': numeros,
                });
              } on PlatformException catch (e) {
                debugPrint('Falha ao sincronizar números suspeitos: $e');
              }
            },
            onError: (Object erro) {
              debugPrint(
                'Falha ao consultar a lista de números suspeitos: $erro',
              );
            },
          );
    } on PlatformException catch (e) {
      debugPrint('Identificação nativa de chamadas indisponível: $e');
    }
  }

  static Future<bool> _verificarNumero(String numero) async {
    try {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        return false;
      }
      final argumentos = {'numero': numero};
      final salvo = await _canalNativo.invokeMethod<bool>(
        'isSavedContact',
        argumentos,
      );
      if (salvo == true) return false;
      return await _canalNativo.invokeMethod<bool>(
            'isSuspectNumberCached',
            argumentos,
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  static String normalizarNumero(String numero) {
    final digitos = numero.replaceAll(RegExp(r'\D'), '');
    final internacional =
        numero.trimLeft().startsWith('+') || digitos.startsWith('00');
    final telefone = digitos.startsWith('00') ? digitos.substring(2) : digitos;
    final tronco = RegExp(r'^(?:55)?0([1-9]\d{9,10})$').firstMatch(telefone);
    if (tronco != null) return '55${tronco[1]}';
    if (!internacional && RegExp(r'^[1-9]\d{9,10}$').hasMatch(telefone)) {
      return '55$telefone';
    }
    return telefone;
  }

  static void pararMonitoramento() {
    _subscription?.cancel();
    // A sincronização permanece ativa enquanto o usuário estiver autenticado,
    // mantendo o cache nativo atualizado mesmo ao sair da tela Home.
  }

  static void encerrarSessao() {
    pararMonitoramento();
    _suspeitosSubscription?.cancel();
    _suspeitosSubscription = null;
  }
}
