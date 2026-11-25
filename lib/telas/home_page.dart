import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/acessibilidade_service.dart';
import '../services/caller_id_service.dart';
import '../services/tutorial_service.dart';
import '../shared/acolle_design.dart';
import '../shared/acolle_icons.dart';
import 'aprender_page.dart';
import 'mais_opcoes_page.dart';
import 'minha_rotina_page.dart';
import 'pedir_ajuda_page.dart';
import 'proteger_page.dart';
import 'tutorial_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  AcessibilidadeService get acessibilidade =>
      AcessibilidadeService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    acessibilidade.addListener(
      _onAcessibilidadeChanged,
    );

    acessibilidade.carregar();

    _iniciarCallerId();

    // O tutorial abre assim que a Home aparece, sem depender do pedido
    // de permissão de chamadas.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarTutorial();
    });
  }

  // Evita abrir o tutorial mais de uma vez por usuário na mesma sessão.
  static final Set<String> _tutorialTentadoPara = <String>{};

  /// Abre o tutorial de primeiro acesso uma única vez por usuário.
  Future<void> _verificarTutorial() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint('[Tutorial] sem usuário logado; não abre.');
        return;
      }

      if (_tutorialTentadoPara.contains(uid)) return;

      if (await TutorialService.jaConcluiu(uid)) {
        debugPrint('[Tutorial] já concluído para este usuário.');
        return;
      }

      if (!mounted) return;

      // Se outra tela (ex.: alarme) estiver por cima, tenta de novo na
      // próxima abertura, sem marcar como concluído.
      if (ModalRoute.of(context)?.isCurrent == false) {
        debugPrint('[Tutorial] outra tela está por cima; fica para depois.');
        return;
      }

      _tutorialTentadoPara.add(uid);
      debugPrint('[Tutorial] abrindo tutorial de primeiro acesso.');

      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => TutorialPage(
            aoFinalizar: () => TutorialService.marcarConcluido(uid),
          ),
        ),
      );
    } catch (e) {
      debugPrint('[Tutorial] erro ao abrir: $e');
    }
  }

  void _onAcessibilidadeChanged() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _iniciarCallerId() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await CallerIdService.sincronizarNumerosSuspeitos();
    if (!mounted) return;
    final status = await Permission.phone.status;

    if (mounted && status.isGranted) {
      await CallerIdService.iniciarMonitoramento(
        _mostrarAlertaNumero,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _iniciarCallerId();
  }

  void _mostrarAlertaNumero(String numero) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final altoContraste =
            acessibilidade.altoContraste;

        return AlertDialog(
          backgroundColor:
              AcolleDesign.corCard(
            altoContraste,
          ),
          icon: Icon(
            Icons.warning_amber_rounded,
            color: AcolleDesign.vermelho,
            size: 42,
          ),
          title: Text(
            'Atenção!',
            style: AcolleDesign.tituloDialogo,
          ),
          content: Text(
            'O número $numero foi identificado como um dos números '
            'suspeitos de golpe. Tenha cuidado ao atender.',
            style: AcolleDesign.textoDialogo,
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    AcolleDesign.laranja,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  void _abrirPagina(Widget pagina) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => pagina,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final altoContraste = acessibilidade.altoContraste;

    return Scaffold(
      backgroundColor: AcolleDesign.corFundo(altoContraste),
      appBar: AppBar(
        backgroundColor: AcolleDesign.corFundo(altoContraste),
        elevation: 0,
        toolbarHeight: 64,
        title: Semantics(
          label: 'Acolle',
          image: true,
          child: ExcludeSemantics(
            child: Image.asset(
              'assets/images/logo_acolle_nova.png',
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
        ),
        centerTitle: true,
      ),

      // Tela pensada para caber inteira, sem rolagem. Se o celular for
      // pequeno ou o texto estiver muito grande, ela passa a rolar em vez
      // de estourar (rede de segurança para acessibilidade).
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 32),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMascoteSaudacao(altoContraste),
                    const SizedBox(height: 16),
                    Expanded(child: _buildCardsPrincipais(altoContraste)),
                    const SizedBox(height: 16),
                    _buildMaisOpcoes(altoContraste),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMascoteSaudacao(bool altoContraste) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ExcludeSemantics(
          child: Image.asset(
            'assets/images/mascote_home.png',
            height: 92,
            width: 92,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: AcolleDesign.corIcone(altoContraste),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Dúvidas sobre o app?\n'
              'Posso te ajudar',
              style: TextStyle(
                color: altoContraste ? Colors.black : Colors.white,
                fontSize: AcolleDesign.tamanhoTexto(19),
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Botão "?" que reabre o tutorial. TutorialPage() sem aoFinalizar é
        // o mesmo que "Aprender > Ver tutorial" já faz.
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Semantics(
            button: true,
            label: 'Abrir o tutorial',
            child: Material(
              color: AcolleDesign.corIcone(altoContraste),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: Colors.white24,
                highlightColor: Colors.black12,
                onTap: () => _abrirPagina(const TutorialPage()),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    Icons.help_rounded,
                    size: 32,
                    color: altoContraste ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsPrincipais(bool altoContraste) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildCardPrincipal(
                  icone: AcolleIcons.proteger,
                  titulo: 'PROTEÇÃO',
                  descricaoParaLeitor:
                      'Verifique mensagens, links e chamadas.',
                  altoContraste: altoContraste,
                  cor: AcolleDesign.roxo,
                  onTap: () => _abrirPagina(const ProtegerPage()),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildCardPrincipal(
                  icone: AcolleIcons.rotina,
                  titulo: 'AGENDA',
                  descricaoParaLeitor:
                      'Organize seus lembretes e horários.',
                  altoContraste: altoContraste,
                  cor: AcolleDesign.azul,
                  onTap: () => _abrirPagina(const MinhaRotinaPage()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildCardPrincipal(
                  icone: AcolleIcons.pedirAjuda,
                  titulo: 'AJUDA',
                  descricaoParaLeitor:
                      'Fale rapidamente com alguém de confiança.',
                  altoContraste: altoContraste,
                  cor: AcolleDesign.verde,
                  onTap: () => _abrirPagina(const PedirAjudaPage()),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildCardPrincipal(
                  icone: AcolleIcons.aprender,
                  titulo: 'DICAS',
                  descricaoParaLeitor: 'Veja dicas para evitar golpes.',
                  altoContraste: altoContraste,
                  // Laranja mais escuro para o texto branco ter contraste.
                  cor: AcolleDesign.laranjaEscuro,
                  onTap: () => _abrirPagina(const AprenderPage()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Cartão sólido na cor do botão, com o ícone dentro de um quadrado
  /// branco. A descrição não aparece na tela, mas o leitor de tela lê.
  Widget _buildCardPrincipal({
    required IconData icone,
    required String titulo,
    required String descricaoParaLeitor,
    required bool altoContraste,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$titulo. $descricaoParaLeitor',
      child: Material(
        color: altoContraste ? Colors.black : cor,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white24,
          highlightColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icone,
                    size: 38,
                    color: altoContraste ? Colors.black : cor,
                  ),
                ),
                const SizedBox(height: 10),
                // O título é uma palavra só em maiúsculas: em vez de
                // quebrar linha, ele encolhe só se não couber.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontSize: AcolleDesign.tamanhoTexto(22),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaisOpcoes(bool altoContraste) {
    return Semantics(
      button: true,
      label: 'Mais opções. Acesse outros recursos do Acolle.',
      child: Material(
        color: altoContraste ? Colors.black : const Color(0xFF616161),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _abrirPagina(const MaisOpcoesPage()),
          splashColor: Colors.white24,
          highlightColor: Colors.black12,
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            child: Row(
              children: [
                const Icon(
                  AcolleIcons.mais,
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Mais opções',
                    style: TextStyle(
                      fontSize: AcolleDesign.tamanhoTexto(20),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(
                  AcolleIcons.avancar,
                  size: 30,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    acessibilidade.removeListener(
      _onAcessibilidadeChanged,
    );

    CallerIdService
        .pararMonitoramento();

    super.dispose();
  }
}
