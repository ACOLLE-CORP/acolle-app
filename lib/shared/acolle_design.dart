import 'package:flutter/material.dart';

import '../services/acessibilidade_service.dart';

class AcolleDesign {
  // ============================================================
  // CORES PRINCIPAIS
  // ============================================================

  static const Color roxo = Color(0xFF6D59F4);

  static const Color roxoEscuro = Color(0xFF2A1B5D);

  static const Color roxoSuave = Color(0xFFEDE9FF);

  static const Color azul = Color(0xFF2962FF);

  static const Color laranja = Color(0xFFFF9129);

  static const Color vermelho = Color(0xFFE53935);

  static const Color verde = Color(0xFF2E7D32);

  static const Color fundo = Color(0xFFFBFAFF);

  static const Color card = Color(0xFFFFFFFF);

  // IMPORTANTE:
  // Não pode se chamar "texto", pois temos também
  // o método AcolleDesign.texto().
  static const Color textoBase = Color(0xFF251D3D);

  static const Color textoSecundario = Color(0xFF5E576D);

  static const Color borda = Color(0xFFE1DCEF);

  static ThemeData tema() {
    final esquema = ColorScheme.fromSeed(
      seedColor: roxo,
      brightness: Brightness.light,
      primary: roxo,
      secondary: laranja,
      surface: card,
      error: vermelho,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: fundo,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      iconTheme: const IconThemeData(color: roxoEscuro, size: 26),
      appBarTheme: const AppBarTheme(
        backgroundColor: fundo,
        foregroundColor: roxoEscuro,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borda, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: roxo, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(48, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          side: const BorderSide(color: roxo, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ============================================================
  // ACESSIBILIDADE
  // ============================================================

  static bool get altoContraste {
    return AcessibilidadeService.instance.altoContraste;
  }

  static double get escalaTexto {
    return AcessibilidadeService.instance.escalaTexto;
  }

  // ============================================================
  // CORES DINÂMICAS
  // ============================================================

  static Color corFundo(bool altoContraste) {
    return altoContraste 
    ? Colors.black 
    : fundo;
  }

  static Color corTexto(bool altoContraste) {
    return altoContraste 
    ? Colors.white
    : textoBase;
  }

  static Color corTextoSecundario(bool altoContraste) {
    return altoContraste
        ? Colors.white
        : textoSecundario;
  }

  static Color corIcone(bool altoContraste) {
    // O laranja continua sendo a cor de destaque,
    // inclusive no alto contraste.
    return altoContraste 
    ? laranja 
    : roxo;
  }

  static Color corCampo(bool altoContraste) {
    return altoContraste
        ? Colors.black
        : Colors.white;
  }

  static Color corCard(bool altoContraste) {
    return altoContraste
        ? Colors.black
        : card;
  }

  static Color corBorda(bool altoContraste) {
    return altoContraste
        ? Colors.white
        : borda;
  }

  // ============================================================
  // APPBAR
  // ============================================================

  static PreferredSizeWidget appBarPadrao(
    String titulo, {
    bool centralizado = false,
  }) {
    final contraste = altoContraste;

    return AppBar(
      backgroundColor: corFundo(contraste),

      elevation: 0,

      surfaceTintColor: Colors.transparent,

      centerTitle: centralizado,

      iconTheme: IconThemeData(
        color: corIcone(contraste),
      ),

      title: Text(
        titulo,
        style: TextStyle(
          color: corIcone(contraste),
          fontSize: tamanhoTexto(24),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  static InputDecoration inputDecoration({
    String? label,
    String? hint,
    IconData? icone,
    bool altoContraste = false,
  }) {
    final corTextoAtual =
        corTextoSecundario(altoContraste);

    final corDestaque =
        corIcone(altoContraste);

    return InputDecoration(
      labelText: label,

      hintText: hint,

      labelStyle: TextStyle(
        fontSize: tamanhoTexto(17),
        color: corTextoAtual,
      ),

      hintStyle: TextStyle(
        fontSize: tamanhoTexto(16),
        color: corTextoAtual,
      ),

      prefixIcon: icone != null
          ? Icon(
              icone,
              color: corDestaque,
            )
          : null,

      filled: true,

      fillColor: corCampo(
        altoContraste,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(18),

        borderSide: BorderSide(
          color: corBorda(
            altoContraste,
          ),
          width: 1.5,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(18),

        borderSide: BorderSide(
          color: corBorda(
            altoContraste,
          ),
          width: 1.5,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(18),

        borderSide: BorderSide(
          color: corDestaque,
          width: 2,
        ),
      ),

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
    );
  }

  // ============================================================
  // CAMPO DE TEXTO
  // ============================================================

  static Widget campoTexto({
    required String label,
    required TextEditingController controller,
    required IconData icone,
    TextInputType? teclado,
    TextInputAction? acaoTeclado,
    String? dica,
    bool obscureText = false,
    int maxLines = 1,
    Widget? suffix,
  }) {
    final contraste = altoContraste;

    return TextField(
      controller: controller,
      keyboardType: teclado,
      textInputAction: acaoTeclado,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      style: TextStyle(
        fontSize: tamanhoTexto(18),
        color: corTexto(contraste),
      ),
      decoration: inputDecoration(
        label: label,
        hint: dica,
        icone: icone,
        altoContraste: contraste,
      ).copyWith(
        suffixIcon: suffix,
      ),
    );
  }

  // ============================================================
  // TEXTO PADRÃO
  // ============================================================

  static TextStyle texto({
    required double tamanho,
    Color? cor,
    FontWeight? peso,
    double? altura,
  }) {
    return TextStyle(
      fontSize: tamanhoTexto(tamanho),

      color: cor ??
          corTexto(altoContraste),

      fontWeight: peso,

      height: altura,
    );
  }

  // ============================================================
  // TAMANHO DO TEXTO
  // ============================================================

  static double tamanhoTexto(
    double tamanho,
  ) {
    // A escala já é aplicada uma única vez pelo MediaQuery em main.dart.
    // Multiplicar aqui novamente fazia 140% virar quase 200% e quebrava cards.
    return tamanho;
  }

  // ============================================================
  // BOTÃO PRINCIPAL
  // ============================================================

  static Widget botaoPrimario({
    required String texto,
    required IconData icone,
    required VoidCallback? onPressed,
    bool carregando = false,
  }) {
    final contraste = altoContraste;

    final corBotao =
        corIcone(contraste);

    final corTextoBotao =
        contraste
            ? Colors.black
            : Colors.white;

    return SizedBox(
      height: 58,

      width: double.infinity,

      child: ElevatedButton.icon(
        onPressed: carregando
            ? null
            : onPressed,

        icon: carregando
            ? SizedBox(
                width: 24,
                height: 24,

                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,

                  color:
                      corTextoBotao,
                ),
              )
            : Icon(
                icone,
                color:
                    corTextoBotao,
              ),

        label: Text(
          carregando
              ? 'Carregando...'
              : texto,

          style: TextStyle(
            fontSize:
                tamanhoTexto(18),

            fontWeight:
                FontWeight.bold,

            color:
                corTextoBotao,
          ),
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              corBotao,

          foregroundColor:
              corTextoBotao,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTÃO SECUNDÁRIO
  // ============================================================
  static Widget botaoSecundario({
    required String texto,
    required VoidCallback? onPressed,
    Color? cor,
  }) {
    final contraste = altoContraste;

    final corBotao =
        cor ?? corIcone(contraste);

    return SizedBox(
      height: 50,

      width: double.infinity,

      child: OutlinedButton(
        onPressed: onPressed,

        child: Text(
          texto,

          style: TextStyle(
            fontSize:
                tamanhoTexto(17),
          ),
        ),
      ),
    );
  }
  // ============================================================
  // CARTÃO
  // ============================================================

  static Widget cartao({
    required Widget filho,

    EdgeInsetsGeometry padding =
        const EdgeInsets.all(16),

    EdgeInsetsGeometry? margem,

    Color? cor,

    Border? borda,
  }) {
    final contraste =
        altoContraste;

    return Container(
      margin: margem,

      padding: padding,

      decoration: BoxDecoration(
        color:
            cor ?? corCard(contraste),

        borderRadius:
            BorderRadius.circular(18),

        border:
            borda ??
            Border.all(
              color:
                  corBorda(contraste),

              width: 1.2,
            ),

        boxShadow: contraste
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0F2A1B5D),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
      ),

      child: filho,
    );
  }
// ============================================================
// ESTADO VAZIO
// ============================================================

static Widget estadoVazio({
  required IconData icone,
  required String mensagem,
}) {
  final contraste = altoContraste;

  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 28,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icone,
          size: tamanhoTexto(64),
          color: corIcone(contraste),
        ),

        const SizedBox(height: 16),

        Text(
          mensagem,
          textAlign: TextAlign.center,
          style: AcolleDesign.texto(
            tamanho: 17,
            cor: corTexto(contraste),
            peso: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
  // ============================================================
  // CARREGAMENTO CENTRAL
  // ============================================================

  static Widget carregandoCentral(String mensagem) {
    final contraste = altoContraste;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          color: corIcone(contraste),
          strokeWidth: 3,
        ),
        const SizedBox(height: 16),
        Text(
          mensagem,
          textAlign: TextAlign.center,
          style: texto(
            tamanho: 17,
            peso: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  // ============================================================
  // SNACKBAR
  // ============================================================

  static void snackbar(
    BuildContext context,
    String mensagem, {
    Color? cor,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          mensagem,

          style: TextStyle(
            fontSize:
                tamanhoTexto(16),
          ),
        ),

        backgroundColor:
            cor ?? laranja,

        behavior:
            SnackBarBehavior.floating,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // DIÁLOGOS
  // ============================================================

  static TextStyle get tituloDialogo {
    return texto(
      tamanho: 21,
      peso: FontWeight.bold,
    );
  }

  static TextStyle get textoDialogo {
    return texto(
      tamanho: 17,
      cor:
          corTextoSecundario(
        altoContraste,
      ),
    );
  }
}
