import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../shared/acolle_design.dart';

/// Etapa do fluxo "Esqueci minha senha": o usuário informa o código de
/// verificação recebido por e-mail (action code do Firebase) e, em seguida,
/// define uma nova senha.
///
/// Funciona em conjunto com `FirebaseAuth.verifyPasswordResetCode` e
/// `FirebaseAuth.confirmPasswordReset`, que validam o código recebido por
/// e-mail quando o usuário clicar no link de recuperação.
class CodigoRedefinicaoPage extends StatefulWidget {
  const CodigoRedefinicaoPage({super.key, required this.email});

  final String email;

  @override
  State<CodigoRedefinicaoPage> createState() => _CodigoRedefinicaoPageState();
}

class _CodigoRedefinicaoPageState extends State<CodigoRedefinicaoPage> {
  final _codigoController = TextEditingController();
  bool _carregando = false;
  bool _verificado = false;
  String? _erro;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _verificarCodigo() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      setState(() => _erro = 'Digite o código recebido por e-mail.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await FirebaseAuth.instance.verifyPasswordResetCode(codigo);
      if (!mounted) return;
      setState(() => _verificado = true);
      AcolleDesign.snackbar(context, 'Código confirmado!', cor: AcolleDesign.verde);
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Código inválido ou expirado.';
      if (e.code == 'expired-action-code') {
        mensagem = 'O código expirou. Peça um novo.';
      } else if (e.code == 'invalid-action-code') {
        mensagem = 'Código inválido. Verifique e tente novamente.';
      } else if (e.code == 'user-disabled') {
        mensagem = 'Essa conta foi desativada.';
      }
      setState(() => _erro = mensagem);
    } catch (_) {
      setState(() => _erro = 'Não foi possível verificar agora.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _reenviar() async {
    setState(() => _carregando = true);
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: widget.email);
      if (!mounted) return;
      AcolleDesign.snackbar(
          context, 'Enviamos um novo código para ${widget.email}.');
    } catch (_) {
      if (mounted) {
        AcolleDesign.snackbar(context, 'Não foi possível reenviar agora.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcolleDesign.fundo,
      appBar: AcolleDesign.appBarPadrao('Código de verificação'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.password_rounded,
                  size: 80, color: AcolleDesign.roxo),
              const SizedBox(height: 18),
              const Text(
                'Confirme o código',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AcolleDesign.roxo,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enviamos um código para o seu e-mail. Cole o código abaixo '
                'para criar uma nova senha. O código está no link do e-mail '
                'que você recebeu — abra o e-mail, toque em "redefinir senha" '
                'e copie o código da página que abrir.',
                textAlign: TextAlign.center,
                selectionColor: AcolleDesign.fundo,
              ),
              const SizedBox(height: 28),
              AcolleDesign.campoTexto(
                label: 'Código de verificação',
                controller: _codigoController,
                icone: Icons.vpn_key_outlined,
                teclado: TextInputType.visiblePassword,
                acaoTeclado: TextInputAction.done,
              ),
              const SizedBox(height: 28),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(_erro!,
                      style: const TextStyle(color: Colors.red, fontSize: 16)),
                ),
              AcolleDesign.botaoPrimario(
                texto:  _verificado ? 'Confirmar e continuar' : 'Verificar código',
                icone: _verificado ? Icons.check_circle : Icons.verified_outlined,
                carregando: _carregando,
                onPressed: _verificado
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RedefinirSenhaPage(
                              codigo: _codigoController.text.trim(),
                            ),
                          ),
                        )
                    : _verificarCodigo,
              ),
              const SizedBox(height: 12),
              AcolleDesign.botaoSecundario(
                texto: 'Reenviar código',
                cor: Colors.grey.shade700,
                onPressed: _reenviar,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Voltar para login',
                  style: TextStyle(
                      color: AcolleDesign.laranja,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tela final do fluxo: nova senha + confirmação, usando o código verificado.
class RedefinirSenhaPage extends StatefulWidget {
  const RedefinirSenhaPage({super.key, required this.codigo});

  final String codigo;

  @override
  State<RedefinirSenhaPage> createState() => _RedefinirSenhaPageState();
}

class _RedefinirSenhaPageState extends State<RedefinirSenhaPage> {
  final _novaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _carregando = false;
  bool _mostrar = false;

  @override
  void dispose() {
    _novaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nova = _novaController.text.trim();

    if (nova.length < 6) {
      AcolleDesign.snackbar(context, 'A senha precisa ter no mínimo 6 caracteres.');
      return;
    }
    if (nova != _confirmarController.text.trim()) {
      AcolleDesign.snackbar(context, 'As senhas não são iguais.');
      return;
    }

    setState(() => _carregando = true);
    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.codigo,
        newPassword: nova,
      );
      if (!mounted) return;
      AcolleDesign.snackbar(
          context, 'Senha alterada! Faça login com a nova senha.', cor: AcolleDesign.verde);
      Navigator.popUntil(context, (route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Não foi possível alterar a senha.';
      if (e.code == 'expired-action-code') {
        mensagem = 'O código expirou. Recomece a recuperação.';
      } else if (e.code == 'invalid-action-code') {
        mensagem = 'Código inválido. Verifique e tente novamente.';
      } else if (e.code == 'weak-password') {
        mensagem = 'Escolha uma senha mais forte.';
      }
      AcolleDesign.snackbar(context, mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcolleDesign.fundo,
      appBar: AcolleDesign.appBarPadrao('Nova senha'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset,
                  size: 80, color: AcolleDesign.roxo),
              const SizedBox(height: 18),
              const Text(
                'Crie sua nova senha',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AcolleDesign.roxo,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Use uma senha fácil para você lembrar, mas difícil para '
                'outras pessoas adivinharem. Mínimo de 6 caracteres.',
                textAlign: TextAlign.center,
                selectionColor: AcolleDesign.fundo,
              ),
              const SizedBox(height: 28),
              AcolleDesign.campoTexto(
                label: 'Nova senha',
                controller: _novaController,
                icone: Icons.lock_outline,
                obscureText: !_mostrar,
                suffix: IconButton(
                  icon: Icon(_mostrar ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _mostrar = !_mostrar),
                ),
              ),
              const SizedBox(height: 16),
              AcolleDesign.campoTexto(
                label: 'Confirmar nova senha',
                controller: _confirmarController,
                icone: Icons.lock_outline,
                obscureText: !_mostrar,
                acaoTeclado: TextInputAction.done,
              ),
              const SizedBox(height: 28),
              AcolleDesign.botaoPrimario(
                texto: 'Salvar nova senha',
                icone: Icons.check_circle_outline,
                carregando: _carregando,
                onPressed: _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
