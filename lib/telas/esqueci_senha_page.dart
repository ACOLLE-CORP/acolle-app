import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../shared/acolle_design.dart';
import 'redefinir_fluxo_page.dart';

class EsqueciSenhaPage extends StatefulWidget {
  const EsqueciSenhaPage({super.key});

  @override
  State<EsqueciSenhaPage> createState() => _EsqueciSenhaPageState();
}

class _EsqueciSenhaPageState extends State<EsqueciSenhaPage> {
  final emailController = TextEditingController();
  bool carregando = false;

  Future<void> enviarEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      AcolleDesign.snackbar(context, 'Digite seu e-mail.');
      return;
    }

    setState(() => carregando = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      AcolleDesign.snackbar(
        context,
        'Enviamos um código de recuperação para seu e-mail.',
        cor: AcolleDesign.verde,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CodigoRedefinicaoPage(email: email),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Não foi possível enviar o e-mail.';
      if (e.code == 'invalid-email') {
        mensagem = 'Digite um e-mail válido.';
      } else if (e.code == 'user-not-found') {
        mensagem = 'Não encontramos uma conta com esse e-mail.';
      }
      AcolleDesign.snackbar(context, mensagem);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcolleDesign.fundo,
      appBar: AcolleDesign.appBarPadrao('Recuperar senha'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Icon(Icons.lock_reset, size: 80, color: AcolleDesign.roxo),
              const SizedBox(height: 18),
              const Text(
                'Esqueceu sua senha?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.bold,
                  color: AcolleDesign.roxo,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Digite seu e-mail cadastrado.\nVamos enviar um código para você criar uma nova senha.',
                textAlign: TextAlign.center,
                selectionColor: AcolleDesign.card,
              ),
              const SizedBox(height: 34),
              AcolleDesign.campoTexto(
                label: 'E-mail',
                controller: emailController,
                icone: Icons.email_outlined,
                teclado: TextInputType.emailAddress,
              ),
              const SizedBox(height: 28),
              AcolleDesign.botaoPrimario(
                texto: 'Enviar código',
                icone: Icons.send,
                carregando: carregando,
                onPressed: enviarEmail,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Voltar para login',
                  style: TextStyle(
                    color: AcolleDesign.laranja,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
