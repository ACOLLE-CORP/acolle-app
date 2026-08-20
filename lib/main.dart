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
  }

  @override
  Widget build(BuildContext context) {
    // Reconstrói o MaterialApp sempre que o usuário mudar
    // o tamanho do texto ou o alto contraste.
    return ListenableBuilder(
      listenable: AcessibilidadeService.instance,
      builder: (context, _) {
        final acessibilidade = AcessibilidadeService.instance;

        // ============================================================
        // TEMA NORMAL DO ACOLLE
        // ============================================================
        final temaNormal = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,

          scaffoldBackgroundColor: const Color(0xFFFAF7FC),

          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF773FD1),
            brightness: Brightness.light,
          ),

          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFAF7FC),
            foregroundColor: Color(0xFF25212B),
            elevation: 0,
          ),

          cardTheme: const CardThemeData(
            color: Color(0xFFF2EDF5),
            elevation: 0,
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
              borderSide: BorderSide(
                color: Color(0xFFD4CBDD),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
              borderSide: BorderSide(
                color: Color(0xFFD4CBDD),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
              borderSide: BorderSide(
                color: Color(0xFF773FD1),
                width: 2,
              ),
            ),
          ),

          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              color: Color(0xFF25212B),
            ),
            bodyMedium: TextStyle(
              color: Color(0xFF25212B),
            ),
            titleLarge: TextStyle(
              color: Color(0xFF25212B),
            ),
          ),
        );

        // ============================================================
        // TEMA DE ALTO CONTRASTE
        // ============================================================
        final temaAltoContraste = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,

          scaffoldBackgroundColor: Colors.black,

          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Colors.black,

            secondary: Colors.white,
            onSecondary: Colors.black,

            surface: Colors.black,
            onSurface: Colors.white,

            error: Colors.red,
            onError: Colors.white,
          ),

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),

          cardTheme: const CardThemeData(
            color: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Colors.white,
                width: 1.5,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
            ),
          ),

          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.black,

            hintStyle: TextStyle(
              color: Colors.white,
            ),

            labelStyle: TextStyle(
              color: Colors.white,
            ),

            prefixIconColor: Colors.white,
            suffixIconColor: Colors.white,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
              borderSide: BorderSide(
                color: Colors.white,
                width: 2,
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
              borderSide: BorderSide(
                color: Colors.white,
                width: 2,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
              borderSide: BorderSide(
                color: Colors.white,
                width: 3,
              ),
            ),
          ),

          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              color: Colors.white,
            ),
            bodyMedium: TextStyle(
              color: Colors.white,
            ),
            bodySmall: TextStyle(
              color: Colors.white,
            ),
            titleLarge: TextStyle(
              color: Colors.white,
            ),
            titleMedium: TextStyle(
              color: Colors.white,
            ),
            titleSmall: TextStyle(
              color: Colors.white,
            ),
            headlineLarge: TextStyle(
              color: Colors.white,
            ),
            headlineMedium: TextStyle(
              color: Colors.white,
            ),
            headlineSmall: TextStyle(
              color: Colors.white,
            ),
          ),

          iconTheme: const IconThemeData(
            color: Colors.white,
          ),

          dividerTheme: const DividerThemeData(
            color: Colors.white,
            thickness: 1,
          ),

          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.all(
              Colors.white,
            ),
            trackColor: WidgetStateProperty.all(
              Colors.black,
            ),
            trackOutlineColor: WidgetStateProperty.all(
              Colors.white,
            ),
          ),
        );

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
          // APLICA O TEMA GLOBAL
          // ==========================================================
          theme: temaNormal,

          darkTheme: temaAltoContraste,

          // Quando o alto contraste estiver ligado,
          // usa o tema de alto contraste.
          themeMode: acessibilidade.altoContraste
              ? ThemeMode.dark
              : ThemeMode.light,

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