import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/acessibilidade_service.dart';
import '../services/exclusao_conta_service.dart';
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

  _voltarParaLogin(context);
}

void _voltarParaLogin(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const LoginPage(),
    ),
    (route) => false,
  );
}

Future<void> confirmarExclusaoConta(BuildContext context) async {
  var senha = '';
  var excluindo = false;
  String? erro;
  final excluida = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, atualizar) => PopScope(
        canPop: !excluindo,
        child: AlertDialog(
          title: const Text('Excluir conta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Esta ação é definitiva. Seu perfil, histórico, lembretes '
                  'e contatos de emergência serão apagados.',
                ),
                const SizedBox(height: 16),
                TextField(
                  obscureText: true,
                  enabled: !excluindo,
                  decoration: InputDecoration(
                    labelText: 'Confirme sua senha',
                    errorText: erro,
                    errorMaxLines: 4,
                  ),
                  onChanged: (valor) => atualizar(() {
                    senha = valor;
                    erro = null;
                  }),
                ),
                if (excluindo) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(semanticsLabel: 'Excluindo conta'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: excluindo ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AcolleDesign.vermelho),
              onPressed: excluindo || senha.isEmpty ? null : () async {
                atualizar(() {
                  excluindo = true;
                  erro = null;
                });
                String? falha;
                try {
                  await ExclusaoContaService.excluir(senha);
                } on FirebaseAuthException catch (e) {
                  falha = switch (e.code) {
                    'wrong-password' || 'invalid-credential' =>
                      'Confira sua senha e tente novamente.',
                    'too-many-requests' =>
                      'Aguarde alguns minutos e tente novamente.',
                    _ => 'Não foi possível concluir. Tente novamente.',
                  };
                } catch (_) {
                  falha = 'Não foi possível concluir. Verifique a conexão e tente novamente.';
                }
                if (!dialogContext.mounted) return;
                if (falha == null) {
                  Navigator.pop(dialogContext, true);
                } else {
                  atualizar(() {
                    excluindo = false;
                    erro = falha;
                  });
                }
              },
              child: const Text('Excluir minha conta'),
            ),
          ],
        ),
      ),
    ),
  );
  if (excluida == true && context.mounted) _voltarParaLogin(context);
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
