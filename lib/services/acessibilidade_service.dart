import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AcessibilidadeService extends ChangeNotifier {
  AcessibilidadeService._();

  static final AcessibilidadeService instance =
      AcessibilidadeService._();

  static const String _chaveEscalaTexto = 'escala_texto';
  static const String _chaveAltoContraste = 'alto_contraste';

  double _escalaTexto = 1.0;
  bool _altoContraste = false;

  double get escalaTexto => _escalaTexto;

  bool get altoContraste => _altoContraste;

  // ============================================================
  // CARREGAR CONFIGURAÇÕES
  // ============================================================

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();

    _escalaTexto =
        prefs.getDouble(_chaveEscalaTexto) ?? 1.0;

    _altoContraste =
        prefs.getBool(_chaveAltoContraste) ?? false;

    notifyListeners();
  }

  // ============================================================
  // ALTERAR TAMANHO DA FONTE
  // ============================================================

  Future<void> alterarEscalaTexto(double novaEscala) async {
    // Limites para evitar textos pequenos demais
    // ou exageradamente grandes.
    final escala = novaEscala.clamp(0.8, 1.8);

    _escalaTexto = escala.toDouble();

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(
      _chaveEscalaTexto,
      _escalaTexto,
    );
  }

  // ============================================================
  // AUMENTAR FONTE
  // ============================================================

  Future<void> aumentarTexto() async {
    await alterarEscalaTexto(
      (_escalaTexto + 0.1).clamp(0.8, 1.8),
    );
  }

  // ============================================================
  // DIMINUIR FONTE
  // ============================================================

  Future<void> diminuirTexto() async {
    await alterarEscalaTexto(
      (_escalaTexto - 0.1).clamp(0.8, 1.8),
    );
  }

  // ============================================================
  // RESTAURAR TAMANHO PADRÃO
  // ============================================================

  Future<void> restaurarTexto() async {
    await alterarEscalaTexto(1.0);
  }

  // ============================================================
  // ALTO CONTRASTE
  // ============================================================

  Future<void> alterarAltoContraste(bool ativado) async {
    _altoContraste = ativado;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _chaveAltoContraste,
      _altoContraste,
    );
  }

  // ============================================================
  // ALTERNAR ALTO CONTRASTE
  // ============================================================

  Future<void> alternarAltoContraste() async {
    await alterarAltoContraste(
      !_altoContraste,
    );
  }

  // ============================================================
  // RESTAURAR ACESSIBILIDADE
  // ============================================================

  Future<void> restaurarPadrao() async {
    _escalaTexto = 1.0;
    _altoContraste = false;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(
      _chaveEscalaTexto,
      _escalaTexto,
    );

    await prefs.setBool(
      _chaveAltoContraste,
      _altoContraste,
    );
  }
}