import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'services/notificacao_service.dart';
import 'services/acessibilidade_service.dart';
import 'services/caller_id_service.dart';
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

  _SessaoLembretes().iniciar();
  runApp(const AcolleApp());
}

class _SessaoLembretes with WidgetsBindingObserver {
  void iniciar() {
    WidgetsBinding.instance.addObserver(this);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _renovarLembretes();
      } else {
        CallerIdService.encerrarSessao();
        unawaited(_encerrarNotificacoes());
      }
    });
    Timer.periodic(const Duration(hours: 6), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _renovarLembretes();
      }
    });
  }

  Future<void> _encerrarNotificacoes() async {
    try {
      await Future.wait([
        NotificacaoService.cancelarTodosLembretes(),
        NotificacaoService.pararRegistroToken(),
      ]);
    } catch (erro) {
      debugPrint('Falha ao encerrar notificações: ${erro.runtimeType}');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _renovarLembretes();
  }

  Future<void> _renovarLembretes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await NotificacaoService.sincronizarLembretes(uid);
    } catch (erro) {
      debugPrint('Falha ao renovar lembretes: ${erro.runtimeType}');
    }
  }
}

class AcolleApp extends StatefulWidget {
  const AcolleApp({super.key});

  @override
  State<AcolleApp> createState() => _AcolleAppState();
}

class _AcolleAppState extends State<AcolleApp> {
  StreamSubscription<String>? _subscricaoRotasBotao;
  StreamSubscription? _alarmesTocando;
  final _alarmesExibidos = <int>{};

  @override
  void initState() {
    super.initState();
    // Sempre que um alarme começar a tocar, abre a tela dedicada
    // por cima de qualquer tela em que o usuário estiver.
    _alarmesTocando = Alarm.ringing.listen((alarmSet) {
      _mostrarAlarmes(alarmSet.alarms);
    });

    // Novo: se o app foi aberto por um toque no menu do botão
    // flutuante, navega direto para a tela correspondente.
    // O postFrameCallback garante que o navigatorKey já está pronto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarAberturaPeloBotaoFlutuante();
    });
    navegacaoInicialPronta.future.then((_) {
      _mostrarAlarmes(Alarm.ringing.value.alarms);
    });

    _subscricaoRotasBotao = FloatingButtonService.rotas.listen(_abrirRotaBotao);
  }

  void _mostrarAlarmes(Iterable<AlarmSettings> alarmes) {
    final navigator = navigatorKey.currentState;
    if (!mounted || navigator == null || !navegacaoInicialPronta.isCompleted) {
      return;
    }
    _alarmesExibidos.retainAll(alarmes.map((alarme) => alarme.id));
    for (final alarme in alarmes) {
      if (!_alarmesExibidos.add(alarme.id)) continue;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => TelaAlarmeTocando(alarm: alarme),
          fullscreenDialog: true,
        ),
      );
    }
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

      case 'verificar_link_tela':
        final textoTela = await FloatingButtonService.textoTelaPendente();

        if (!mounted) return;

        tela = VerificarLinkPage(
          textoDaTela: textoTela ?? '',
        );

        break;

      case 'verificar_link':
        tela = const VerificarLinkPage(
          usarAreaDeTransferencia: true,
        );

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
    _alarmesTocando?.cancel();
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
                textScaler: acessibilidade.escalaTexto == 1.0
                    ? mediaQuery.textScaler
                    : _EscalaDoAplicativo(mediaQuery.textScaler, acessibilidade.escalaTexto),
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

class _EscalaDoAplicativo extends TextScaler {
  const _EscalaDoAplicativo(this.sistema, this.fator);
  final TextScaler sistema;
  final double fator;

  @override
  double scale(double fontSize) => sistema.scale(fontSize) * fator;

  @override
  double get textScaleFactor => scale(14) / 14;
}
