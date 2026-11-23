import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cadastro_page.dart';
import 'esqueci_senha_page.dart';
import 'home_page.dart';
import '../shared/acolle_design.dart';

const Color fundoAcolle = Color(0xFFFAF7FC);
const Color laranjaAcolle = Color(0xFFF47A07);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final _emailFocus = FocusNode();
  final _senhaFocus = FocusNode();

  bool carregando = false;
  bool mostrarSenha = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _senhaFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    _emailFocus.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    setState(() => carregando = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login realizado com sucesso!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Erro ao entrar. Verifique seus dados.';

      if (e.code == 'user-not-found') {
        mensagem = 'Usuário não encontrado.';
      } else if (e.code == 'wrong-password') {
        mensagem = 'Senha incorreta.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'E-mail inválido.';
      } else if (e.code == 'invalid-credential') {
        mensagem = 'E-mail ou senha incorretos.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX 1: altura do mascote calculada a partir da tela (com limites
    // min/max) em vez de valor fixo (250), reduzindo rolagem desnecessária
    // em telas pequenas.
    final alturaTela = MediaQuery.of(context).size.height;
    final alturaMascote = (alturaTela * 0.34).clamp(170.0, 320.0);

    return Scaffold(
      backgroundColor: fundoAcolle,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/mascote_login.png',
                  height: alturaMascote,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Bem-vindo ao Acolle',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AcolleDesign.roxo,
                  ),
                ),

                const SizedBox(height: 34),

                // O Semantics mantém o nome do campo para o leitor de tela
                // quando a dica visual some ao tocar no campo.
                Semantics(
                  label: 'E-mail',
                  textField: true,
                  child: TextField(
                    controller: emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: const TextStyle(fontSize: 19),
                    decoration: InputDecoration(
                      hintText: _emailFocus.hasFocus ? null : 'Seu e-mail',
                      hintStyle: const TextStyle(fontSize: 19),
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Semantics(
                  label: 'Senha',
                  textField: true,
                  child: TextField(
                    controller: senhaController,
                    focusNode: _senhaFocus,
                    obscureText: !mostrarSenha,
                    style: const TextStyle(fontSize: 19),
                    decoration: InputDecoration(
                      hintText: _senhaFocus.hasFocus ? null : 'Sua senha',
                      hintStyle: const TextStyle(fontSize: 19),
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          mostrarSenha
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () {
                          setState(() {
                            mostrarSenha = !mostrarSenha;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // FIX 2: SizedBox(height: 58) fixo trocado por
                // ConstrainedBox(minHeight: 58) para o botão crescer com
                // o texto em vez de estourar quando a fonte do sistema é
                // ampliada.
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 58, minWidth: double.infinity),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcolleDesign.roxo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: carregando ? null : entrar,
                    child: carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EsqueciSenhaPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Recuperar senha',
                    style: TextStyle(color: AcolleDesign.roxo, fontSize: 18),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CadastroPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Criar conta',
                    style: TextStyle(
                      color: laranjaAcolle,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}