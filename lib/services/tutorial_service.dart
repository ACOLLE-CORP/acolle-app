import 'package:shared_preferences/shared_preferences.dart';

/// Guarda se o usuário já concluiu (ou pulou) o tutorial de primeiro acesso.
///
/// A marca é salva por usuário (uid), para que uma segunda conta no mesmo
/// aparelho também veja o tutorial uma vez.
class TutorialService {
  static String _chave(String uid) =>
      'tutorial_primeiro_acesso_concluido_$uid';

  /// Retorna true se o tutorial já foi concluído.
  ///
  /// Em caso de erro de leitura, retorna false: é melhor mostrar o tutorial
  /// do que escondê-lo. A tela inicial só o abre uma vez por sessão.
  static Future<bool> jaConcluiu(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_chave(uid)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> marcarConcluido(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_chave(uid), true);
    } catch (_) {
      // Não bloqueia o usuário se não for possível salvar.
    }
  }

  /// Usado para testes ou para voltar a exibir o tutorial automaticamente.
  static Future<void> reiniciar(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chave(uid));
    } catch (_) {}
  }
}
