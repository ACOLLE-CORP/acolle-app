import 'package:flutter/material.dart';

import '../services/acessibilidade_service.dart';
import '../shared/acolle_design.dart';
import '../shared/acolle_icons.dart';
import 'analisar_mensagem_page.dart';
import 'botao_flutuante.dart';
import 'verificar_link_page.dart';

class ProtegerPage extends StatelessWidget {
  const ProtegerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final acessibilidade = AcessibilidadeService.instance;
    final altoContraste = acessibilidade.altoContraste;

    return Scaffold(
      backgroundColor: AcolleDesign.corFundo(altoContraste),
      appBar: AcolleDesign.appBarPadrao(
        'PROTEÇÃO',
        centralizado: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Proteja-se de golpes',
                style: AcolleDesign.texto(
                  tamanho: 27,
                  peso: FontWeight.bold,
                  cor: AcolleDesign.corTexto(
                    altoContraste,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Os botões a seguir são para o senhor(a) descobrir se a mensagem, link ou ligação que recebeu pode ser golpe.',
                style: AcolleDesign.texto(
                  tamanho: 17,
                  cor: AcolleDesign.corTextoSecundario(
                    altoContraste,
                  ),
                  altura: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              _Opcao(
                icone: AcolleIcons.mensagem,
                titulo: 'Verificar mensagem',
                descricao:
                    'Analise uma mensagem antes de confiar nela.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AnalisarMensagemPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _Opcao(
                icone: AcolleIcons.link,
                titulo: 'Verificar link',
                descricao:
                    'Confira um link antes de abrir.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const VerificarLinkPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Proteção rápida (botão flutuante que continua fora do app).
              // Antes ficava na Home.
              const BotaoFlutuanteCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final altoContraste =
        AcessibilidadeService.instance.altoContraste;

    return Semantics(
      button: true,
      label: '$titulo. $descricao',
      child: Material(
        color: AcolleDesign.corCard(
          altoContraste,
        ),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AcolleDesign.corFundo(
                      altoContraste,
                    ),
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color: AcolleDesign.corBorda(
                        altoContraste,
                      ),
                    ),
                  ),
                  child: Icon(
                    icone,
                    size: 30,
                    color: AcolleDesign.corIcone(
                      altoContraste,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: AcolleDesign.texto(
                          tamanho: 19,
                          peso: FontWeight.bold,
                          cor:
                              AcolleDesign.corTexto(
                            altoContraste,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descricao,
                        style: AcolleDesign.texto(
                          tamanho: 15,
                          cor: AcolleDesign
                              .corTextoSecundario(
                            altoContraste,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  AcolleIcons.avancar,
                  size: 30,
                  color: AcolleDesign.corIcone(
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
}
