import 'package:flutter/material.dart';

const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);
const Color laranjaAcolle = Color(0xFFF47A07);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            Image.asset(
              'assets/images/mascote_home.png',
              height: 180,
            ),

            const SizedBox(height: 10),

            const Text(
              'Olá!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: roxoAcolle,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Como posso ajudar você hoje?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 30),

            _botaoPrincipal(
              titulo: 'Analisar Mensagem',
              icone: Icons.search,
              cor: roxoAcolle,
              onTap: () {},
            ),

            const SizedBox(height: 15),

            _botaoPrincipal(
              titulo: 'Analisar Link',
              icone: Icons.link,
              cor: Colors.blue,
              onTap: () {},
            ),

            const SizedBox(height: 15),

            _botaoPrincipal(
              titulo: 'SOS Emergência',
              icone: Icons.sos,
              cor: Colors.red,
              onTap: () {},
            ),

            const SizedBox(height: 15),

            _botaoPrincipal(
              titulo: 'Dicas de Segurança',
              icone: Icons.shield_outlined,
              cor: laranjaAcolle,
              onTap: () {},
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Row(
                children: [
                  Icon(
                    Icons.security,
                    color: roxoAcolle,
                    size: 35,
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Nenhuma ameaça detectada hoje.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _botaoPrincipal({
    required String titulo,
    required IconData icone,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 65,

      child: ElevatedButton.icon(
        onPressed: onTap,

        icon: Icon(
          icone,
          color: Colors.white,
        ),

        label: Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}