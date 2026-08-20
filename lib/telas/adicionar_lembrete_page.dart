import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../shared/acolle_design.dart';
import '../services/notificacao_service.dart';
import '../services/acessibilidade_service.dart';

/// Tela para adicionar um novo lembrete de remédio:
/// nome, horário e frequência.
class AdicionarLembretePage extends StatefulWidget {
  const AdicionarLembretePage({super.key});

  @override
  State<AdicionarLembretePage> createState() =>
      _AdicionarLembretePageState();
}

class _AdicionarLembretePageState extends State<AdicionarLembretePage> {
  final TextEditingController _nomeController =
      TextEditingController();

  TimeOfDay? _horario;

  String _frequencia = 'Diário';

  bool _carregando = false;

  static const List<String> _opcoesFrequencia = [
    'Diário',
    'A cada 8 horas',
    'A cada 12 horas',
    'Semanal',
    'Sob demanda',
  ];

  AcessibilidadeService get acessibilidade =>
      AcessibilidadeService.instance;

  @override
  void initState() {
    super.initState();

    acessibilidade.addListener(
      _onAcessibilidadeChanged,
    );
  }

  // ============================================================
  // ATUALIZAÇÃO DA ACESSIBILIDADE
  // ============================================================

  void _onAcessibilidadeChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // ESCOLHER HORÁRIO
  // ============================================================

  Future<void> _escolherHorario() async {
    final agora = TimeOfDay.now();

    final horario = await showTimePicker(
      context: context,
      initialTime: _horario ?? agora,
      helpText: 'Escolha o horário do remédio',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (horario == null) return;

    if (!mounted) return;

    setState(() {
      _horario = horario;
    });
  }

  // ============================================================
  // FORMATAR HORÁRIO
  // ============================================================

  String _formatarHorario(TimeOfDay horario) {
    final hora =
        horario.hour.toString().padLeft(2, '0');

    final minuto =
        horario.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  // ============================================================
  // SALVAR
  // ============================================================

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();

    if (nome.isEmpty) {
      AcolleDesign.snackbar(
        context,
        'Digite o nome do remédio.',
      );

      return;
    }

    if (_horario == null) {
      AcolleDesign.snackbar(
        context,
        'Escolha o horário do remédio.',
      );

      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          AcolleDesign.snackbar(
            context,
            'Usuário não encontrado. Faça login novamente.',
          );
        }

        return;
      }

      final horarioFormatado =
          _formatarHorario(_horario!);

      // ----------------------------------------------------------
      // SALVAR NO FIRESTORE
      // ----------------------------------------------------------

      final doc = await FirebaseFirestore.instance
          .collection('remedios')
          .add({
        'usuarioId': user.uid,
        'nome': nome,
        'horario': horarioFormatado,
        'frequencia': _frequencia,
        'ativo': true,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      // ----------------------------------------------------------
      // AGENDAR NOTIFICAÇÃO
      // ----------------------------------------------------------

      await NotificacaoService.agendarLembrete(
        docId: doc.id,
        nome: nome,
        horario: horarioFormatado,
        frequencia: _frequencia,
      );

      if (!mounted) return;

      Navigator.pop(context);

      // ----------------------------------------------------------
      // CONFIRMAÇÃO
      // ----------------------------------------------------------

      AcolleDesign.snackbar(
        context,
        'Lembrete adicionado!',
        cor: AcolleDesign.verde,
      );
    } catch (e) {
      debugPrint(
        'Erro ao salvar lembrete: $e',
      );

      if (!mounted) return;

      AcolleDesign.snackbar(
        context,
        'Erro ao salvar lembrete.',
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final contraste =
        acessibilidade.altoContraste;

    // Essas cores vêm do AcolleDesign.
    final fundo =
        AcolleDesign.corFundo(contraste);

    final corTexto =
        AcolleDesign.corTexto(contraste);

    final corTextoSecundario =
        AcolleDesign.corTextoSecundario(
      contraste,
    );

    final corDestaque =
        AcolleDesign.corIcone(contraste);

    final corCard =
        AcolleDesign.corCard(contraste);

    final corBorda =
        AcolleDesign.corBorda(contraste);

    final corBotao =
        contraste
            ? Colors.orange
            : AcolleDesign.roxo;

    final corTextoBotao =
        contraste
            ? Colors.black
            : Colors.white;

    // ============================================================
    // TEMA LOCAL
    // ============================================================

    final tema = Theme.of(context).copyWith(
      brightness: contraste
          ? Brightness.dark
          : Brightness.light,

      scaffoldBackgroundColor: fundo,

      colorScheme: contraste
          ? const ColorScheme.dark(
              primary: Colors.orange,
              onPrimary: Colors.black,
              secondary: Colors.orange,
              onSecondary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            )
          : ColorScheme.fromSeed(
              seedColor: AcolleDesign.roxo,
            ),

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,

        fillColor: corCard,

        labelStyle:
            AcolleDesign.texto(
          tamanho: 17,
          cor: corTexto,
        ),

        hintStyle:
            AcolleDesign.texto(
          tamanho: 16,
          cor: corTextoSecundario,
        ),

        prefixIconColor:
            corDestaque,

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),

          borderSide: BorderSide(
            color: corBorda,
            width:
                contraste ? 2 : 1.5,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),

          borderSide: BorderSide(
            color: corDestaque,
            width: 3,
          ),
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),

          borderSide: BorderSide(
            color: corBorda,
          ),
        ),
      ),

      appBarTheme:
          AppBarTheme(
        backgroundColor: fundo,
        foregroundColor: corTexto,
        elevation: 0,
      ),

      dropdownMenuTheme:
          DropdownMenuThemeData(
        textStyle:
            AcolleDesign.texto(
          tamanho: 18,
          cor: corTexto,
        ),
      ),
    );

