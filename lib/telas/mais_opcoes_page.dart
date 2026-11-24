import 'package:flutter/material.dart';

import '../services/acessibilidade_service.dart';
import '../shared/acoes_conta.dart';
import '../shared/acolle_design.dart';
import '../shared/acolle_icons.dart';
import 'configurar_protecao_chamadas_page.dart';
import 'historico_chamadas_page.dart';
import 'historico_page.dart';
import 'perfil_page.dart';
import 'termos_page.dart';

class MaisOpcoesPage extends StatelessWidget {
  const MaisOpcoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final acessibilidade =
        AcessibilidadeService.instance;

    final altoContraste =
        acessibilidade.altoContraste;

    return Scaffold(
      backgroundColor:
          AcolleDesign.corFundo(
        altoContraste,
      ),
      appBar:
          AcolleDesign.appBarPadrao(
        'Mais opções',
        centralizado: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mais opções',
                style:
                    AcolleDesign.texto(
                  tamanho: 27,
                  peso:
                      FontWeight.bold,
                  cor:
                      AcolleDesign.corTexto(
                    altoContraste,
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Outros recursos do Acolle ficam aqui para manter a tela inicial simples.',
                style:
                    AcolleDesign.texto(
                  tamanho: 17,
                  cor:
                      AcolleDesign.corTextoSecundario(
                    altoContraste,
                  ),
                  altura: 1.5,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              _Opcao(
                icone:
                    AcolleIcons.chamada,
                titulo:
                    'Proteção de chamadas',
                descricao:
                    'Configure a identificação de chamadas suspeitas.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ConfigurarProtecaoChamadasPage(
                        proxima: (_) =>
                            const HistoricoChamadasPage(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 12,
              ),

              _Opcao(
                icone:
                    AcolleIcons.chamadasRecebidas,
                titulo:
                    'Histórico de chamadas',
                descricao:
                    'Consulte chamadas identificadas pelo Acolle.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const HistoricoChamadasPage(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 12,
              ),

              _Opcao(
                icone:
                    AcolleIcons.historico,
                titulo:
                    'Histórico de verificações',
                descricao:
                    'Consulte mensagens, links e chamadas analisadas.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const HistoricoPage(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 12,
              ),

              _Opcao(
                icone:
                    AcolleIcons.perfil,
                titulo:
                    'Meu perfil',
                descricao:
                    'Veja e altere seus dados pessoais.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const PerfilPage(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 12,
              ),

              _Opcao(
                icone:
                    AcolleIcons.acessibilidade,
                titulo:
                    'Acessibilidade',
                descricao:
                    'Tamanho das letras e alto contraste.',
                onTap: () =>
                    abrirAcessibilidade(context),
              ),

              const SizedBox(
                height: 12,
              ),

              _Opcao(
                icone:
                    AcolleIcons.sair,
                titulo:
                    'Sair da conta',
                descricao:
                    'Encerrar a sessão neste aparelho.',
                onTap: () =>
                    confirmarSaida(context),
              ),
              const SizedBox(height: 12),
              _Opcao(
                icone: Icons.privacy_tip_outlined,
                titulo: 'Termos e privacidade',
                descricao: 'Saiba como seus dados são usados.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermosPage(onboarding: false),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Opcao(
                icone: Icons.delete_forever_outlined,
                titulo: 'Excluir conta',
                descricao: 'Apague sua conta e seus dados do Acolle.',
                onTap: () => confirmarExclusaoConta(context),
              ),
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
        AcessibilidadeService
            .instance
            .altoContraste;

    return Material(
      color:
          AcolleDesign.corCard(
        altoContraste,
      ),
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration:
                    BoxDecoration(
                  color:
                      AcolleDesign.corFundo(
                    altoContraste,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  border: Border.all(
                    color:
                        AcolleDesign.corBorda(
                      altoContraste,
                    ),
                  ),
                ),
                child: Icon(
                  icone,
                  size: 30,
                  color:
                      AcolleDesign.corIcone(
                    altoContraste,
                  ),
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style:
                          AcolleDesign.texto(
                        tamanho: 19,
                        peso:
                            FontWeight.bold,
                        cor:
                            AcolleDesign.corTexto(
                          altoContraste,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      descricao,
                      style:
                          AcolleDesign.texto(
                        tamanho: 15,
                        cor:
                            AcolleDesign.corTextoSecundario(
                          altoContraste,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                AcolleIcons.avancar,
                size: 30,
                color:
                    AcolleDesign.corIcone(
                  altoContraste,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
