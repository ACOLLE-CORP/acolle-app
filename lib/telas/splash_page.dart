import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';

const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);
const Color laranjaAcolle = Color(0xFFF47A07);

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double progresso = 0;
  int porcentagem = 0;
  String mensagem = 'Inicializando...';

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (porcentagem >= 100) {
        timer.cancel();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F5FF),
              Color(0xFFEDE4FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: "mascote",
                  child: Image.asset(
                    'assets/images/mascote.png',
                    height: 250,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Acolle',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: roxoAcolle,
                    letterSpacing: 1.5,
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
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(roxoAcolle),
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
      ),
    );
  }
}