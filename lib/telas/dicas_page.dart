import 'package:flutter/material.dart';

const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);

class DicasPage extends StatelessWidget {
  const DicasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoAcolle,

      appBar: AppBar(
        backgroundColor: fundoAcolle,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: roxoAcolle),
        title: const Text(
          "Dicas de Segurança",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: roxoAcolle,
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
                color: Color(0xFF25212B),
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
              "Nenhum banco pede senha por telefone. Se alguém pedir, desliga na hora.",
            ),

            _criarDica(
              Icons.link,
              "Não clique em links",
              "Abra apenas mensagens de pessoas conhecidas. Links podem ter vírus.",
            ),

            _criarDica(
              Icons.payments,
              "Desconfie de pedidos",
              "Antes de enviar dinheiro, confirme com um familiar ou seu banco.",
            ),

            _criarDica(
              Icons.call_received,
              "Números estranhos",
              "Se receber ligação de número desconhecido pedindo informações, desligue.",
            ),

            _criarDica(
              Icons.warning_amber_rounded,
              "Prêmios não pedidos",
              "Se ganhou algo que não participou, é golpe. Ignore e delete.",
            ),

            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: roxoAcolle,
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

            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade700, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Números de emergência úteis',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildEmergencyNumber('Polícia', '190'),
                  _buildEmergencyNumber('Bombeiros', '193'),
                  _buildEmergencyNumber('Ambulância', '192'),
                  _buildEmergencyNumber('Disque Denúncia (Golpes)', '100'),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyNumber(String label, String numero) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.phone, size: 18, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(numero, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade700)),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                icone,
                color: roxoAcolle,
                size: 32,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25212B),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
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