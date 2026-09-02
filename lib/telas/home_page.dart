import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/acessibilidade_service.dart';
import '../services/caller_id_service.dart';
import '../shared/acolle_design.dart';
import 'aprender_page.dart';
import 'botao_flutuante.dart';
import 'login_page.dart';
import 'mais_opcoes_page.dart';
import 'minha_rotina_page.dart';
import 'pedir_ajuda_page.dart';
import 'perfil_page.dart';
import 'proteger_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AcessibilidadeService get acessibilidade =>
      AcessibilidadeService.instance;

  @override
  void initState() {
    super.initState();

    acessibilidade.addListener(
      _onAcessibilidadeChanged,
    );

    acessibilidade.carregar();

    _iniciarCallerId();
  }

  void _onAcessibilidadeChanged() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _iniciarCallerId() async {
    final status = await Permission.phone.request();

    if (status.isGranted) {
      CallerIdService.iniciarMonitoramento(
        _mostrarAlertaNumero,
      );
    }
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
            'O número $numero está na lista de números '
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

  Future<void> _confirmarSaida() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final altoContraste =
            acessibilidade.altoContraste;

        return AlertDialog(
          backgroundColor:
              AcolleDesign.corCard(
            altoContraste,
          ),
          title: Text(
            'Sair da conta',
            style: AcolleDesign.tituloDialogo,
          ),
          content: Text(
            'Deseja realmente sair da sua conta?',
            style: AcolleDesign.textoDialogo,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    AcolleDesign.vermelho,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (sair != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  void _abrirAcessibilidade() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final altoContraste =
                acessibilidade.altoContraste;

            return Material(
              color: AcolleDesign.corFundo(
                altoContraste,
              ),
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    32,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Acessibilidade',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color:
                                AcolleDesign.corTexto(
                              altoContraste,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Ajuste a leitura para ficar mais confortável.',
                          style: TextStyle(
                            fontSize: 17,
                            color: AcolleDesign
                                .corTextoSecundario(
                              altoContraste,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Icon(
                              Icons.text_decrease,
                              size: 30,
                              color:
                                  AcolleDesign.corIcone(
                                altoContraste,
                              ),
                            ),

                            Expanded(
                              child: Slider(
                                value: acessibilidade
                                    .escalaTexto,
                                min: 0.9,
                                max: 1.4,
                                divisions: 5,
                                activeColor:
                                    AcolleDesign
                                        .corIcone(
                                  altoContraste,
                                ),
                                label:
                                    '${(acessibilidade.escalaTexto * 100).round()}%',
                                onChanged: (valor) {
                                  acessibilidade
                                      .alterarEscalaTexto(
                                    valor,
                                  );

                                  setModalState(
                                    () {},
                                  );
                                },
                              ),
                            ),

                            Icon(
                              Icons.text_increase,
                              size: 30,
                              color:
                                  AcolleDesign.corIcone(
                                altoContraste,
                              ),
                            ),
                          ],
                        ),

                        SwitchListTile.adaptive(
                          contentPadding:
                              EdgeInsets.zero,
                          title: Text(
                            'Alto contraste',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                              color: AcolleDesign
                                  .corTexto(
                                altoContraste,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            'Aumenta a diferença entre as cores.',
                            style: TextStyle(
                              fontSize: 16,
                              color: AcolleDesign
                                  .corTextoSecundario(
                                altoContraste,
                              ),
                            ),
                          ),
                          value: altoContraste,
                          activeColor:
                              AcolleDesign.laranja,
                          onChanged: (valor) {
                            acessibilidade
                                .alterarAltoContraste(
                              valor,
                            );

                            setModalState(
                              () {},
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        Divider(
                          color: AcolleDesign
                              .corTextoSecundario(
                            altoContraste,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const BotaoFlutuanteCard(),

                        const SizedBox(height: 12),

                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                AcolleDesign.corIcone(
                              altoContraste,
                            ),
                            foregroundColor:
                                altoContraste
                                    ? Colors.black
                                    : Colors.white,
                            minimumSize:
                                const Size.fromHeight(
                              54,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                            );
                          },
                          child: const Text(
                            'Concluir',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
    final usuario =
        FirebaseAuth.instance.currentUser;

    final nome =
        usuario?.displayName?.trim();

    final saudacao =
        nome?.isNotEmpty == true
            ? 'Olá, ${nome!.split(' ').first}!'
            : 'Olá!';

    final altoContraste =
        acessibilidade.altoContraste;

    return Scaffold(
      backgroundColor:
          AcolleDesign.corFundo(
        altoContraste,
      ),

      appBar: AppBar(
        backgroundColor:
            AcolleDesign.corFundo(
          altoContraste,
        ),
        elevation: 0,

        title: Text(
          'Acolle',
          style: TextStyle(
            color:
                AcolleDesign.corIcone(
              altoContraste,
            ),
            fontWeight:
                FontWeight.bold,
            fontSize: 28,
          ),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            tooltip: 'Acessibilidade',
            icon: Icon(
              Icons.accessibility_new,
              color:
                  AcolleDesign.corIcone(
                altoContraste,
              ),
            ),
            onPressed:
                _abrirAcessibilidade,
          ),

          IconButton(
            tooltip: 'Meu perfil',
            icon: Icon(
              Icons.person_outline,
              color:
                  AcolleDesign.corIcone(
                altoContraste,
              ),
            ),
            onPressed: () {
              _abrirPagina(
                const PerfilPage(),
              );
            },
          ),

          IconButton(
            tooltip: 'Sair da conta',
            icon: Icon(
              Icons.logout,
              color:
                  AcolleDesign.corIcone(
                altoContraste,
              ),
            ),
            onPressed:
                _confirmarSaida,
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            28,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              _buildMascoteSaudacao(
                saudacao,
                altoContraste,
              ),

              const SizedBox(height: 26),

              Text(
                'Como podemos ajudar?',
                style: TextStyle(
                  fontSize:
                      AcolleDesign.tamanhoTexto(
                    23,
                  ),
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AcolleDesign.corTexto(
                    altoContraste,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              _buildCardsPrincipais(
                altoContraste,
              ),

              const SizedBox(height: 18),

              _buildMaisOpcoes(
                altoContraste,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMascoteSaudacao(
    String saudacao,
    bool altoContraste,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,

      children: [
        ExcludeSemantics(
          child: Image.asset(
            'assets/images/mascote.png',
            height: 82,
            width: 82,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Container(
            padding:
                const EdgeInsets.all(17),

            margin:
                const EdgeInsets.only(
              bottom: 6,
            ),

            decoration: BoxDecoration(
              color:
                  AcolleDesign.corIcone(
                altoContraste,
              ),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),

            child: Text(
              '$saudacao\n'
              'Estou aqui para proteger você.',

              style: TextStyle(
                color: altoContraste
                    ? Colors.black
                    : Colors.white,

                fontSize:
                    AcolleDesign.tamanhoTexto(
                  19,
                ),

                fontWeight:
                    FontWeight.bold,

                height: 1.25,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsPrincipais(
    bool altoContraste,
  ) {
    return GridView.count(
      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      crossAxisCount: 2,

      mainAxisSpacing: 14,

      crossAxisSpacing: 14,

      // Antes era 1.12.
      // Um valor menor deixa os cards mais altos.
      childAspectRatio: 0.95,

      children: [
        _buildCardPrincipal(
          icone:
              Icons.shield_outlined,

          titulo: 'Proteger',

          descricao:
              'Verifique mensagens, links e chamadas.',

          altoContraste:
              altoContraste,

          onTap: () {
            _abrirPagina(
              const ProtegerPage(),
            );
          },
        ),

        _buildCardPrincipal(
          icone:
              Icons.calendar_today_outlined,

          titulo: 'Minha Rotina',

          descricao:
              'Organize seus lembretes e horários.',

          altoContraste:
              altoContraste,

          onTap: () {
            _abrirPagina(
              const MinhaRotinaPage(),
            );
          },
        ),

        _buildCardPrincipal(
          icone:
              Icons.people_outline,

          titulo: 'Pedir Ajuda',

          descricao:
              'Fale rapidamente com alguém de confiança.',

          altoContraste:
              altoContraste,

          onTap: () {
            _abrirPagina(
              const PedirAjudaPage(),
            );
          },
        ),

        _buildCardPrincipal(
          icone:
              Icons.menu_book_outlined,

          titulo: 'Aprender',

          descricao:
              'Veja dicas para evitar golpes.',

          altoContraste:
              altoContraste,

          onTap: () {
            _abrirPagina(
              const AprenderPage(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCardPrincipal({
    required IconData icone,
    required String titulo,
    required String descricao,
    required bool altoContraste,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,

      label:
          '$titulo. $descricao',

      child: Material(
        color:
            AcolleDesign.corCard(
          altoContraste,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        child: InkWell(
          onTap: onTap,

          borderRadius:
              BorderRadius.circular(
            20,
          ),

          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                Icon(
                  icone,

                  size: 40,

                  color:
                      AcolleDesign.corIcone(
                    altoContraste,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  titulo,

                  textAlign:
                      TextAlign.center,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize:
                        AcolleDesign
                            .tamanhoTexto(
                      18,
                    ),

                    fontWeight:
                        FontWeight.bold,

                    color:
                        AcolleDesign.corTexto(
                      altoContraste,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Flexible(
                  child: Text(
                    descricao,

                    textAlign:
                        TextAlign.center,

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize:
                          AcolleDesign
                              .tamanhoTexto(
                        13,
                      ),

                      height: 1.15,

                      color: AcolleDesign
                          .corTextoSecundario(
                        altoContraste,
                      ),
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

  Widget _buildMaisOpcoes(
    bool altoContraste,
  ) {
    return Semantics(
      button: true,

      label:
          'Mais opções. Acesse outros recursos do Acolle.',

      child: Material(
        color:
            AcolleDesign.corCard(
          altoContraste,
        ),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        child: InkWell(
          onTap: () {
            _abrirPagina(
              const MaisOpcoesPage(),
            );
          },

          borderRadius:
              BorderRadius.circular(
            18,
          ),

          child: Container(
            height: 62,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),

            child: Row(
              children: [
                Icon(
                  Icons.more_horiz,

                  size: 32,

                  color:
                      AcolleDesign.corIcone(
                    altoContraste,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    'Mais opções',

                    style: TextStyle(
                      fontSize:
                          AcolleDesign
                              .tamanhoTexto(
                        18,
                      ),

                      fontWeight:
                          FontWeight.bold,

                      color:
                          AcolleDesign.corTexto(
                        altoContraste,
                      ),
                    ),
                  ),
                ),

                Icon(
                  Icons.chevron_right,

                  size: 30,

                  color:
                      AcolleDesign.corIcone(
                    altoContraste,
                  ),
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
    acessibilidade.removeListener(
      _onAcessibilidadeChanged,
    );

    CallerIdService
        .pararMonitoramento();

    super.dispose();
  }
}