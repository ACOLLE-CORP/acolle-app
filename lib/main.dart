import 'dart:async';

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
import 'telas/pedir_ajuda_page.dart';
import 'shared/acolle_design.dart';

/// Chave global de navegação — usada para abrir a tela de alarme por cima
/// de qualquer tela em que o usuário estiver, mesmo com o app em segundo
/// plano.
final navigatorKey = GlobalKey<NavigatorState>();
final navegacaoInicialPronta = Completer<void>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(notificacaoBackgroundMessageHandler);

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
  StreamSubscription<String>? _subscricaoRotasBotao;

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

    _subscricaoRotasBotao = FloatingButtonService.rotas.listen(_abrirRotaBotao);
  }

  Future<void> _verificarAberturaPeloBotaoFlutuante() async {
    final rota = await FloatingButtonService.rotaInicial();
    if (rota == null) return;

    _abrirRotaBotao(rota);
  }

  Future<void> _abrirRotaBotao(String rota) async {
    await navegacaoInicialPronta.future;

    if (!mounted) return;

    Widget? tela;

    switch (rota) {
      case 'analisar':
        tela = const AnalisarMensagemPage();

        break;

      case 'analisar_tela':
        final texto = await FloatingButtonService.textoTelaPendente();

        if (!mounted) return;

        if (texto == null || texto.trim().isEmpty) {
          tela = const AnalisarMensagemPage();
        } else {
          tela = AnalisarMensagemPage(
            textoInicial: texto,
            analisarAutomaticamente: true,
            origemCapturaTela: true,
          );
        }

        break;

      case 'verificar_link':
        tela = const VerificarLinkPage();

        break;

      case 'alertas':
        tela = const HistoricoPage();

        break;

      case 'ajuda':
        tela = const PedirAjudaPage();

        break;

      default:
        tela = null;
    }

    if (tela != null) {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => tela!));
    }
  }

  @override
  void dispose() {
    _subscricaoRotasBotao?.cancel();
    super.dispose();
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

          theme: AcolleDesign.tema(),

          locale: const Locale('pt', 'BR'),

          supportedLocales: const [Locale('pt', 'BR')],

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
                textScaler: TextScaler.linear(acessibilidade.escalaTexto),
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
