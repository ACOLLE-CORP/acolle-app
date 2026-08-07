import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../shared/acolle_design.dart';

/// Tela genérica de permissão do onboarding do Acolle.
///
/// Mostra ícone grande + explicação simples + botão Permitir / Agora não.
/// Reutilizada para chamadas, microfone, notificações e contatos.
class PermissaoPage extends StatefulWidget {
  const PermissaoPage({
    super.key,
    required this.icone,
    required this.titulo,
    required this.explicacao,
    required this.permissao,
    required this.proxima,
    required this.rotuloPermitir,
    this.botaoAtivar = false,
  });

  /// Ícone principal mostrado no topo.
  final IconData icone;
  final String titulo;
  final String explicacao;
  final Permission permissao;
  final WidgetBuilder proxima;
  final String rotuloPermitir;
  final bool botaoAtivar;

  @override
  State<PermissaoPage> createState() => _PermissaoPageState();
}

class _PermissaoPageState extends State<PermissaoPage> {
  bool _concedida = false;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _verificarEstado();
  }

  Future<void> _verificarEstado() async {
    final status = await widget.permissao.status;
    if (mounted) setState(() => _concedida = status.isGranted);
  }

  Future<void> _solicitar() async {
    setState(() => _carregando = true);
    try {
      final status = await widget.permissao.request();
      if (mounted) setState(() => _concedida = status.isGranted);
      if (!mounted) return;
      if (status.isGranted || status.isLimited) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: widget.proxima),
        );
      } else if (status.isPermanentlyDenied) {
        await _abrirConfiguracoes();
      } else {
        AcolleDesign.snackbar(
          context,
          'Sem essa permissão, alguns recursos podem não funcionar.',
        );
      }
    } catch (e) {
      if (mounted) {
        AcolleDesign.snackbar(context, 'Não foi possível conceder a permissão.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirConfiguracoes() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(widget.icone, color: AcolleDesign.roxo, size: 40),
        title: Text('Abrir configurações'),
        content: const Text(
          'Recusamos a permissão antes. Para ativar agora, abra as '
          'Configurações do aplicativo Acolle.',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
  }

  void _pular() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: widget.proxima),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcolleDesign.fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: TextButton.icon(
                  onPressed: _pular,
                  icon: const Icon(Icons.close),
                  label: const Text('Pular'),
                ),
              ),
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AcolleDesign.card,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icone,
                    color: AcolleDesign.roxo, size: 76),
              ),
              const SizedBox(height: 28),
              Text(
                widget.titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AcolleDesign.texto,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.explicacao,
                textAlign: TextAlign.center,
                style: AcolleDesign.estiloCorpo,
              ),
              const Spacer(),
              if (_concedida)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AcolleDesign.verde.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle, color: AcolleDesign.verde),
                      SizedBox(width: 8),
                      Text(
                        'Permissão concedida!',
                        style: TextStyle(
                            color: AcolleDesign.verde,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              AcolleDesign.botaoPrimario(
                texto: widget.rotuloPermitir,
                icone: Icons.lock_open_outlined,
                carregando: _carregando,
                onPressed: _solicitar,
              ),
              const SizedBox(height: 12),
              AcolleDesign.botaoSecundario(
                texto: 'Agora não',
                cor: Colors.grey.shade700,
                onPressed: _pular,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
