import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'services/notificacao_service.dart';
import 'services/acessibilidade_service.dart';
import 'services/floating_button_service.dart';
import 'telas/splash_page.dart';
import 'telas/tela_alarme_tocando.dart';
import 'telas/analisar_mensagem_page.dart';
import 'telas/verificar_link_page.dart';
import 'telas/historico_page.dart';
import 'telas/home_page.dart';

/// Chave global de navegação — usada para abrir a tela de alarme por cima
/// de qualquer tela em que o usuário estiver, mesmo com o app em segundo
/// plano.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    notificacaoBackgroundMessageHandler,
  );

  await NotificacaoService.inicializar();

  await AcessibilidadeService.instance.carregar();

  runApp(const AcolleApp());
}

class AcolleApp extends StatefulWidget {
  const AcolleApp({super.key});

  @override
  State<AcolleApp> createState() => _AcolleAppState();
}

class _AcolleAppState extends State<AcolleApp> {
  @override
  void initState() {
    super.initState();

    // Sempre que um alarme começar a tocar, abre a tela dedicada
    // por cima de qualquer tela em que o usuário estiver.
    Alarm.ringing.listen((alarmSet) {
      for (final alarm in alarmSet.alarms) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => TelaAlarmeTocando(alarm: alarm),
            fullscreenDialog: true,
          ),
        );
      }
    });

    // Novo: se o app foi aberto por um toque no menu do botão
    // flutuante, navega direto para a tela correspondente.
    // O postFrameCallback garante que o navigatorKey já está pronto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarAberturaPeloBotaoFlutuante();
    });
  }

  Future<void> _verificarAberturaPeloBotaoFlutuante() async {
    final rota = await FloatingButtonService.rotaInicial();
    if (rota == null) return;

    final Widget? tela = switch (rota) {
      'analisar' => const AnalisarMensagemPage(),
      'verificar_link' => const VerificarLinkPage(),
      'alertas' => const HistoricoPage(),
      // Ainda não existe uma tela de chat dedicada — por enquanto,
      // "Falar com o Acolle" leva para a Home. Ajuste aqui quando
      // essa tela existir.
      'chat' => const HomePage(),
      _ => null,
    };

    if (tela != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => tela),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reconstrói o MaterialApp sempre que o usuário mudar
    // o tamanho do texto ou o alto contraste.
    return ListenableBuilder(
      listenable: AcessibilidadeService.instance,
      builder: (context, _) {
        final acessibilidade = AcessibilidadeService.instance;


        return MaterialApp(
          navigatorKey: navigatorKey,

          debugShowCheckedModeBanner: false,

          locale: const Locale('pt', 'BR'),

          supportedLocales: const [
            Locale('pt', 'BR'),
          ],

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ==========================================================
          // TAMANHO DA LETRA
          // ==========================================================
          // Continua exatamente sendo controlado pelo
          // AcessibilidadeService e vale para TODO o aplicativo.
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);

            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(
                  acessibilidade.escalaTexto,
                ),
              ),
              child: child!,
            );
          },

          home: const SplashPage(),
        );
      },
    );
  }
}