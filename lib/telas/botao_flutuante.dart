import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/floating_button_service.dart';
import '../services/acessibilidade_service.dart';
import '../shared/acolle_design.dart';

const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);

/// Card/seção para ativar ou desativar o botão flutuante de proteção.
class BotaoFlutuanteCard extends StatefulWidget {
  const BotaoFlutuanteCard({super.key});

  @override
  State<BotaoFlutuanteCard> createState() =>
      _BotaoFlutuanteCardState();
}

class _BotaoFlutuanteCardState
    extends State<BotaoFlutuanteCard> {
  static const _canalPermissoes =
      MethodChannel('acolle/caller_id');

  final AcessibilidadeService acessibilidade =
      AcessibilidadeService.instance;

  bool _permissaoConcedida = false;
  bool _botaoAtivo = false;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();

    acessibilidade.addListener(
      _atualizarAcessibilidade,
    );

    _verificarPermissao();
  }

  void _atualizarAcessibilidade() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _verificarPermissao() async {
    try {
      final concedida =
          await _canalPermissoes.invokeMethod<bool>(
        'isOverlayPermissionEnabled',
      );

      if (!mounted) return;

      setState(() {
        _permissaoConcedida =
            concedida ?? false;

        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _permissaoConcedida = false;
        _carregando = false;
      });

      debugPrint(
        'Erro ao verificar permissão de sobreposição: $e',
      );
    }
  }

  Future<void> _pedirPermissao() async {
    try {
      await _canalPermissoes.invokeMethod(
        'requestOverlayPermission',
      );

      // Aguarda um pouco para que o Android termine
      // a transição para as configurações.
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      await _verificarPermissao();
    } catch (e) {
      debugPrint(
        'Erro ao solicitar permissão de sobreposição: $e',
      );
    }
  }

  Future<void> _alternarBotao(
    bool ativar,
  ) async {
    if (ativar && !_permissaoConcedida) {
      await _pedirPermissao();

      if (!_permissaoConcedida) {
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _carregando = true;
    });

    try {
      if (ativar) {
        await FloatingButtonService.iniciar();
      } else {
        await FloatingButtonService.parar();
      }

      if (!mounted) return;

      setState(() {
        _botaoAtivo = ativar;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível ${ativar ? 'ativar' : 'desativar'} '
            'o botão de proteção.',
          ),
        ),
      );

      debugPrint(
        'Erro ao alternar botão flutuante: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool altoContraste =
        acessibilidade.altoContraste;

    final Color corFundo =
        AcolleDesign.corCard(
      altoContraste,
    );

    final Color corTexto =
        AcolleDesign.corTexto(
      altoContraste,
    );

    final Color corTextoSecundario =
        AcolleDesign.corTextoSecundario(
      altoContraste,
    );

    final Color corIcone =
        AcolleDesign.corIcone(
      altoContraste,
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 12,
      ),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: corFundo,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: corIcone.withOpacity(0.35),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,

            children: [
              Container(
                padding:
                    const EdgeInsets.all(10),

                decoration: BoxDecoration(
                  color:
                      corIcone.withOpacity(0.12),

                  shape: BoxShape.circle,
                ),

                child: Icon(
                  Icons.control_camera,
                  color: corIcone,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Botão flutuante de proteção',

                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    color: corTexto,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              if (_carregando)
                SizedBox(
                  width: 22,
                  height: 22,

                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: corIcone,
                  ),
                )
              else
                Switch(
                  value: _botaoAtivo,

                  activeColor:
                      corIcone,

                  onChanged:
                      _alternarBotao,
                ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _permissaoConcedida
                ? 'Deixa uma bolinha na tela para analisar '
                    'mensagens, verificar links e pedir ajuda '
                    'a qualquer momento, mesmo com o Acolle fechado.'
                : 'Para ativar, o Acolle precisa da permissão '
                    'para aparecer sobre outros aplicativos. '
                    'Toque na chave ao lado para conceder.',

            style: TextStyle(
              fontSize: 14,

              color:
                  corTextoSecundario,

              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    acessibilidade.removeListener(
      _atualizarAcessibilidade,
    );

    super.dispose();
  }
}

// ============================================================
// TELA DE CONFIGURAÇÃO DO BOTÃO FLUTUANTE
// ============================================================

class ConfigurarBotaoFlutuantePage
    extends StatefulWidget {
  const ConfigurarBotaoFlutuantePage({
    super.key,
  });

  @override
  State<ConfigurarBotaoFlutuantePage>
      createState() =>
          _ConfigurarBotaoFlutuantePageState();
}

class _ConfigurarBotaoFlutuantePageState
    extends State<ConfigurarBotaoFlutuantePage> {
  final AcessibilidadeService acessibilidade =
      AcessibilidadeService.instance;

  @override
  void initState() {
    super.initState();

    acessibilidade.addListener(
      _atualizarAcessibilidade,
    );

    acessibilidade.carregar();
  }

  void _atualizarAcessibilidade() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool altoContraste =
        acessibilidade.altoContraste;

    final Color corFundo =
        AcolleDesign.corFundo(
      altoContraste,
    );

    final Color corIcone =
        AcolleDesign.corIcone(
      altoContraste,
    );

    return Scaffold(
      backgroundColor: corFundo,

      appBar: AppBar(
        backgroundColor: corFundo,

        elevation: 0,

        title: Text(
          'Botão de proteção',

          style: TextStyle(
            color: corIcone,

            fontWeight:
                FontWeight.bold,

            fontSize: 20,
          ),
        ),

        iconTheme: IconThemeData(
          color: corIcone,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: const [
            BotaoFlutuanteCard(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    acessibilidade.removeListener(
      _atualizarAcessibilidade,
    );

    super.dispose();
  }
}