    return Theme(
      data: tema,

      child: Scaffold(
        backgroundColor: fundo,

        // ========================================================
        // APPBAR
        // ========================================================

        appBar: AcolleDesign.appBarPadrao(
          'Adicionar lembrete',
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(28),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,

              children: [
                // ==================================================
                // ÍCONE
                // ==================================================

                Icon(
                  Icons.medication_outlined,
                  size:
                      AcolleDesign.tamanhoTexto(
                    70,
                  ),
                  color: corDestaque,
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // TÍTULO
                // ==================================================

                Text(
                  'Adicionar lembrete de remédio',
                  textAlign:
                      TextAlign.center,

                  style:
                      AcolleDesign.texto(
                    tamanho: 26,
                    peso:
                        FontWeight.bold,
                    cor: corTexto,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // NOME DO REMÉDIO
                // ==================================================

                TextField(
                  controller:
                      _nomeController,

                  keyboardType:
                      TextInputType.text,

                  style:
                      AcolleDesign.texto(
                    tamanho: 18,
                    cor: corTexto,
                  ),

                  decoration:
                      AcolleDesign.inputDecoration(
                    label:
                        'Nome do remédio',

                    icone:
                        Icons.medication,

                    altoContraste:
                        contraste,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // HORÁRIO
                // ==================================================

                Semantics(
                  button: true,

                  label: _horario == null
                      ? 'Escolher horário do remédio'
                      : 'Horário escolhido: ${_formatarHorario(_horario!)}',

                  child: InkWell(
                    onTap:
                        _escolherHorario,

                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),

                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),

                      decoration:
                          BoxDecoration(
                        color: corCard,

                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),

                        border:
                            Border.all(
                          color: corBorda,
                          width:
                              contraste
                                  ? 2
                                  : 1.5,
                        ),
                      ),

                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color:
                                corDestaque,
                            size:
                                AcolleDesign.tamanhoTexto(
                              28,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Text(
                              _horario == null
                                  ? 'Escolher horário'
                                  : 'Horário: ${_formatarHorario(_horario!)}',

                              style:
                                  AcolleDesign.texto(
                                tamanho: 18,
                                cor: corTexto,
                                peso:
                                    FontWeight.w500,
                              ),
                            ),
                          ),

                          Icon(
                            Icons.chevron_right,
                            color:
                                corDestaque,
                            size:
                                AcolleDesign.tamanhoTexto(
                              28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // FREQUÊNCIA
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),

                  decoration:
                      BoxDecoration(
                    color: corCard,

                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),

                    border:
                        Border.all(
                      color: corBorda,
                      width:
                          contraste
                              ? 2
                              : 1.5,
                    ),
                  ),

                  child:
                      DropdownButtonHideUnderline(
                    child:
                        DropdownButton<String>(
                      value:
                          _frequencia,

                      isExpanded:
                          true,

                      icon: Icon(
                        Icons.repeat,
                        color:
                            corDestaque,
                        size:
                            AcolleDesign.tamanhoTexto(
                          28,
                        ),
                      ),

                      dropdownColor:
                          corCard,

                      style:
                          AcolleDesign.texto(
                        tamanho: 18,
                        cor: corTexto,
                      ),

                      items:
                          _opcoesFrequencia
                              .map(
                        (
                          frequencia,
                        ) {
                          return DropdownMenuItem<
                              String>(
                            value:
                                frequencia,

                            child:
                                Text(
                              frequencia,

                              style:
                                  AcolleDesign.texto(
                                tamanho:
                                    18,
                                cor:
                                    corTexto,
                              ),
                            ),
                          );
                        },
                      ).toList(),

                      onChanged:
                          (valor) {
                        if (valor ==
                            null) {
                          return;
                        }

                        setState(() {
                          _frequencia =
                              valor;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                // ==================================================
                // BOTÃO SALVAR
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,

                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _carregando
                            ? null
                            : _salvar,

                    icon: _carregando
                        ? SizedBox(
                            width: 24,
                            height: 24,

                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  3,

                              valueColor:
                                  AlwaysStoppedAnimation<
                                      Color>(
                                corTextoBotao,
                              ),
                            ),
                          )
                        : Icon(
                            Icons
                                .check_circle_outline,

                            size:
                                AcolleDesign.tamanhoTexto(
                              26,
                            ),
                          ),

                    label: Text(
                      _carregando
                          ? 'Salvando...'
                          : 'Salvar lembrete',

                      style:
                          AcolleDesign.texto(
                        tamanho: 19,
                        peso:
                            FontWeight.bold,
                        cor:
                            corTextoBotao,
                      ),
                    ),

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          corBotao,

                      foregroundColor:
                          corTextoBotao,

                      disabledBackgroundColor:
                          corBotao
                              .withOpacity(
                        0.6,
                      ),

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // INFORMAÇÃO
                // ==================================================

                Text(
                  'Você receberá uma notificação no horário escolhido.',

                  textAlign:
                      TextAlign.center,

                  style:
                      AcolleDesign.texto(
                    tamanho: 15,
                    cor:
                        corTextoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    acessibilidade.removeListener(
      _onAcessibilidadeChanged,
    );

    _nomeController.dispose();

    super.dispose();
  }
}