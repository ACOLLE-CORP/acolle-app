import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/acolle_design.dart';

class ConfigurarProtecaoChamadasPage extends StatefulWidget {
  const ConfigurarProtecaoChamadasPage({super.key, required this.proxima});

  final WidgetBuilder proxima;

  @override
  State<ConfigurarProtecaoChamadasPage> createState() =>
      _ConfigurarProtecaoChamadasPageState();
}

class _ConfigurarProtecaoChamadasPageState
    extends State<ConfigurarProtecaoChamadasPage>
    with WidgetsBindingObserver {
  static const _canal = MethodChannel('acolle/caller_id');
  bool _identificacaoAtiva = false;
  bool _sobreposicaoAtiva = false;
  bool _verificando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _atualizarEstado();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _atualizarEstado();
  }

  Future<void> _atualizarEstado() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      if (mounted) setState(() => _verificando = false);
      return;
    }
    try {
      final resultados = await Future.wait([
        _canal.invokeMethod<bool>('isScreeningRoleEnabled'),
        _canal.invokeMethod<bool>('isOverlayPermissionEnabled'),
      ]);
      if (!mounted) return;
      setState(() {
        _identificacaoAtiva = resultados[0] ?? false;
        _sobreposicaoAtiva = resultados[1] ?? false;
        _verificando = false;
      });
    } on PlatformException {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _ativarIdentificacao() async {
    await _canal.invokeMethod<bool>('requestScreeningRole');
    await _atualizarEstado();
  }

  Future<void> _ativarSobreposicao() async {
    await _canal.invokeMethod<bool>('requestOverlayPermission');
  }

  void _continuar() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: widget.proxima),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tudoPronto = _identificacaoAtiva && _sobreposicaoAtiva;
    return Scaffold(
      backgroundColor: AcolleDesign.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.phone_in_talk,
                size: 76,
                color: AcolleDesign.roxo,
              ),
              const SizedBox(height: 18),
              const Text(
                'Proteção durante as ligações',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: AcolleDesign.texto,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ative os dois passos abaixo. Você só precisa fazer isso uma vez neste celular.',
                textAlign: TextAlign.center,
                style: AcolleDesign.estiloCorpo,
              ),
              const SizedBox(height: 28),
              if (_verificando)
                const Center(child: CircularProgressIndicator())
              else ...[
                _PassoPermissao(
                  numero: '1',
                  titulo: 'Identificar chamadas',
                  explicacao: 'Na próxima tela, escolha Acolle e confirme.',
                  ativo: _identificacaoAtiva,
                  textoBotao: 'Ativar identificação',
                  onPressed: _ativarIdentificacao,
                ),
                const SizedBox(height: 16),
                _PassoPermissao(
                  numero: '2',
                  titulo: 'Mostrar o aviso grande',
                  explicacao:
                      'Ative a chave “Permitir exibição sobre outros apps”.',
                  ativo: _sobreposicaoAtiva,
                  textoBotao: 'Permitir aviso na tela',
                  onPressed: _identificacaoAtiva ? _ativarSobreposicao : null,
                ),
              ],
              const SizedBox(height: 28),
              if (tudoPronto)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AcolleDesign.verde.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: AcolleDesign.verde),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Proteção de chamadas ativada!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AcolleDesign.verde,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              AcolleDesign.botaoPrimario(
                texto: tudoPronto ? 'Continuar' : 'Concluir os passos acima',
                icone: tudoPronto ? Icons.arrow_forward : Icons.lock_outline,
                onPressed: tudoPronto ? _continuar : null,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _continuar,
                child: const Text('Fazer isso mais tarde'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassoPermissao extends StatelessWidget {
  const _PassoPermissao({
    required this.numero,
    required this.titulo,
    required this.explicacao,
    required this.ativo,
    required this.textoBotao,
    required this.onPressed,
  });

  final String numero;
  final String titulo;
  final String explicacao;
  final bool ativo;
  final String textoBotao;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AcolleDesign.cartao(
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: ativo ? AcolleDesign.verde : AcolleDesign.roxo,
                foregroundColor: Colors.white,
                child: ativo
                    ? const Icon(Icons.check)
                    : Text(
                        numero,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(explicacao, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 14),
          if (ativo)
            const Text(
              'Ativado ✓',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AcolleDesign.verde,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            )
          else
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.touch_app),
              label: Text(textoBotao),
            ),
        ],
      ),
    );
  }
}
