import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phone_state/phone_state.dart';

class CallerIdService {
  static StreamSubscription? _subscription;

  static void iniciarMonitoramento(Function(String numero) onNumeroSuspeito) {
    _subscription = PhoneState.stream.listen((event) async {
      if (event.status == PhoneStateStatus.CALL_INCOMING &&
          event.number != null) {
        final numero = event.number!;
        final suspeito = await _verificarNumero(numero);

        if (suspeito) {
          onNumeroSuspeito(numero);
        }
      }
    });
  }

  static Future<bool> _verificarNumero(String numero) async {
    final resultado = await FirebaseFirestore.instance
        .collection('numeros_suspeitos')
        .where('numero', isEqualTo: numero)
        .get();

    return resultado.docs.isNotEmpty;
  }

  static void pararMonitoramento() {
    _subscription?.cancel();
  }
}