import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'login_page.dart';
import 'dicas_page.dart';
import 'analisar_mensagem_page.dart';
import '../services/caller_id_service.dart';

const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);
const Color laranjaAcolle = Color(0xFFF47A07);
const Color cinzaCardAcolle = Color(0xFFF3EEFA);

class _AtalhoHome {
  final IconData icone;
  final String titulo;
  final VoidCallback onTap;

  const _AtalhoHome({
    required this.icone,
    required this.titulo,
    required this.onTap,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _iniciarCallerId();
  }

  Future<void> _iniciarCallerId() async {
    final status = await Permission.phone.request();

    if (status.isGranted) {
      CallerIdService.iniciarMonitoramento((numero) {
        _mostrarAlertaNumero(numero);
      });
    }
  }

  void _mostrarAlertaNumero(String numero) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Atenção!'),
          ],
        ),
        content: Text(
          'O número $numero está na lista de números suspeitos de golpe. Tenha cuidado ao atender.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    CallerIdService.pararMonitoramento();
    super.dispose();
  }

  Future<void> _confirmarSaida(BuildContext context) async {
    bool? sair = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Sair',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Deseja realmente sair da conta?',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 18),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sair',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (sair == true) {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomeUsuario = FirebaseAuth.instance.currentUser?.displayName;

    final saudacao =
        (nomeUsuario != null && nomeUsuario.trim().isNotEmpty)
            ? 'Olá, ${nomeUsuario.trim().split(' ').first}!'
            : 'Olá!';

    return Scaffold(
      backgroundColor: fundoAcolle,

      appBar: AppBar(
        backgroundColor: fundoAcolle,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          'Acolle',
          style: TextStyle(
            color: roxoAcolle,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),

        actions: [
          IconButton(
            iconSize: 34,
            icon: const Icon(
              Icons.logout,
              color: roxoAcolle,
            ),
            onPressed: () => _confirmarSaida(context),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              _buildBarraBusca(),

              const SizedBox(height: 26),

              _buildMascoteSaudacao(saudacao),

              const SizedBox(height: 28),

              _buildBotaoEmergencia(context),

              const SizedBox(height: 22),

              _buildGradeAtalhos(context),

              const SizedBox(height: 22),

              _buildStatusSeguranca(),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarraBusca() {
    return Container(
      height: 64,

      padding: const EdgeInsets.symmetric(horizontal: 18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),

      child: const TextField(
        style: TextStyle(
          fontSize: 20,
        ),

        decoration: InputDecoration(
          border: InputBorder.none,

          hintText: 'Buscar',

          hintStyle: TextStyle(
            fontSize: 19,
          ),

          prefixIcon: Icon(
            Icons.search,
            size: 30,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildMascoteSaudacao(String saudacao) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,

      children: [

        Image.asset(
          'assets/images/mascote.png',
          height: 95,
          width: 95,
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 18,
            ),

            margin: const EdgeInsets.only(bottom: 12),

            decoration: const BoxDecoration(
              color: roxoAcolle,

              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
            ),

            child: Text(
              saudacao,

              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoEmergencia(BuildContext context) {
    return Material(
      color: Colors.red,

      borderRadius: BorderRadius.circular(22),

      child: InkWell(
        borderRadius: BorderRadius.circular(22),

        onTap: () {
          // TODO: fluxo de SOS Emergência
        },

        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),

          child: Row(
            children: [

              SizedBox(width: 18),

              Expanded(
                child: Text(
                  'SOS Emergência !',

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeAtalhos(BuildContext context) {
    final atalhos = [
      _AtalhoHome(
        icone: Icons.message_outlined,
        titulo: 'Verificar\nmensagem',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AnalisarMensagemPage(),
            ),
          );
        },
      ),
      _AtalhoHome(
        icone: Icons.link,
        titulo: 'Verificar\nlink',
        onTap: () {
          // TODO: Tela de análise de link
        },
      ),
      _AtalhoHome(
        icone: Icons.shield_outlined,
        titulo: 'Dicas de\nproteção',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DicasPage(),
            ),
          );
        },
      ),
      _AtalhoHome(
        icone: Icons.history,
        titulo: 'Histórico',
        onTap: () {
          // TODO: Tela de histórico
        },
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      mainAxisSpacing: 18,
      crossAxisSpacing: 18,

      childAspectRatio: 0.90,

      children: atalhos
          .map((atalho) => _buildCartaoAtalho(atalho))
          .toList(),
    );
  }

  Widget _buildCartaoAtalho(_AtalhoHome atalho) {
    return Material(
      color: cinzaCardAcolle,

      borderRadius: BorderRadius.circular(22),

      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: atalho.onTap,

        child: Padding(
          padding: const EdgeInsets.all(22),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

            children: [

              Icon(
                atalho.icone,
                color: roxoAcolle,
                size: 44,
              ),

              const SizedBox(height: 18),

              Text(
                atalho.titulo,
                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSeguranca() {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: const Row(
        children: [

          Icon(
            Icons.verified_user,
            color: roxoAcolle,
            size: 46,
          ),

          SizedBox(width: 16),

          Expanded(
            child: Text(
              'Tudo certo!\nNenhuma ameaça foi encontrada hoje.',

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),

        ],
      ),
    );
  }
}