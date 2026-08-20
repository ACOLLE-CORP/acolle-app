import 'package:flutter/material.dart';

import '../services/acessibilidade_service.dart';

const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);
const Color laranjaAcolle = Color(0xFFF47A07);

class DicasPage extends StatefulWidget {
  const DicasPage({super.key});

  @override
  State<DicasPage> createState() => _DicasPageState();
}

class _DicasPageState extends State<DicasPage> {
  @override
  void initState() {
    super.initState();

    AcessibilidadeService.instance.addListener(
      _onAcessibilidadeChanged,
    );

    AcessibilidadeService.instance.carregar();
  }

  void _onAcessibilidadeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    AcessibilidadeService.instance.removeListener(
      _onAcessibilidadeChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acessibilidade = AcessibilidadeService.instance;

    final bool altoContraste = acessibilidade.altoContraste;
    final double escalaTexto = acessibilidade.escalaTexto;

    final Color fundo =
        altoContraste ? Colors.black : fundoAcolle;

    final Color texto =
        altoContraste ? Colors.white : const Color(0xFF25212B);

    final Color textoSecundario =
        altoContraste ? Colors.white : Colors.black87;

    final Color card =
        altoContraste ? Colors.black : Colors.white;

    final Color borda =
        altoContraste ? Colors.white : const Color(0xFFE0DCE5);

    final Color icone =
        laranjaAcolle;

    final Color destaque =
        laranjaAcolle;

    final Color destaqueTexto =
        Colors.black;

    return Scaffold(
      backgroundColor: fundo,

      appBar: AppBar(
        backgroundColor: fundo,
        elevation: 0,
        centerTitle: true,

        iconTheme: IconThemeData(
          color: icone,
        ),

        title: Text(
          'Dicas de Segurança',
          style: TextStyle(
            fontSize: 24 * escalaTexto,
            fontWeight: FontWeight.bold,
            color: destaque,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proteja-se de golpes',
                style: TextStyle(
                  fontSize: 28 * escalaTexto,
                  fontWeight: FontWeight.bold,
                  color: texto,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Leia estas dicas antes de atender ligações ou mensagens.',
                style: TextStyle(
                  fontSize: 20 * escalaTexto,
                  color: textoSecundario,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 30),

              _criarDica(
                icone: Icons.phone,
                titulo: 'Não passe sua senha',
                texto:
                    'Nenhum banco pede senha por telefone. '
                    'Se alguém pedir, desligue na hora.',
                card: card,
                borda: borda,
                textocor: texto,
                textoSecundario: textoSecundario,
                iconeCor: icone,
                escalaTexto: escalaTexto,
              ),

              _criarDica(
                icone: Icons.link,
                titulo: 'Não clique em links',
                texto:
                    'Abra apenas mensagens de pessoas conhecidas. '
                    'Links podem levar para páginas falsas ou perigosas.',
                card: card,
                borda: borda,
                textocor: texto,
                textoSecundario: textoSecundario,
                iconeCor: icone,
                escalaTexto: escalaTexto,
              ),

              _criarDica(
                icone: Icons.payments,
                titulo: 'Desconfie de pedidos',
                texto:
                    'Antes de enviar dinheiro, confirme com um familiar '
                    'ou diretamente com seu banco.',
                card: card,
                borda: borda,
                textocor: texto,
                textoSecundario: textoSecundario,
                iconeCor: icone,
                escalaTexto: escalaTexto,
              ),

              _criarDica(
                icone: Icons.call_received,
                titulo: 'Números estranhos',
                texto:
                    'Se receber ligação de número desconhecido pedindo '
                    'informações, desligue.',
                card: card,
                borda: borda,
                textocor: texto,
                textoSecundario: textoSecundario,
                iconeCor: icone,
                escalaTexto: escalaTexto,
              ),

              _criarDica(
                icone: Icons.warning_amber_rounded,
                titulo: 'Prêmios não pedidos',
                texto:
                    'Se ganhou algo de uma promoção da qual não participou, '
                    'desconfie. Não forneça seus dados.',
                card: card,
                borda: borda,
                textocor: texto,
                textoSecundario: textoSecundario,
                iconeCor: icone,
                escalaTexto: escalaTexto,
              ),

              const SizedBox(height: 10),

              // CARD PRINCIPAL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: destaque,
                  borderRadius: BorderRadius.circular(20),

                  border: altoContraste
                      ? Border.all(
                          color: Colors.white,
                          width: 2,
                        )
                      : null,
                ),

                child: Column(
                  children: [
                    Icon(
                      Icons.shield,
                      color: destaqueTexto,
                      size: 60,
                    ),

                    const SizedBox(height: 15),

                    Text(
                      'Em caso de dúvida,\nnão responda imediatamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: destaqueTexto,
                        fontSize: 22 * escalaTexto,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Peça ajuda para um familiar ou pessoa de confiança.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: destaqueTexto,
                        fontSize: 18 * escalaTexto,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // NÚMEROS DE EMERGÊNCIA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: altoContraste
                      ? Colors.black
                      : Colors.amber.shade50,

                  borderRadius: BorderRadius.circular(16),

                  border: Border.all(
                    color: altoContraste
                        ? Colors.white
                        : Colors.amber.shade300,
                    width: 1.5,
                  ),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: icone,
                          size: 28,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'Números de emergência úteis',
                            style: TextStyle(
                              fontSize: 18 * escalaTexto,
                              fontWeight: FontWeight.bold,
                              color: icone,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _buildEmergencyNumber(
                      'Polícia',
                      '190',
                      texto: texto,
                      icone: icone,
                      escalaTexto: escalaTexto,
                    ),

                    _buildEmergencyNumber(
                      'Bombeiros',
                      '193',
                      texto: texto,
                      icone: icone,
                      escalaTexto: escalaTexto,
                    ),

                    _buildEmergencyNumber(
                      'Ambulância',
                      '192',
                      texto: texto,
                      icone: icone,
                      escalaTexto: escalaTexto,
                    ),

                    _buildEmergencyNumber(
                      'Disque Denúncia',
                      '100',
                      texto: texto,
                      icone: icone,
                      escalaTexto: escalaTexto,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyNumber(
    String label,
    String numero, {
    required Color texto,
    required Color icone,
    required double escalaTexto,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.phone,
            size: 18,
            color: icone,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontSize: 16 * escalaTexto,
                      fontWeight: FontWeight.w600,
                      color: texto,
                    ),
                  ),
                  TextSpan(
                    text: numero,
                    style: TextStyle(
                      fontSize: 16 * escalaTexto,
                      fontWeight: FontWeight.bold,
                      color: icone,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _criarDica({
    required IconData icone,
    required String titulo,
    required String texto,
    required Color card,
    required Color borda,
    required Color textocor,
    required Color textoSecundario,
    required Color iconeCor,
    required double escalaTexto,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: borda,
          width: 1.5,
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 56,
            height: 56,

            decoration: BoxDecoration(
              color: laranjaAcolle.withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: iconeCor,
                width: 1,
              ),
            ),

            child: Center(
              child: Icon(
                icone,
                color: iconeCor,
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
                  style: TextStyle(
                    fontSize: 18 * escalaTexto,
                    fontWeight: FontWeight.bold,
                    color: textocor,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 15 * escalaTexto,
                    height: 1.5,
                    color: textoSecundario,
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