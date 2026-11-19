import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/acessibilidade_service.dart';
import '../shared/acolle_design.dart';

/// Tela exibida depois que o e-mail de recuperação foi enviado.
///
/// O Firebase envia um LINK (não um código). Esta tela explica o passo a
/// passo para o usuário: abrir o e-mail, tocar no link, criar a nova senha
/// na página que abrir e voltar ao Acolle para entrar.
class LinkRedefinicaoEnviadoPage extends StatefulWidget {
  const LinkRedefinicaoEnviadoPage({super.key, required this.email});

  final String email;

  @override
  State<LinkRedefinicaoEnviadoPage> createState() =>
      _LinkRedefinicaoEnviadoPageState();
}

class _LinkRedefinicaoEnviadoPageState
    extends State<LinkRedefinicaoEnviadoPage> {
  bool _carregando = false;

  Future<void> _reenviar() async {
    setState(() => _carregando = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      if (!mounted) return;
      AcolleDesign.snackbar(
        context,
        'Enviamos o e-mail de novo para ${widget.email}.',
        cor: AcolleDesign.verde,
      );
    } catch (_) {
      if (mounted) {
        AcolleDesign.snackbar(context, 'Não foi possível reenviar agora.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget _passo(int numero, String texto, bool altoContraste) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AcolleDesign.corIcone(altoContraste),
            ),
            child: Text(
              '$numero',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: altoContraste ? Colors.black : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                texto,
                style: AcolleDesign.texto(
                  tamanho: 19,
                  cor: AcolleDesign.corTexto(altoContraste),
                  altura: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final acessibilidade = AcessibilidadeService.instance;

    return AnimatedBuilder(
      animation: acessibilidade,
      builder: (context, _) {
        final altoContraste = acessibilidade.altoContraste;

        return Scaffold(
          backgroundColor: AcolleDesign.corFundo(altoContraste),
          appBar: AcolleDesign.appBarPadrao('Verifique seu e-mail'),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_read_rounded,
                    size: 84,
                    color: AcolleDesign.corIcone(altoContraste),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enviamos um link',
                    textAlign: TextAlign.center,
                    style: AcolleDesign.texto(
                      tamanho: 30,
                      peso: FontWeight.bold,
                      cor: AcolleDesign.corIcone(altoContraste),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mandamos um e-mail para\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: AcolleDesign.texto(
                      tamanho: 19,
                      cor: AcolleDesign.corTexto(altoContraste),
                      altura: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _passo(1, 'Abra o e-mail que acabamos de enviar.',
                      altoContraste),
                  _passo(2, 'Toque no link para redefinir a senha.',
                      altoContraste),
                  _passo(3, 'Na página que abrir, crie a sua nova senha.',
                      altoContraste),
                  _passo(4, 'Volte ao Acolle e entre com a nova senha.',
                      altoContraste),
                  const SizedBox(height: 6),
                  AcolleDesign.cartao(
                    padding: const EdgeInsets.all(14),
                    cor: altoContraste ? Colors.black : AcolleDesign.roxoSuave,
                    filho: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          size: 28,
                          color: AcolleDesign.corIcone(altoContraste),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Não achou o e-mail? Olhe também na caixa de '
                            'Spam ou Lixo eletrônico. O Acolle nunca pede '
                            'sua senha por e-mail.',
                            style: AcolleDesign.texto(
                              tamanho: 17,
                              peso: FontWeight.w600,
                              cor: AcolleDesign.corTexto(altoContraste),
                              altura: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  AcolleDesign.botaoPrimario(
                    texto: 'Reenviar e-mail',
                    icone: Icons.send_rounded,
                    carregando: _carregando,
                    onPressed: _reenviar,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    child: Text(
                      'Voltar para o login',
                      style: AcolleDesign.texto(
                        tamanho: 18,
                        peso: FontWeight.bold,
                        cor: altoContraste
                            ? AcolleDesign.laranja
                            : AcolleDesign.laranja,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
