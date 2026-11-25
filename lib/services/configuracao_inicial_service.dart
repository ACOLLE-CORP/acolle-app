import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracaoInicialService {
  static Future<bool> pendente(String uid) async =>
      (await SharedPreferences.getInstance()).getBool(
        'configuracao_pendente_$uid',
      ) ??
      false;

  static Future<void> iniciar(String uid) async {
    await (await SharedPreferences.getInstance()).setBool(
      'configuracao_pendente_$uid',
      true,
    );
  }

  static Future<void> concluir(String uid) async {
    await (await SharedPreferences.getInstance()).remove(
      'configuracao_pendente_$uid',
    );
  }
}
