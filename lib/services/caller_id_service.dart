import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:phone_state/phone_state.dart';

/// Monitora chamadas recebidas em tempo real e compara o número com a coleção
/// `numeros_suspeitos` no Firestore. Dispara alerta visual e grava a chamada
/// no histórico.
class CallerIdService {
  static StreamSubscription? _subscription;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _suspeitosSubscription;
  static const _canalNativo = MethodChannel('acolle/caller_id');

  static Future<void> iniciarMonitoramento(
    Function(String numero) onNumeroSuspeito,
  ) async {
    await _prepararIdentificadorNativo();
    await _subscription?.cancel();
    _subscription = PhoneState.stream.listen((event) async {
      if (event.status == PhoneStateStatus.CALL_INCOMING &&
          event.number != null) {
        final numero = event.number!;
        final suspeito = await _verificarNumero(numero);

        try {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            await FirebaseFirestore.instance.collection('chamadas').add({
              'usuarioId': uid,
              'numero': numero,
              'suspeito': suspeito,
              'data': FieldValue.serverTimestamp(),
            });
          }
        } catch (_) {}

        if (suspeito) {
          onNumeroSuspeito(numero);
        }
      }
    });
  }

  static Future<void> _prepararIdentificadorNativo() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final papelAtivo =
          await _canalNativo.invokeMethod<bool>('requestScreeningRole') ??
          false;
      if (papelAtivo) {
        await _canalNativo.invokeMethod<bool>('requestOverlayPermission');
      }
      await _suspeitosSubscription?.cancel();
      _suspeitosSubscription = FirebaseFirestore.instance
          .collection('numeros_suspeitos')
          .snapshots()
          .listen((snapshot) async {
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
          });
    } on PlatformException catch (e) {
      debugPrint('Identificação nativa de chamadas indisponível: $e');
    }
  }

  static Future<bool> _verificarNumero(String numero) async {
    try {
      final resultado = await FirebaseFirestore.instance
          .collection('numeros_suspeitos')
          .get();
      final procurado = normalizarNumero(numero);
      return resultado.docs.any(
        (doc) =>
            normalizarNumero(doc.data()['numero']?.toString() ?? '') ==
            procurado,
      );
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  static String normalizarNumero(String numero) {
    var digitos = numero.replaceAll(RegExp(r'\D'), '');
    if (digitos.startsWith('00')) digitos = digitos.substring(2);
    if ((digitos.length == 10 || digitos.length == 11) &&
        !digitos.startsWith('55')) {
      digitos = '55$digitos';
    }
    return digitos;
  }

  static void pararMonitoramento() {
    _subscription?.cancel();
    // A sincronização permanece ativa enquanto o usuário estiver autenticado,
    // mantendo o cache nativo atualizado mesmo ao sair da tela Home.
  }
}
