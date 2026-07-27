import 'package:flutter/material.dart';

class DicasPage extends StatelessWidget {
  const DicasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFF773FD1),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Dicas de Segurança",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Proteja-se de golpes",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Leia estas dicas antes de atender ligações ou mensagens.",
              style: TextStyle(
                fontSize: 20,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 30),

            _criarDica(
              Icons.phone,
              "Não passe sua senha",
              "Nenhum banco pede senha por telefone.",
            ),

            _criarDica(
              Icons.link,
              "Não clique em links",
              "Abra apenas mensagens de pessoas conhecidas.",
            ),

            _criarDica(
              Icons.payments,
              "Desconfie de pedidos",
              "Antes de enviar dinheiro, confirme com um familiar.",
            ),

            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: const Color(0xFF773FD1),
                borderRadius: BorderRadius.circular(20),
              ),

              child: const Column(
                children: [

                  Icon(
                    Icons.shield,
                    color: Colors.white,
                    size: 60,
                  ),

                  SizedBox(height: 15),

                  Text(
                    "Em caso de dúvida,\nnão responda imediatamente.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "Peça ajuda para um familiar ou pessoa de confiança.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _criarDica(
      IconData icone,
      String titulo,
      String texto,
      ) {

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Icon(
            icone,
            color: const Color(0xFF773FD1),
            size: 50,
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}