import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'services/notificacao_service.dart';
import 'services/acessibilidade_service.dart';
import 'telas/splash_page.dart';
import 'telas/tela_alarme_tocando.dart';

/// Chave global de navegação — usada para abrir a tela de alarme por cima
/// de qualquer tela em que o usuário estiver, mesmo com o app em segundo
/// plano.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  @override
  void initState() {
    super.initState();
    // Sempre que um alarme começar a tocar, abre a tela dedicada por cima
    // de qualquer coisa que estiver na tela.
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
  }

  @override
  Widget build(BuildContext context) {
    // Reconstrói o MaterialApp sempre que o usuário mudar o tamanho do
    // texto ou o alto contraste em qualquer tela do app.
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

        

          // Aplica a escala de texto escolhida pelo usuário a TODO o app,
          // sem precisar alterar cada TextStyle das telas individualmente.
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