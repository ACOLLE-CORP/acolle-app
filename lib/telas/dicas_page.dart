import 'package:flutter/material.dart';

import '../services/acessibilidade_service.dart';
import '../shared/acolle_design.dart';

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
    final contraste = AcolleDesign.altoContraste;

    return Scaffold(
      backgroundColor: AcolleDesign.corFundo(contraste),

      appBar: AcolleDesign.appBarPadrao(
        'Dicas de Segurança',
        centralizado: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'Proteja-se de golpes',
                style: AcolleDesign.texto(
                  tamanho: 28,
                  cor: AcolleDesign.corTexto(contraste),
                  peso: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Leia estas dicas antes de atender ligações ou mensagens.',
                style: AcolleDesign.texto(
                  tamanho: 20,
                  cor: AcolleDesign.corTextoSecundario(
                    contraste,
                  ),
                  altura: 1.3,
                ),
              ),

              const SizedBox(height: 30),

              _criarDica(
                icone: Icons.phone,
                titulo: 'Não passe sua senha',
                descricao:
                    'Nenhum banco pede senha por telefone. '
                    'Se alguém pedir, desligue na hora.',
              ),

              _criarDica(
                icone: Icons.link,
                titulo: 'Não clique em links',
                descricao:
                    'Abra apenas mensagens de pessoas conhecidas. '
                    'Links podem levar para páginas falsas ou perigosas.',
              ),

              _criarDica(
                icone: Icons.payments,
                titulo: 'Desconfie de pedidos',
                descricao:
                    'Antes de enviar dinheiro, confirme com um familiar '
                    'ou diretamente com seu banco.',
              ),

              _criarDica(
                icone: Icons.call_received,
                titulo: 'Números estranhos',
                descricao:
                    'Se receber ligação de número desconhecido pedindo '
                    'informações, desligue.',
              ),

              _criarDica(
                icone: Icons.warning_amber_rounded,
                titulo: 'Prêmios não pedidos',
                descricao:
                    'Se ganhou algo de uma promoção da qual não participou, '
                    'desconfie. Não forneça seus dados.',
              ),

              const SizedBox(height: 10),

              _buildCardPrincipal(),

              const SizedBox(height: 30),

              _buildNumerosEmergencia(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DICA
  // ============================================================

  Widget _criarDica({
    required IconData icone,
    required String titulo,
    required String descricao,
  }) {
    final contraste = AcolleDesign.altoContraste;

    return AcolleDesign.cartao(
      margem: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),

      filho: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 56,
            height: 56,

            decoration: BoxDecoration(
              color: contraste
                  ? Colors.black
                  : AcolleDesign.laranja.withValues(
                      alpha: 0.15,
                    ),

              borderRadius: BorderRadius.circular(14),

              border: Border.all(
                color: AcolleDesign.corIcone(contraste),
                width: 1,
              ),
            ),

            child: Center(
              child: Icon(
                icone,
                color: AcolleDesign.corIcone(contraste),
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
                  style: AcolleDesign.texto(
                    tamanho: 18,
                    cor: AcolleDesign.corTexto(contraste),
                    peso: FontWeight.bold,
                    altura: 1.2,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  descricao,
                  style: AcolleDesign.texto(
                    tamanho: 15,
                    cor: AcolleDesign.corTextoSecundario(
                      contraste,
                    ),
                    altura: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD PRINCIPAL
  // ============================================================

  Widget _buildCardPrincipal() {
    final contraste = AcolleDesign.altoContraste;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: AcolleDesign.laranja,

        borderRadius: BorderRadius.circular(20),

        border: contraste
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
            color: Colors.black,
            size: 60,
          ),

          const SizedBox(height: 15),

          Text(
            'Em caso de dúvida,\nnão responda imediatamente.',
            textAlign: TextAlign.center,

            style: AcolleDesign.texto(
              tamanho: 22,
              cor: Colors.black,
              peso: FontWeight.bold,
              altura: 1.25,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Peça ajuda para um familiar ou pessoa de confiança.',
            textAlign: TextAlign.center,

            style: AcolleDesign.texto(
              tamanho: 18,
              cor: Colors.black,
              altura: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NÚMEROS DE EMERGÊNCIA
  // ============================================================

  Widget _buildNumerosEmergencia() {
    final contraste = AcolleDesign.altoContraste;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AcolleDesign.corCard(contraste),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: contraste
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
                color: AcolleDesign.corIcone(contraste),
                size: 28,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Números de emergência úteis',

                  style: AcolleDesign.texto(
                    tamanho: 18,
                    cor: AcolleDesign.corIcone(
                      contraste,
                    ),
                    peso: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildEmergencyNumber(
            'Polícia',
            '190',
          ),

          _buildEmergencyNumber(
            'Bombeiros',
            '193',
          ),

          _buildEmergencyNumber(
            'Ambulância',
            '192',
          ),

          _buildEmergencyNumber(
            'Disque Denúncia',
            '100',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NÚMERO INDIVIDUAL
  // ============================================================

  Widget _buildEmergencyNumber(
    String label,
    String numero,
  ) {
    final contraste = AcolleDesign.altoContraste;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.phone,
            size: 18,
            color: AcolleDesign.corIcone(contraste),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',

                    style: AcolleDesign.texto(
                      tamanho: 16,
                      cor: AcolleDesign.corTexto(
                        contraste,
                      ),
                      peso: FontWeight.w600,
                    ),
                  ),

                  TextSpan(
                    text: numero,

                    style: AcolleDesign.texto(
                      tamanho: 16,
                      cor: AcolleDesign.corIcone(
                        contraste,
                      ),
                      peso: FontWeight.bold,
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
}