import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AcessibilidadeService extends ChangeNotifier {
  static final AcessibilidadeService instance = AcessibilidadeService._();

  AcessibilidadeService._();

  static const String _escalaTextoKey = 'escala_texto';
  static const String _altoContrasteKey = 'alto_contraste';

  double _escalaTexto = 1.0;
  bool _altoContraste = false;

  double get escalaTexto => _escalaTexto;
  bool get altoContraste => _altoContraste;

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();

    _escalaTexto = prefs.getDouble(_escalaTextoKey) ?? 1.0;
    _altoContraste = prefs.getBool(_altoContrasteKey) ?? false;

    notifyListeners();
  }

  Future<void> alterarEscalaTexto(double valor) async {
    _escalaTexto = valor;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_escalaTextoKey, valor);
  }

  Future<void> alterarAltoContraste(bool valor) async {
    _altoContraste = valor;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_altoContrasteKey, valor);
  }
}