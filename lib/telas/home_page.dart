import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/caller_id_service.dart';
import '../services/acessibilidade_service.dart';
import '../services/emergencia_service.dart';
import 'analisar_mensagem_page.dart';
import 'contatos_emergencia_page.dart';
import 'dicas_page.dart';
import 'historico_chamadas_page.dart';
import 'historico_page.dart';
import 'lembretes_remedios_page.dart';
import 'login_page.dart';
import 'perfil_page.dart';
import 'verificar_link_page.dart';


const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);
const Color laranjaAcolle = Color(0xFFF47A07);
const Color cinzaCardAcolle = Color(0xFFF3EEFA);

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

  @override
  void initState() {
    super.initState();
    AcessibilidadeService.instance.addListener(_onAcessibilidadeChanged);
    AcessibilidadeService.instance.carregar();
    _iniciarCallerId();
  }

  void _onAcessibilidadeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _iniciarCallerId() async {
    final status = await Permission.phone.request();
    if (status.isGranted) {
      CallerIdService.iniciarMonitoramento(_mostrarAlertaNumero);
    }
  }

  void _mostrarAlertaNumero(String numero) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
          size: 40,
        ),
        title: const Text('Atenção!'),
        content: Text(
          'O número $numero está na lista de números suspeitos de golpe. Tenha cuidado ao atender.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarSaida() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (sair == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _abrirAcessibilidade() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final altoContraste = AcessibilidadeService.instance.altoContraste;

          return Theme(
            data: Theme.of(context).copyWith(
              brightness:
                  altoContraste ? Brightness.dark : Brightness.light,
              scaffoldBackgroundColor:
                  altoContraste ? Colors.black : Colors.white,
              colorScheme: altoContraste
                  ? const ColorScheme.dark(
                      primary: Colors.white,
                      onPrimary: Colors.black,
                      surface: Colors.black,
                      onSurface: Colors.white,
                    )
                  : ColorScheme.fromSeed(seedColor: roxoAcolle),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          // FIX 4: SingleChildScrollView evita overflow do modal em telas
          // pequenas quando _escalaTexto aumenta o tamanho do conteúdo.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Acessibilidade',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ajuste a leitura para ficar mais confortável.',
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.text_decrease, size: 30),
                    Expanded(
                      child: Slider(
                      value: AcessibilidadeService.instance.escalaTexto,
                      min: 0.9,
                      max: 1.4,
                      divisions: 5,
                      label:
                          '${(AcessibilidadeService.instance.escalaTexto * 100).round()}%',
                      onChanged: (valor) {
                        AcessibilidadeService.instance.alterarEscalaTexto(valor);
                        setModalState(() {});
                      },
                    ),
                    ),
                    const Icon(Icons.text_increase, size: 30),
                  ],
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Alto contraste',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Aumenta a diferença entre cores.',
                    style: TextStyle(fontSize: 16),
                  ),
                  value: AcessibilidadeService.instance.altoContraste,
                  onChanged: (valor) {
                    AcessibilidadeService.instance.alterarAltoContraste(valor);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Concluir'),
                ),
              ],
            ),
          ),
        ),
          );
        },
      ),
    );
  }

