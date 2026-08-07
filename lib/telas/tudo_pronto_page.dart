import 'package:flutter/material.dart';

import '../services/notificacao_service.dart';
import '../shared/acolle_design.dart';
import 'home_page.dart';

/// Tela final do onboarding: "Tudo pronto!".
class TudoProntoPage extends StatefulWidget {
  const TudoProntoPage({super.key});

  @override
  State<TudoProntoPage> createState() => _TudoProntoPageState();
}

class _TudoProntoPageState extends State<TudoProntoPage> {
  bool _inicializando = true;

  @override
  void initState() {
    super.initState();
    _configurarNotificacoes();
  }

  Future<void> _configurarNotificacoes() async {
    try {
      await NotificacaoService.registrarTokenUsuario();
      await NotificacaoService.inscreverTopicoSeguranca();
    } catch (_) {
      // Não bloqueia o usuário; notificações não são críticas para a tela atual.
    } finally {
      if (mounted) setState(() => _inicializando = false);
    }
  }

  void _irParaApp() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcolleDesign.fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: AcolleDesign.card,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: AcolleDesign.verde, size: 92),
              ),
              const SizedBox(height: 28),
              const Text(
                'Tudo pronto!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AcolleDesign.roxo,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'O Acolle está preparado para te proteger. '
                'Agora você tem um parceiro contra golpes digitais.',
                textAlign: TextAlign.center,
                style: AcolleDesign.estiloCorpo,
              ),
              const Spacer(),
              if (_inicializando)
                AcolleDesign.carregandoCentral('Preparando suas notificações...')
              else
                AcolleDesign.botaoPrimario(
                  texto: 'Ir para o app',
                  icone: Icons.arrow_forward,
                  onPressed: _irParaApp,
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
