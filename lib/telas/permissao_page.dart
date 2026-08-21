import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../shared/acolle_design.dart';
import '../services/acessibilidade_service.dart';

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
  final AcessibilidadeService _acessibilidade =
      AcessibilidadeService.instance;

  bool _concedida = false;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _verificarEstado();
  }

  Future<void> _verificarEstado() async {
    final status = await widget.permissao.status;

    if (!mounted) return;

    setState(() {
      _concedida = status.isGranted;
    });
  }

  Future<void> _solicitar() async {
    setState(() => _carregando = true);

    try {
      final status = await widget.permissao.request();

      if (!mounted) return;

      setState(() {
        _concedida = status.isGranted;
      });

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
    } catch (_) {
      if (mounted) {
        AcolleDesign.snackbar(
          context,
          'Não foi possível conceder a permissão.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _abrirConfiguracoes() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final altoContraste = _acessibilidade.altoContraste;

        return AlertDialog(
          backgroundColor: AcolleDesign.corFundo(altoContraste),
          icon: Icon(
            widget.icone,
            color: AcolleDesign.corIcone(altoContraste),
            size: 40,
          ),
          title: Text(
            'Abrir configurações',
            style: AcolleDesign.texto(
              tamanho: AcolleDesign.tamanhoTexto(22),
              peso: FontWeight.bold,
            ).copyWith(
              color: AcolleDesign.corTexto(altoContraste),
            ),
          ),
          content: Text(
            'Recusamos a permissão antes. Para ativar agora, abra as '
            'Configurações do aplicativo Acolle.',
            style: AcolleDesign.texto(
              tamanho: AcolleDesign.tamanhoTexto(17),
            ).copyWith(
              color: AcolleDesign.corTexto(altoContraste),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Agora não',
                style: AcolleDesign.texto(
                  tamanho: AcolleDesign.tamanhoTexto(16),
                  peso: FontWeight.bold,
                ).copyWith(
                  color: AcolleDesign.corTexto(altoContraste),
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    AcolleDesign.corIcone(altoContraste),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text(
                'Abrir',
                style: TextStyle(
                  fontSize: AcolleDesign.tamanhoTexto(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
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
    return AnimatedBuilder(
      animation: _acessibilidade,
      builder: (context, child) {
        final altoContraste = _acessibilidade.altoContraste;

        return Scaffold(
          backgroundColor: AcolleDesign.corFundo(altoContraste),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 16,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: TextButton.icon(
                      onPressed: _pular,
                      icon: Icon(
                        Icons.close,
                        color: AcolleDesign.corIcone(altoContraste),
                      ),
                      label: Text(
                        'Pular',
                        style: AcolleDesign.texto(
                          tamanho: AcolleDesign.tamanhoTexto(16),
                          peso: FontWeight.bold,
                        ).copyWith(
                          color: AcolleDesign.corTexto(altoContraste),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AcolleDesign.corCard(altoContraste),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AcolleDesign.corBorda(altoContraste),
                        width: altoContraste ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      widget.icone,
                      color: AcolleDesign.corIcone(altoContraste),
                      size: 76,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    widget.titulo,
                    textAlign: TextAlign.center,
                    style: AcolleDesign.texto(
                      tamanho: AcolleDesign.tamanhoTexto(28),
                      peso: FontWeight.bold,
                    ).copyWith(
                      color: AcolleDesign.corTexto(altoContraste),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    widget.explicacao,
                    textAlign: TextAlign.center,
                    style: AcolleDesign.texto(
                      tamanho: AcolleDesign.tamanhoTexto(18),
                    ).copyWith(
                      color: AcolleDesign.corTextoSecundario(
                        altoContraste,
                      ),
                    ),
                  ),

                  const Spacer(),

                  if (_concedida)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: altoContraste
                            ? AcolleDesign.corCard(altoContraste)
                            : AcolleDesign.verde.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AcolleDesign.verde,
                          width: altoContraste ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AcolleDesign.verde,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Permissão concedida!',
                              textAlign: TextAlign.center,
                              style: AcolleDesign.texto(
                                tamanho: AcolleDesign.tamanhoTexto(16),
                                peso: FontWeight.bold,
                              ).copyWith(
                                color: AcolleDesign.corTexto(
                                  altoContraste,
                                ),
                              ),
                            ),
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
                    cor: altoContraste
                        ? AcolleDesign.corTexto(altoContraste)
                        : Colors.grey.shade700,
                    onPressed: _pular,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}