/// Aciona o SOS com uma única interação.
  ///
  /// O contato principal é o primeiro contato da lista de emergência
  /// é obtido do Firestore. Se não houver contatos, o usuário é avisado
  /// A lista completa continua disponível em "Contatos de emergência".
  Future<void> _executarSOS() async {
    if (_sosEmAndamento) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _sosEmAndamento = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('contatos_emergencia')
          .where('usuarioId', isEqualTo: user.uid)
          .orderBy('criadoEm', descending: true)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        setState(() => _sosEmAndamento = false);
        _mostrarSemContatoEmergencia();
        return;
      }

      final dados = snapshot.docs.first.data();
      final nome = dados['nome'] as String? ?? 'contato de emergência';
      final telefone = dados['telefone'] as String? ?? '';

      if (telefone.trim().isEmpty) {
        setState(() => _sosEmAndamento = false);
        _mostrarErroSOS('O contato principal não possui um telefone cadastrado.');
        return;
      }

      // Fecha qualquer teclado/elemento de entrada antes de iniciar a ação.
      FocusScope.of(context).unfocus();

      // Ação principal do SOS: ligação imediata, sem tela intermediária.
      EmergenciaService.ligarPara(telefone);

      if (!mounted) return;
      setState(() => _sosEmAndamento = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ligando para $nome...'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'CONTATOS',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContatosEmergenciaPage(),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sosEmAndamento = false);
      _mostrarErroSOS('Não foi possível iniciar a ligação de emergência.');
    }
  }

  void _mostrarSemContatoEmergencia() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.contact_emergency_outlined,
          color: roxoAcolle,
          size: 48,
        ),
        title: const Text('Contato de emergência'),
        content: const Text(
          'Para usar o SOS com um toque, cadastre pelo menos um contato de emergência.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Agora não'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar'),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContatosEmergenciaPage(),
                ),
              );
            },
          ),
        ],
      ),
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
  

  @override
  void dispose() {
    AcessibilidadeService.instance.removeListener(_onAcessibilidadeChanged);
    CallerIdService.pararMonitoramento();
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nome = FirebaseAuth.instance.currentUser?.displayName?.trim();
    final saudacao = nome?.isNotEmpty == true
        ? 'Olá, ${nome!.split(' ').first}!'
        : 'Olá!';
    final altoContraste = AcessibilidadeService.instance.altoContraste;

    final cores = altoContraste
        ? const _CoresHome(
            fundo: Colors.black,
            texto: Colors.white,
            card: Colors.black,
            borda: Colors.white,
            campo: Colors.black,
            icone: Colors.white,
            textoSecundario: Colors.white,
            destaque: Colors.white,
            destaqueTexto: Colors.black,
          )
        : const _CoresHome(
            fundo: fundoAcolle,
            texto: Color(0xFF25212B),
            card: cinzaCardAcolle,
            borda: Color(0xFFD4CBDD),
            campo: Colors.white,
            icone: roxoAcolle,
            textoSecundario: Colors.black87,
            destaque: roxoAcolle,
            destaqueTexto: Colors.white,
          );

    return Scaffold(
        backgroundColor: cores.fundo,
        appBar: AppBar(
          backgroundColor: cores.fundo,
          title: Text(
            'Acolle',
            style: TextStyle(
              color: cores.destaque,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Acessibilidade',
              icon: Icon(Icons.accessibility_new, color: cores.icone),
              onPressed: _abrirAcessibilidade,
            ),
            IconButton(
              tooltip: 'Meu Perfil',
              icon: Icon(Icons.person_outline, color: cores.icone),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PerfilPage()),
              ),
            ),
            IconButton(
              tooltip: 'Sair da conta',
              icon: Icon(Icons.logout, color: cores.icone),
              onPressed: _confirmarSaida,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBarraBusca(cores),
                const SizedBox(height: 20),
                _buildMascoteSaudacao(saudacao, cores),
                const SizedBox(height: 24),
                _buildBotaoEmergencia(),
                const SizedBox(height: 24),
                _buildTituloSecao('Como podemos ajudar?', cores),
                const SizedBox(height: 12),
                _buildGradeAtalhos(cores),
                const SizedBox(height: 22),
                _buildStatusSeguranca(cores),
              ],
            ),
          ),  
      ),
    ); 
  }

  Widget _buildBarraBusca(_CoresHome cores) {
    return Semantics(
      label: 'Buscar recursos',
      textField: true,
      child: TextField(
        controller: _buscaController,
        onChanged: (valor) =>
            setState(() => _busca = valor.trim().toLowerCase()),
        style: TextStyle(fontSize: 19, color: cores.texto),
        decoration: InputDecoration(
          filled: true,
          fillColor: cores.campo,
          hintText: 'Buscar uma ajuda',
          hintStyle: TextStyle(color: cores.textoSecundario, fontSize: 18),
          prefixIcon: Icon(Icons.search, size: 28, color: cores.icone),
          suffixIcon: _busca.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  icon: Icon(Icons.close, color: cores.icone),
                  onPressed: () {
                    _buscaController.clear();
                    setState(() => _busca = '');
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: cores.borda, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: cores.borda, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildMascoteSaudacao(String saudacao, _CoresHome cores) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
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
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: cores.destaque,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(5),
              ),
            ),
            child: Text(
              '$saudacao\nEstou aqui para proteger você.',
              style: TextStyle(
                color: cores.destaqueTexto,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoEmergencia() {
    return Semantics(
      button: true,
      label: 'SOS Emergência. Toque uma vez para ligar para o contato principal.',
      // FIX 1: SizedBox(height: 82) fixo trocado por ConstrainedBox(minHeight)
      // + FittedBox no conteúdo, para o botão crescer com o texto/ícone em
      // vez de forçar corte quando _escalaTexto aumenta ou a tela é estreita.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: _sosEmAndamento ? null : _executarSOS,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_sosEmAndamento)
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.emergency, size: 34),
                const SizedBox(width: 10),
                Text(
                  _sosEmAndamento ? 'Acionando SOS...' : 'SOS Emergência',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTituloSecao(String texto, _CoresHome cores) => Text(
    texto,
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: cores.texto,
    ),
  );

  Widget _buildGradeAtalhos(_CoresHome cores) {
    final atalhos =
        [
              _AtalhoHome(
                icone: Icons.message_outlined,
                titulo: 'Verificar mensagem',
                descricao: 'Analise mensagens suspeitas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalisarMensagemPage(),
                  ),
                ),
              ),
              _AtalhoHome(
                icone: Icons.link,
                titulo: 'Verificar link',
                descricao: 'Confira links antes de abrir',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VerificarLinkPage(),
                  ),
                ),
              ),
              _AtalhoHome(
                icone: Icons.shield_outlined,
                titulo: 'Dicas de proteção',
                descricao: 'Aprenda a se proteger',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DicasPage()),
                ),
              ),
              _AtalhoHome(
                icone: Icons.medication_outlined,
                titulo: 'Lembretes de remédios',
                descricao: 'Gerencie seus horários',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LembretesRemediosPage(),
                  ),
                ),
              ),
              _AtalhoHome(
                icone: Icons.contact_emergency,
                titulo: 'Contatos de emergência',
                descricao: 'Lista de pessoas de confiança',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContatosEmergenciaPage(),
                  ),
                ),
              ),
              _AtalhoHome(
                icone: Icons.call_received,
                titulo: 'Histórico de chamadas',
                descricao: 'Veja quem ligou e se era suspeito',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoricoChamadasPage(),
                  ),
                ),
              ),
              _AtalhoHome(
                icone: Icons.history,
                titulo: 'Histórico',
                descricao: 'Suas verificações anteriores',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoricoPage(),
                  ),
                ),
              ),
            ]
            .where(
              (atalho) =>
                  _busca.isEmpty ||
                  '${atalho.titulo} ${atalho.descricao}'.toLowerCase().contains(
                    _busca,
                  ),
            )
            .toList();

    if (atalhos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Nenhum recurso encontrado.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: atalhos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) =>
          _buildCartaoAtalho(atalhos[index], cores),
    );
  }

  Widget _buildCartaoAtalho(_AtalhoHome atalho, _CoresHome cores) {
    return Semantics(
      button: true,
      label: '${atalho.titulo}. ${atalho.descricao}',
      child: Material(
        color: cores.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: atalho.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            // FIX 2: mainAxisSize.min + Flexible/maxLines/overflow no texto
            // evitam que o título estoure a altura fixa do card quando
            // o texto é ampliado (alto contraste/zoom).
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(atalho.icone, color: cores.icone, size: 42),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    atalho.titulo,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cores.texto,
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

  Widget _buildStatusSeguranca(_CoresHome cores) {
    return Semantics(
      label: 'Status de segurança: tudo certo. Nenhuma ameaça encontrada hoje.',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cores.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cores.borda, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_user, color: cores.icone, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Tudo certo!\nNenhuma ameaça foi encontrada hoje.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cores.texto,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoresHome {
  final Color fundo;
  final Color texto;
  final Color card;
  final Color borda;
  final Color campo;
  final Color icone;
  final Color textoSecundario;
  final Color destaque;
  final Color destaqueTexto;

  const _CoresHome({
    required this.fundo,
    required this.texto,
    required this.card,
    required this.borda,
    required this.campo,
    required this.icone,
    required this.textoSecundario,
    required this.destaque,
    required this.destaqueTexto,
  });
}
