import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/acessibilidade_service.dart';
import '../telas/login_page.dart';
import 'acolle_design.dart';

/// Ações de conta compartilhadas entre telas (antes ficavam dentro da Home).
/// O conteúdo foi apenas movido; a lógica é a mesma.

Future<void> confirmarSaida(BuildContext context) async {
  final acessibilidade = AcessibilidadeService.instance;

  final sair = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final altoContraste =
          acessibilidade.altoContraste;

      return AlertDialog(
        backgroundColor:
            AcolleDesign.corCard(
          altoContraste,
        ),
        title: Text(
          'Sair da conta',
          style: AcolleDesign.tituloDialogo,
        ),
        content: Text(
          'Deseja realmente sair da sua conta?',
          style: AcolleDesign.textoDialogo,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                false,
              );
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  AcolleDesign.vermelho,
            ),
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },
            child: const Text('Sair'),
          ),
        ],
      );
    },
  );

  if (sair != true) return;

  await FirebaseAuth.instance.signOut();

  if (!context.mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const LoginPage(),
    ),
    (route) => false,
  );
}

void abrirAcessibilidade(BuildContext context) {
  final acessibilidade = AcessibilidadeService.instance;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final altoContraste =
              acessibilidade.altoContraste;

          return Material(
            color: AcolleDesign.corFundo(
              altoContraste,
            ),
            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  32,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Acessibilidade',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color:
                              AcolleDesign.corTexto(
                            altoContraste,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Ajuste a leitura para ficar mais confortável.',
                        style: TextStyle(
                          fontSize: 17,
                          color: AcolleDesign
                              .corTextoSecundario(
                            altoContraste,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Icon(
                            Icons.text_decrease_rounded,
                            size: 30,
                            color:
                                AcolleDesign.corIcone(
                              altoContraste,
                            ),
                          ),

                          Expanded(
                            child: Slider(
                              value: acessibilidade
                                  .escalaTexto,
                              min: 0.9,
                              max: 1.4,
                              divisions: 5,
                              activeColor:
                                  AcolleDesign
                                      .corIcone(
                                altoContraste,
                              ),
                              label:
                                  '${(acessibilidade.escalaTexto * 100).round()}%',
                              onChanged: (valor) {
                                acessibilidade
                                    .alterarEscalaTexto(
                                  valor,
                                );

                                setModalState(
                                  () {},
                                );
                              },
                            ),
                          ),

                          Icon(
                            Icons.text_increase_rounded,
                            size: 30,
                            color:
                                AcolleDesign.corIcone(
                              altoContraste,
                            ),
                          ),
                        ],
                      ),

                      SwitchListTile.adaptive(
                        contentPadding:
                            EdgeInsets.zero,
                        title: Text(
                          'Alto contraste',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight.bold,
                            color: AcolleDesign
                                .corTexto(
                              altoContraste,
                            ),
                          ),
                        ),
                        subtitle: Text(
                          'Aumenta a diferença entre as cores.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AcolleDesign
                                .corTextoSecundario(
                              altoContraste,
                            ),
                          ),
                        ),
                        value: altoContraste,
                        activeColor:
                            AcolleDesign.laranja,
                        onChanged: (valor) {
                          acessibilidade
                              .alterarAltoContraste(
                            valor,
                          );

                          setModalState(
                            () {},
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              AcolleDesign.corIcone(
                            altoContraste,
                          ),
                          foregroundColor:
                              altoContraste
                                  ? Colors.black
                                  : Colors.white,
                          minimumSize:
                              const Size.fromHeight(
                            54,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                          );
                        },
                        child: const Text(
                          'Concluir',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
