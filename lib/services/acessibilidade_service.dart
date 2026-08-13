import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AcessibilidadeService extends ChangeNotifier {
  static final AcessibilidadeService instance = AcessibilidadeService._();

  AcessibilidadeService._();

  static const String _escalaTextoKey = 'escala_texto';

  double _escalaTexto = 1.0;

  double get escalaTexto => _escalaTexto;

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();

    _escalaTexto = prefs.getDouble(_escalaTextoKey) ?? 1.0;

    notifyListeners();
  }

  Future<void> alterarEscalaTexto(double valor) async {
    _escalaTexto = valor;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_escalaTextoKey, valor);
  }
}