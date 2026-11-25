import '../services/configuracao_inicial_service.dart';
import 'termos_page.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import '../main.dart' show navegacaoInicialPronta;
import '../shared/acolle_design.dart';

const Color fundoAcolle = Color(0xFFFAF7FC);

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _progressTimer;
  double progresso = 0;
  int porcentagem = 0;

  @override
  void initState() {
    super.initState();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) async {
      if (porcentagem >= 100) {
        timer.cancel();

        if (!mounted) return;
        final user = FirebaseAuth.instance.currentUser;
        final pendente = user != null && await ConfiguracaoInicialService.pendente(user.uid);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                user == null ? const LoginPage() : pendente ? TermosPage.primeiraPermissao(context) : const HomePage(),
          ),
        );
        if (!navegacaoInicialPronta.isCompleted) {
          navegacaoInicialPronta.complete();
        }
      } else {
        setState(() {
          porcentagem++;
          progresso = porcentagem / 100;
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
    // não estourar em celulares pequenos. A nova logo é bem mais larga
    // (proporção aproximada de 4,5 : 1).
    final larguraLogo = [
      tamanhoTela.width * 0.72,
      alturaTela * 0.60,
      320.0,
    ].reduce((a, b) => a < b ? a : b);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity, // garante que a cor cubra 100% da tela
        color: fundoAcolle,
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
                                'assets/images/logo_acolle_nova.png',
                                width: larguraLogo,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Sempre um passo à frente\nsem pressa.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 21,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 40),

                          SizedBox(
                            height: 36,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned.fill(
                                    child: LinearProgressIndicator(
                                      value: progresso,
                                      backgroundColor: AcolleDesign.roxoEscuro,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AcolleDesign.roxo,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Carregando $porcentagem%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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