import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/caller_id_service.dart';
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
  double _escalaTexto = 1;
  bool _altoContraste = false;

  @override
  void initState() {
    super.initState();
    _iniciarCallerId();
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
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
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
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          // FIX 4: SingleChildScrollView evita overflow do modal em telas
          // pequenas quando _escalaTexto aumenta o tamanho do conteúdo.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Acessibilidade', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Ajuste a leitura para ficar mais confortável.', style: TextStyle(fontSize: 17)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.text_decrease, size: 30),
                    Expanded(
                      child: Slider(
                        value: _escalaTexto,
                        min: 0.9,
                        max: 1.4,
                        divisions: 5,
                        label: '${(_escalaTexto * 100).round()}%',
                        onChanged: (valor) {
                          setState(() => _escalaTexto = valor);
                          setModalState(() {});
                        },
                      ),
                    ),
                    const Icon(Icons.text_increase, size: 30),
                  ],
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alto contraste', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Aumenta a diferença entre cores.', style: TextStyle(fontSize: 16)),
                  value: _altoContraste,
                  onChanged: (valor) {
                    setState(() => _altoContraste = valor);
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
      ),
    );
  }

  void _confirmarEmergencia() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          // FIX 3: SingleChildScrollView garante que, em telas baixas
          // (landscape/dispositivos pequenos), o conteúdo do modal role
          // em vez de estourar a altura disponível.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pedir ajuda agora',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: roxoAcolle),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Toque em "Ligar" para chamar um contato de emergência. '
                  'Você também pode enviar uma mensagem automática.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                // FIX 3: altura relativa à tela em vez de valor fixo (300),
                // evitando overflow em telas menores.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('contatos_emergencia')
                        .where('usuarioId', isEqualTo: user.uid)
                        .orderBy('criadoEm', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.contact_emergency_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text('Você ainda não tem contatos de emergência.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar agora'),
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => const ContatosEmergenciaPage()));
                              },
                            ),
                          ],
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final d = docs[index].data();
                          final nome = d['nome'] as String? ?? '';
                          final telefone = d['telefone'] as String? ?? '';
                          return ListTile(
                            leading: const Icon(Icons.person, color: roxoAcolle),
                            title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(telefone),
                            trailing: Wrap(
                              children: [
                                IconButton(
                                  tooltip: 'Ligar',
                                  icon: const Icon(Icons.phone, color: Colors.green),
                                  onPressed: () => EmergenciaService.ligarPara(telefone),
                                ),
                                IconButton(
                                  tooltip: 'Enviar mensagem',
                                  icon: const Icon(Icons.message, color: roxoAcolle),
                                  onPressed: () => EmergenciaService.abrirSms(telefone,
                                      'Oi $nome, preciso de ajuda. Mensagem do app Acolle.'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                  icon: const Icon(Icons.local_police),
                  label: const Text('Ligar para 190 (Polícia)'),
                  onPressed: () => EmergenciaService.ligarPara('190'),
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
    CallerIdService.pararMonitoramento();
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nome = FirebaseAuth.instance.currentUser?.displayName?.trim();
    final saudacao = nome?.isNotEmpty == true ? 'Olá, ${nome!.split(' ').first}!' : 'Olá!';
    final cores = _altoContraste
        ? const _CoresHome(fundo: Colors.white, texto: Colors.black, card: Color(0xFFF0F0F0), borda: Colors.black)
        : const _CoresHome(fundo: fundoAcolle, texto: Color(0xFF25212B), card: cinzaCardAcolle, borda: Color(0xFFD4CBDD));

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_escalaTexto)),
      child: Scaffold(
        backgroundColor: cores.fundo,
        appBar: AppBar(
          backgroundColor: cores.fundo,
          title: const Text('Acolle', style: TextStyle(color: roxoAcolle, fontWeight: FontWeight.bold, fontSize: 28)),
          centerTitle: true,
          actions: [
            IconButton(tooltip: 'Acessibilidade', icon: const Icon(Icons.accessibility_new, color: roxoAcolle), onPressed: _abrirAcessibilidade),
            IconButton(tooltip: 'Meu Perfil', icon: const Icon(Icons.person_outline, color: roxoAcolle), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PerfilPage()))),
            IconButton(tooltip: 'Sair da conta', icon: const Icon(Icons.logout, color: roxoAcolle), onPressed: _confirmarSaida),
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
                _buildMascoteSaudacao(saudacao),
                const SizedBox(height: 24),
                _buildBotaoEmergencia(),
                const SizedBox(height: 24),
                _buildTituloSecao('Como podemos ajudar?'),
                const SizedBox(height: 12),
                _buildGradeAtalhos(cores),
                const SizedBox(height: 22),
                _buildStatusSeguranca(cores),
              ],
            ),
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
        onChanged: (valor) => setState(() => _busca = valor.trim().toLowerCase()),
        style: TextStyle(fontSize: 19, color: cores.texto),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Buscar uma ajuda',
          prefixIcon: const Icon(Icons.search, size: 28),
          suffixIcon: _busca.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _buscaController.clear();
                    setState(() => _busca = '');
                  },
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: cores.borda, width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: cores.borda, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildMascoteSaudacao(String saudacao) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ExcludeSemantics(child: Image.asset('assets/images/mascote.png', height: 88, width: 88)),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(color: roxoAcolle, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(5))),
            child: Text('$saudacao\nEstou aqui para proteger você.', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.25)),
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoEmergencia() {
    return Semantics(
      button: true,
      label: 'SOS Emergência. Toque para pedir ajuda.',
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: _confirmarEmergencia,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.emergency, size: 34),
                SizedBox(width: 10),
                Text('SOS Emergência', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTituloSecao(String texto) => Text(texto, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold));

  Widget _buildGradeAtalhos(_CoresHome cores) {
    final atalhos = [
      _AtalhoHome(icone: Icons.message_outlined, titulo: 'Verificar mensagem', descricao: 'Analise mensagens suspeitas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalisarMensagemPage()))),
      _AtalhoHome(icone: Icons.link, titulo: 'Verificar link', descricao: 'Confira links antes de abrir', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificarLinkPage()))),
      _AtalhoHome(icone: Icons.shield_outlined, titulo: 'Dicas de proteção', descricao: 'Aprenda a se proteger', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DicasPage()))),
      _AtalhoHome(icone: Icons.medication_outlined, titulo: 'Lembretes de remédios', descricao: 'Gerencie seus horários', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LembretesRemediosPage()))),
      _AtalhoHome(icone: Icons.contact_emergency, titulo: 'Contatos de emergência', descricao: 'Lista de pessoas de confiança', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContatosEmergenciaPage()))),
      _AtalhoHome(icone: Icons.call_received, titulo: 'Histórico de chamadas', descricao: 'Veja quem ligou e se era suspeito', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoricoChamadasPage()))),
      _AtalhoHome(icone: Icons.history, titulo: 'Histórico', descricao: 'Suas verificações anteriores', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoricoPage()))),
    ].where((atalho) => _busca.isEmpty || '${atalho.titulo} ${atalho.descricao}'.toLowerCase().contains(_busca)).toList();

    if (atalhos.isEmpty) {
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Nenhum recurso encontrado.', style: TextStyle(fontSize: 18))));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: atalhos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.92),
      itemBuilder: (context, index) => _buildCartaoAtalho(atalhos[index], cores),
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
                Icon(atalho.icone, color: roxoAcolle, size: 42),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    atalho.titulo,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cores.texto, height: 1.15),
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cores.borda, width: 1.2)),
        child: Row(
          children: [
            const Icon(Icons.verified_user, color: roxoAcolle, size: 42),
            const SizedBox(width: 14),
            Expanded(child: Text('Tudo certo!\nNenhuma ameaça foi encontrada hoje.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cores.texto, height: 1.35))),
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

  const _CoresHome({required this.fundo, required this.texto, required this.card, required this.borda});
}