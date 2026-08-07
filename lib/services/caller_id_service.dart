import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phone_state/phone_state.dart';

/// Monitora chamadas recebidas em tempo real e compara o número com a coleção
/// `numeros_suspeitos` no Firestore. Dispara alerta visual e grava a chamada
/// no histórico.
class CallerIdService {
  static StreamSubscription? _subscription;

  static void iniciarMonitoramento(Function(String numero) onNumeroSuspeito) {
    _subscription = PhoneState.stream.listen((event) async {
      if (event.status == PhoneStateStatus.CALL_INCOMING && event.number != null) {
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

  static Future<bool> _verificarNumero(String numero) async {
    try {
      final resultado = await FirebaseFirestore.instance
          .collection('numeros_suspeitos')
          .where('numero', isEqualTo: numero)
          .get();

      return resultado.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static void pararMonitoramento() {
    _subscription?.cancel();
  }
}
