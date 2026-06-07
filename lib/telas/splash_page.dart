import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';

const Color roxoAcolle = Color(0xFF773FD1);
const Color azulAcolle = Color(0xFF6C63FF);
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
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoAcolle,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 115,
                height: 115,
                decoration: BoxDecoration(
                  color: roxoAcolle,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: roxoAcolle.withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Acolle',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: roxoAcolle,
                  letterSpacing: 1.8,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Sempre um passo à frente,\nsem pressa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 55),

              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 14,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation<Color>(roxoAcolle),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                '$porcentagem%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: roxoAcolle,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Carregando ambiente seguro...',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 36),

              Container(
                width: 90,
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
  }
}