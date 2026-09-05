import 'package:flutter/material.dart';

import '../services/acessibilidade_service.dart';
import '../shared/acolle_design.dart';
import '../shared/acolle_icons.dart';
import 'dicas_page.dart';

class AprenderPage extends StatelessWidget {
  const AprenderPage({super.key});

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
        'Aprender',
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
                'Aprenda a se proteger',
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
                'Informações simples para ajudar você a reconhecer golpes.',
                style:
                    AcolleDesign.texto(
                  tamanho: 17,
                  cor:
                      AcolleDesign.corTextoSecundario(
                    altoContraste,
                  ),
                  altura: 1.3,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              _Opcao(
                icone:
                    AcolleIcons.aprender,
                titulo:
                    'Dicas de segurança',
                descricao:
                    'Veja dicas para evitar golpes por telefone, mensagens e links.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const DicasPage(),
                    ),
                  );
                },
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
              const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
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
                  size: 32,
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
                      height: 5,
                    ),
                    Text(
                      descricao,
                      style:
                          AcolleDesign.texto(
                        tamanho: 16,
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
