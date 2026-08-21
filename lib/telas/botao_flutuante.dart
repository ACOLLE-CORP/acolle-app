import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/floating_button_service.dart';

const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);

/// Card/seção para ativar ou desativar o botão flutuante de proteção.
/// Pode ser usado dentro de uma tela de configurações existente, ou
/// como tela própria (veja o exemplo de Scaffold no fim do arquivo).
class BotaoFlutuanteCard extends StatefulWidget {
  const BotaoFlutuanteCard({super.key});

  @override
  State<BotaoFlutuanteCard> createState() => _BotaoFlutuanteCardState();
}

class _BotaoFlutuanteCardState extends State<BotaoFlutuanteCard> {
  // Mesmo canal que já existe no MainActivity.kt para as permissões
  // de overlay (usado pelo CallerAlertOverlay/call screening).
  static const _canalPermissoes = MethodChannel('acolle/caller_id');

  bool _permissaoConcedida = false;
  bool _botaoAtivo = false;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _verificarPermissao();
  }

  Future<void> _verificarPermissao() async {
    final concedida = await _canalPermissoes.invokeMethod<bool>(
      'isOverlayPermissionEnabled',
    );

    if (!mounted) return;
    setState(() {
      _permissaoConcedida = concedida ?? false;
      _carregando = false;
    });
  }

  Future<void> _pedirPermissao() async {
    await _canalPermissoes.invokeMethod('requestOverlayPermission');
    // O usuário concede na tela do sistema e volta manualmente —
    // reconfirma o estado ao voltar para o app.
    await _verificarPermissao();
  }

  Future<void> _alternarBotao(bool ativar) async {
    if (ativar && !_permissaoConcedida) {
      await _pedirPermissao();
      if (!_permissaoConcedida) return; // usuário não concedeu, não liga
    }

    setState(() => _carregando = true);

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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roxoAcolle.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: roxoAcolle.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.control_camera, color: roxoAcolle),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Botão flutuante de proteção',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              if (_carregando)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: _botaoAtivo,
                  activeColor: roxoAcolle,
                  onChanged: _alternarBotao,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _permissaoConcedida
                ? 'Deixa uma bolinha na tela para analisar mensagens, '
                    'verificar links e pedir ajuda a qualquer momento, '
                    'mesmo com o Acolle fechado.'
                : 'Para ativar, o Acolle precisa da permissão para '
                    'aparecer sobre outros aplicativos. Toque na chave '
                    'ao lado para conceder.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Exemplo de uso como tela própria — remova se for usar o card
// dentro de uma tela de configurações já existente.
// ============================================================
class ConfigurarBotaoFlutuantePage extends StatelessWidget {
  const ConfigurarBotaoFlutuantePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoAcolle,
      appBar: AppBar(
        backgroundColor: fundoAcolle,
        elevation: 0,
        title: const Text(
          'Botão de proteção',
          style: TextStyle(color: roxoAcolle, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: roxoAcolle),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: BotaoFlutuanteCard(),
      ),
    );
  }
}