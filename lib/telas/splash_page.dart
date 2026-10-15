import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import '../main.dart' show navegacaoInicialPronta;

const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);
const Color laranjaAcolle = Color(0xFFF47A07);

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _progressTimer;
  double progresso = 0;
  int porcentagem = 0;
  String mensagem = 'Inicializando...';

  @override
  void initState() {
    super.initState();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (porcentagem >= 100) {
        timer.cancel();

        if (!mounted) return;
        final user = FirebaseAuth.instance.currentUser;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                user != null ? const HomePage() : const LoginPage(),
          ),
        );
        if (!navegacaoInicialPronta.isCompleted) {
          navegacaoInicialPronta.complete();
        }
      } else {
        setState(() {
          porcentagem++;
          progresso = porcentagem / 100;

          if (porcentagem < 25) {
            mensagem = 'Inicializando...';
          } else if (porcentagem < 50) {
            mensagem = 'Verificando segurança...';
          } else if (porcentagem < 75) {
            mensagem = 'Analisando ambiente...';
          } else {
            mensagem = 'Preparando proteção...';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tamanhoTela = MediaQuery.of(context).size;
    final alturaTela = tamanhoTela.height;

    // O mascote agora usa a imagem recortada (sem margens vazias), então
    // a altura abaixo é a altura real da tartaruga na tela.
    final alturaMascote = (alturaTela * 0.30).clamp(160.0, 280.0);

    // Largura da logo: limitada pela largura e pela altura da tela, para
    // não estourar em celulares pequenos. Proporção da imagem: 411 x 248.
    final larguraLogo = [
      tamanhoTela.width * 0.62,
      alturaTela * 0.30,
      280.0,
    ].reduce((a, b) => a < b ? a : b);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height:
            double.infinity, // FIX: garante que o gradiente cubra 100% da tela
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F5FF), Color(0xFFEDE4FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            // FIX: LayoutBuilder + ConstrainedBox fazem a Column ocupar
            // no mínimo a altura da tela, permitindo o mainAxisAlignment
            // .center funcionar de verdade — e ainda rola se precisar.
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Hero(
                            tag: "mascote",
                            child: Image.asset(
                              'assets/images/mascote_home.png',
                              height: alturaMascote,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Semantics(
                            label: 'Acolle',
                            image: true,
                            child: ExcludeSemantics(
                              child: Image.asset(
                                'assets/images/logo_acolle.png',
                                width: larguraLogo,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Sempre um passo à frente,\nsem pressa.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 50),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: LinearProgressIndicator(
                              value: progresso,
                              minHeight: 14,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                roxoAcolle,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Text(
                            '$porcentagem%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: roxoAcolle,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            mensagem,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 40),

                          Container(
                            width: 110,
                            height: 6,
                            decoration: BoxDecoration(
                              color: laranjaAcolle,
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}