import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/acolle_design.dart';

class AgendaService {
  static const _canal = MethodChannel('acolle/contatos');
  static bool get disponivel =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> preencherContato(
    BuildContext context,
    TextEditingController nome,
    TextEditingController telefone,
  ) async {
    try {
      final contato = await _canal.invokeMapMethod<String, String>(
        'selecionarTelefone',
      );
      if (!context.mounted || contato == null) return;
      nome.text = contato['nome'] ?? '';
      telefone.text = contato['telefone'] ?? '';
    } on PlatformException catch (erro) {
      if (context.mounted) {
        AcolleDesign.snackbar(
          context,
          erro.code == 'SEM_NUMERO'
              ? 'Escolha um contato com telefone.'
              : 'Não foi possível abrir ou ler a agenda. Você também pode digitar o telefone.',
        );
      }
    } on MissingPluginException {
      if (context.mounted) {
        AcolleDesign.snackbar(
          context,
          'Digite o nome e o telefone do contato.',
        );
      }
    }
  }
}
