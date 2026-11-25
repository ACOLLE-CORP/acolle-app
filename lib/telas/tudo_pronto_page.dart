import '../services/notification_listener_service.dart';
import 'package:flutter/services.dart';
import '../services/configuracao_inicial_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool? _avisosDeMensagem = false;
  bool? _avisosDeChamada = false;

  String _estado(bool? ativo) => switch (ativo) {
    true => 'ativados',
    false => 'desativados',
    null => 'a confirmar',
  };

  @override
  void initState() {
    super.initState();
    _configurarNotificacoes();
  }

  Future<void> _configurarNotificacoes() async {
    try {
      final podeNotificar = await Permission.notification.isGranted;
      final avisosDeMensagem = await NotificationListenerService.verificacaoAtiva();
      const chamadas = MethodChannel('acolle/caller_id');
      final identifica =
          await chamadas.invokeMethod<bool>('isScreeningRoleEnabled') ?? false;
      final canalAtivo =
          await chamadas.invokeMethod<bool>('areCallNotificationsEnabled') ??
          false;
      if (!mounted) return;
      setState(() {
        _avisosDeMensagem = avisosDeMensagem;
        _avisosDeChamada = identifica && canalAtivo;
      });
      if (podeNotificar) {
        final token = await NotificacaoService.registrarTokenUsuario();
        if (token != null) await NotificacaoService.inscreverTopicoSeguranca();
      }
    } catch (_) {
      // Sem acesso ao serviço, a tela mantém os avisos como não confirmados.
    }
  }

  Future<void> _irParaApp() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await ConfiguracaoInicialService.concluir(uid);
    if (!mounted) return;
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
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: AcolleDesign.card,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AcolleDesign.verde,
                  size: 92,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Configuração concluída',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AcolleDesign.roxo,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Você já pode verificar mensagens e links.\n\n'
                'Avisos de mensagens: ${_estado(_avisosDeMensagem)}.\n'
                'Avisos de chamadas: ${_estado(_avisosDeChamada)}.\n\n'
                'Para revisar as permissões, abra Aprender e toque em Ver tutorial.',
                textAlign: TextAlign.center,
                style: AcolleDesign.texto(tamanho: 17, peso: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              AcolleDesign.botaoPrimario(
                texto: 'Ir para o app',
                icone: Icons.arrow_forward_rounded,
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
