import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/caller_id_service.dart';
import '../services/acessibilidade_service.dart';
import '../services/emergencia_service.dart';
import '../shared/acolle_design.dart';

import 'analisar_mensagem_page.dart';
import 'botao_flutuante.dart';
import 'contatos_emergencia_page.dart';
import 'dicas_page.dart';
import 'historico_chamadas_page.dart';
import 'historico_page.dart';
import 'lembretes_remedios_page.dart';
import 'login_page.dart';
import 'perfil_page.dart';
import 'verificar_link_page.dart';

class _AtalhoHome {
  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  const _AtalhoHome({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _buscaController = TextEditingController();

  String _busca = '';
  bool _sosEmAndamento = false;

  AcessibilidadeService get acessibilidade =>
      AcessibilidadeService.instance;

  @override
  void initState() {
    super.initState();

    acessibilidade.addListener(_onAcessibilidadeChanged);
    acessibilidade.carregar();

    _iniciarCallerId();
  }

  void _onAcessibilidadeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  // ============================================================
  // CALLER ID
  // ============================================================

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
      builder: (context) {
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: AcolleDesign.vermelho,
            size: 40,
          ),
          title: Text(
            'Atenção!',
            style: AcolleDesign.tituloDialogo,
          ),
          content: Text(
            'O número $numero está na lista de números suspeitos '
            'de golpe. Tenha cuidado ao atender.',
            style: AcolleDesign.textoDialogo,
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AcolleDesign.laranja,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _confirmarSaida() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AcolleDesign.vermelho,
              ),
              onPressed: () {
                Navigator.pop(context, true);
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
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // ACESSIBILIDADE
  // ============================================================

  void _abrirAcessibilidade() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AcolleDesign.corFundo(
        acessibilidade.altoContraste,
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final altoContraste = acessibilidade.altoContraste;

            return SafeArea(
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
                          color: AcolleDesign.corTexto(
                            altoContraste,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Ajuste a leitura para ficar mais confortável.',
                        style: TextStyle(
                          fontSize: 17,
                          color: AcolleDesign.corTextoSecundario(
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
                            color: AcolleDesign.corIcone(
                              altoContraste,
                            ),
                          ),

                          Expanded(
                            child: Slider(
                              value: acessibilidade.escalaTexto,
                              min: 0.9,
                              max: 1.4,
                              divisions: 5,
                              activeColor: AcolleDesign.corIcone(
                                altoContraste,
                              ),

                              label:
                                  '${(acessibilidade.escalaTexto * 100).round()}%',

                              onChanged: (valor) {
                                acessibilidade
                                    .alterarEscalaTexto(valor);

                                setModalState(() {});
                              },
                            ),
                          ),

                          Icon(
                            Icons.text_increase,
                            size: 30,
                            color: AcolleDesign.corIcone(
                              altoContraste,
                            ),
                          ),
                        ],
                      ),

                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,

                        title: Text(
                          'Alto contraste',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AcolleDesign.corTexto(
                              altoContraste,
                            ),
                          ),
                        ),

                        subtitle: Text(
                          'Aumenta a diferença entre as cores.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AcolleDesign.corTextoSecundario(
                              altoContraste,
                            ),
                          ),
                        ),

                        value: altoContraste,

                        activeColor: AcolleDesign.laranja,

                        onChanged: (valor) {
                          acessibilidade
                              .alterarAltoContraste(valor);

                          setModalState(() {});
                        },
                      ),

                      const SizedBox(height: 20),

                      const Divider(),

                      const SizedBox(height: 8),

                      // Botão flutuante de proteção (não é bem
                      // "acessibilidade", mas fica aqui junto com as
                      // outras configurações rápidas do app).
                      const BotaoFlutuanteCard(),

                      const SizedBox(height: 12),

                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AcolleDesign.corIcone(altoContraste),
                          foregroundColor: AcolleDesign.fundo,
                          minimumSize: const Size(
                            double.infinity,
                            54,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Concluir',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SOS
  // ============================================================

  Future<void> _executarSOS() async {
    if (_sosEmAndamento) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() {
      _sosEmAndamento = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('contatos_emergencia')
          .where(
            'usuarioId',
            isEqualTo: user.uid,
          )
          .orderBy(
            'criadoEm',
            descending: true,
          )
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        setState(() {
          _sosEmAndamento = false;
        });

        _mostrarSemContatoEmergencia();
        return;
      }

      final dados = snapshot.docs.first.data();

      final nome =
          dados['nome'] as String? ??
          'contato de emergência';

      final telefone =
          dados['telefone'] as String? ??
          '';

      if (telefone.trim().isEmpty) {
        setState(() {
          _sosEmAndamento = false;
        });

        _mostrarErroSOS(
          'O contato principal não possui um telefone cadastrado.',
        );

        return;
      }

      FocusScope.of(context).unfocus();

      EmergenciaService.ligarPara(telefone);

      if (!mounted) return;

      setState(() {
        _sosEmAndamento = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ligando para $nome...',
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'CONTATOS',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ContatosEmergenciaPage(),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sosEmAndamento = false;
      });

      _mostrarErroSOS(
        'Não foi possível iniciar a ligação de emergência.',
      );
    }
  }

  void _mostrarSemContatoEmergencia() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.contact_emergency_outlined,
            color: AcolleDesign.laranja,
            size: 48,
          ),
          title: Text(
            'Contato de emergência',
            style: AcolleDesign.tituloDialogo,
          ),
          content: Text(
            'Para usar o SOS com um toque, cadastre pelo menos '
            'um contato de emergência.',
            style: AcolleDesign.textoDialogo,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Agora não'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AcolleDesign.laranja,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar'),
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ContatosEmergenciaPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarErroSOS(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    final nome = usuario?.displayName?.trim();

    final saudacao = nome?.isNotEmpty == true
        ? 'Olá, ${nome!.split(' ').first}!'
        : 'Olá!';

    final altoContraste = acessibilidade.altoContraste;

    return Scaffold(
      backgroundColor: AcolleDesign.corFundo(
        altoContraste,
      ),

      appBar: AppBar(
        backgroundColor: AcolleDesign.corFundo(
          altoContraste,
        ),
        elevation: 0,

        title: Text(
          'Acolle',
          style: TextStyle(
            color: AcolleDesign.corIcone( altoContraste),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            tooltip: 'Acessibilidade',
            icon: Icon(
              Icons.accessibility_new,
              color: AcolleDesign.corIcone(
                altoContraste,
              ),
            ),
            onPressed: _abrirAcessibilidade,
          ),

          IconButton(
            tooltip: 'Meu Perfil',
            icon: Icon(
              Icons.person_outline,
              color: AcolleDesign.corIcone(
                altoContraste,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PerfilPage(),
                ),
              );
            },
          ),

          IconButton(
            tooltip: 'Sair da conta',
            icon: Icon(
              Icons.logout,
              color: AcolleDesign.corIcone(
                altoContraste,
              ),
            ),
            onPressed: _confirmarSaida,
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            28,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              _buildBarraBusca(),

              const SizedBox(height: 20),

              _buildMascoteSaudacao(
                saudacao,
              ),

              const SizedBox(height: 24),

              _buildBotaoEmergencia(),

              const SizedBox(height: 24),

              _buildTituloSecao(
                'Como podemos ajudar?',
              ),

              const SizedBox(height: 12),

              _buildGradeAtalhos(),

              const SizedBox(height: 22),

              _buildStatusSeguranca(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUSCA
  // ============================================================

  Widget _buildBarraBusca() {
    final altoContraste = acessibilidade.altoContraste;

    return Semantics(
      label: 'Buscar recursos',
      textField: true,

      child: TextField(
        controller: _buscaController,

        onChanged: (valor) {
          setState(() {
            _busca = valor.trim().toLowerCase();
          });
        },

        style: TextStyle(
          fontSize: 19,
          color: AcolleDesign.corTexto(
            altoContraste,
          ),
        ),

        decoration: InputDecoration(
          filled: true,

          fillColor: AcolleDesign.corCampo(
            altoContraste,
          ),

          hintText: 'Buscar uma ajuda',

          hintStyle: TextStyle(
            color: AcolleDesign.corTextoSecundario(
              altoContraste,
            ),
            fontSize: 18,
          ),

          prefixIcon: Icon(
            Icons.search,
            size: 28,
            color: AcolleDesign.corIcone(
              altoContraste,
            ),
          ),

          suffixIcon: _busca.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',

                  icon: Icon(
                    Icons.close,
                    color: AcolleDesign.corIcone(
                      altoContraste,
                    ),
                  ),

                  onPressed: () {
                    _buscaController.clear();

                    setState(() {
                      _busca = '';
                    });
                  },
                ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AcolleDesign.corBorda(
                altoContraste,
              ),
              width: 1.5,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AcolleDesign.corBorda(
                altoContraste,
              ),
              width: 1.5,
            ),
          ),

          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MASCOTE
  // ============================================================

  Widget _buildMascoteSaudacao(
    String saudacao,
  ) {
    final altoContraste = acessibilidade.altoContraste;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,

      children: [
        ExcludeSemantics(
          child: Image.asset(
            'assets/images/mascote.png',
            height: 88,
            width: 88,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),

            margin:
                const EdgeInsets.only(bottom: 8),

            decoration: BoxDecoration(
              color: AcolleDesign.corIcone( altoContraste),
              borderRadius:
                  BorderRadius.circular(20),
            ),

            child: Text(
              '$saudacao\nEstou aqui para proteger você.',

              style: TextStyle(
                color: altoContraste
                    ? Colors.black
                    : Colors.white,

                fontSize: 20,

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

  // ============================================================
  // SOS
  // ============================================================

  Widget _buildBotaoEmergencia() {
    return Semantics(
      button: true,

      label:
          'SOS Emergência. Toque uma vez para ligar '
          'para o contato principal.',

      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          minHeight: 72,
        ),

        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                AcolleDesign.vermelho,

            foregroundColor:
                Colors.white,

            padding:
                const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),
          ),

          onPressed:
              _sosEmAndamento
                  ? null
                  : _executarSOS,

          child: FittedBox(
            fit: BoxFit.scaleDown,

            child: Row(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                if (_sosEmAndamento)
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        Colors.white,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.emergency,
                    size: 34,
                  ),

                const SizedBox(width: 10),

                Text(
                  _sosEmAndamento
                      ? 'Acionando SOS...'
                      : 'SOS Emergência',

                  style:
                      const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TÍTULO
  // ============================================================

  Widget _buildTituloSecao(
    String texto,
  ) {
    final altoContraste = acessibilidade.altoContraste;

    return Text(
      texto,

      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AcolleDesign.corTexto(
          altoContraste,
        ),
      ),
    );
  }

  // ============================================================
  // ATALHOS
  // ============================================================

  Widget _buildGradeAtalhos() {
    final atalhos = [
      _AtalhoHome(
        icone: Icons.message_outlined,
        titulo: 'Verificar mensagem',
        descricao: 'Analise mensagens suspeitas',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const AnalisarMensagemPage(),
            ),
          );
        },
      ),

      _AtalhoHome(
        icone: Icons.link,
        titulo: 'Verificar link',
        descricao: 'Confira links antes de abrir',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const VerificarLinkPage(),
            ),
          );
        },
      ),

      _AtalhoHome(
        icone: Icons.shield_outlined,
        titulo: 'Dicas de proteção',
        descricao: 'Aprenda a se proteger',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const DicasPage(),
            ),
          );
        },
      ),

      _AtalhoHome(
        icone: Icons.medication_outlined,
        titulo: 'Lembretes de remédios',
        descricao: 'Gerencie seus horários',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const LembretesRemediosPage(),
            ),
          );
        },
      ),

      _AtalhoHome(
        icone: Icons.contact_emergency,
        titulo: 'Contatos de emergência',
        descricao: 'Lista de pessoas de confiança',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const ContatosEmergenciaPage(),
            ),
          );
        },
      ),

      _AtalhoHome(
        icone: Icons.call_received,
        titulo: 'Histórico de chamadas',
        descricao: 'Veja quem ligou e se era suspeito',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const HistoricoChamadasPage(),
            ),
          );
        },
      ),

      _AtalhoHome(
        icone: Icons.history,
        titulo: 'Histórico',
        descricao: 'Suas verificações anteriores',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const HistoricoPage(),
            ),
          );
        },
      ),
    ];

    final filtrados = atalhos.where(
      (atalho) {
        return _busca.isEmpty ||
            '${atalho.titulo} ${atalho.descricao}'
                .toLowerCase()
                .contains(_busca);
      },
    ).toList();

    if (filtrados.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),

        child: Center(
          child: Text(
            'Nenhum recurso encontrado.',
            style: TextStyle(
              fontSize: 18,
              color: AcolleDesign.corTexto(
                acessibilidade.altoContraste,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      itemCount: filtrados.length,

      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.92,
      ),

      itemBuilder: (context, index) {
        return _buildCartaoAtalho(
          filtrados[index],
        );
      },
    );
  }

  Widget _buildCartaoAtalho(
    _AtalhoHome atalho,
  ) {
    final altoContraste =
        acessibilidade.altoContraste;

    return Semantics(
      button: true,

      label:
          '${atalho.titulo}. ${atalho.descricao}',

      child: Material(
        color: AcolleDesign.corCard(
          altoContraste,
        ),

        borderRadius:
            BorderRadius.circular(20),

        child: InkWell(
          borderRadius:
              BorderRadius.circular(20),

          onTap: atalho.onTap,

          child: Padding(
            padding:
                const EdgeInsets.all(16),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                Icon(
                  atalho.icone,

                  color:
                      AcolleDesign.corIcone(
                    altoContraste,
                  ),

                  size: 42,
                ),

                const SizedBox(height: 12),

                Flexible(
                  child: Text(
                    atalho.titulo,

                    textAlign:
                        TextAlign.center,

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 18,

                      fontWeight:
                          FontWeight.bold,

                      color:
                          AcolleDesign.corTexto(
                        altoContraste,
                      ),

                      height: 1.15,
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

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusSeguranca() {
    final altoContraste =
        acessibilidade.altoContraste;

    return Semantics(
      label:
          'Status de segurança: tudo certo. '
          'Nenhuma ameaça encontrada hoje.',

      child: Container(
        padding:
            const EdgeInsets.all(20),

        decoration:
            BoxDecoration(
          color:
              AcolleDesign.corCard(
            altoContraste,
          ),

          borderRadius:
              BorderRadius.circular(20),

          border:
              Border.all(
            color:
                AcolleDesign.corBorda(
              altoContraste,
            ),

            width: 1.2,
          ),
        ),

        child: Row(
          children: [
            Icon(
              Icons.verified_user,

              color:
                  AcolleDesign.corIcone(
                altoContraste,
              ),

              size: 42,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                'Tudo certo!\n'
                'Nenhuma ameaça foi encontrada hoje.',

                style: TextStyle(
                  fontSize: 18,

                  fontWeight:
                      FontWeight.bold,

                  color:
                      AcolleDesign.corTexto(
                    altoContraste,
                  ),

                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    acessibilidade.removeListener(
      _onAcessibilidadeChanged,
    );

    CallerIdService.pararMonitoramento();

    _buscaController.dispose();

    super.dispose();
  }
}