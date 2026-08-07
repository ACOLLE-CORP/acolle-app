import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Design system central do Acolle.
/// Todas as telas novas devem reaproveitar estas cores e componentes,
/// em vez de redeclarar constantes soltas.
class AcolleDesign {
  AcolleDesign._();

  // ---------- Cores ----------
  static const Color roxo = Color(0xFF773FD1);
  static const Color fundo = Color(0xFFFAF7FC);
  static const Color laranja = Color(0xFFF47A07);
  static const Color vermelho = Color(0xFFD32F2F);
  static const Color verde = Color(0xFF2E7D32);
  static const Color card = Color(0xFFF3EEFA);
  static const Color texto = Color(0xFF25212B);
  static const Color borda = Color(0xFFD4CBDD);
  static const Color cinzaClaro = Color(0xFFF0F0F0);

  // ---------- Texto ----------

  /// Título padrão de AppBar (a	scende no roxo Acolle).
  static const TextStyle estiloTituloAppBar = TextStyle(
    color: roxo,
    fontWeight: FontWeight.bold,
    fontSize: 24,
  );

  static const TextStyle estiloSecao = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: texto,
  );

  static const TextStyle estiloCorpo = TextStyle(
    fontSize: 18,
    color: Colors.black87,
    height: 1.4,
  );

  static const TextStyle estiloBotao = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // ---------- Componentes ----------

  /// AppBar padrão do app Acolle.
  static AppBar appBarPadrao(
    String titulo, {
    List<Widget>? actions,
    Widget? leading,
    bool center = true,
  }) {
    return AppBar(
      backgroundColor: fundo,
      elevation: 0,
      centerTitle: center,
      title: Text(titulo, style: estiloTituloAppBar),
      iconTheme: const IconThemeData(color: roxo),
      actions: actions,
      leading: leading,
    );
  }

  /// Botão primário (roxo, grande, com loading opcional).
  static Widget botaoPrimario({
    required String texto,
    required VoidCallback? onPressed,
    bool carregando = false,
    IconData? icone,
    double altura = 60,
    Color cor = roxo,
  }) {
    // FIX: ConstrainedBox(minHeight) no lugar de SizedBox(height) fixo,
    // para o botão crescer com o texto em vez de estourar quando a fonte
    // do sistema é ampliada.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: altura, minWidth: double.infinity),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        onPressed: carregando ? null : onPressed,
        icon: carregando
            ? const SizedBox.shrink()
            : (icone != null ? Icon(icone, size: 24) : const SizedBox.shrink()),
        label: carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(texto, style: estiloBotao, textAlign: TextAlign.center),
      ),
    );
  }

  /// Botão secundário (Outline roxo).
  static Widget botaoSecundario({
    required String texto,
    required VoidCallback onPressed,
    Color cor = roxo,
  }) {
    // FIX: mesmo ajuste do botaoPrimario — minHeight em vez de height fixo.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56, minWidth: double.infinity),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: cor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          side: BorderSide(color: cor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: cor),
        ),
      ),
    );
  }

  /// Campo de texto padrão (label + ícone + máscara opcional).
  static Widget campoTexto({
    required String label,
    required TextEditingController controller,
    IconData? icone,
    TextInputType teclado = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    List<MaskTextInputFormatter>? mascaras,
    int maxLinhas = 1,
    String? dica,
    FocusNode? focusNode,
    TextInputAction acaoTeclado = TextInputAction.next,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      obscureText: obscure,
      inputFormatters: mascaras,
      maxLines: obscure ? 1 : maxLinhas,
      focusNode: focusNode,
      textInputAction: acaoTeclado,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        hintText: dica,
        prefixIcon: icone != null ? Icon(icone) : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borda, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: roxo, width: 2),
        ),
      ),
    );
  }

  /// Cartão branco arredondado usado em listas.
  static Widget cartao({
    required Widget filho,
    EdgeInsets padding = const EdgeInsets.all(18),
    Color cor = Colors.white,
    Color bordaCor = const Color(0xFFE8E0F0),
    double raio = 20,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(raio),
        border: Border.all(color: bordaCor, width: 1.2),
      ),
      child: filho,
    );
  }

  /// Estado vazio padrão (ícone + texto).
  static Widget estadoVazio({
    required IconData icone,
    required String texto,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// Scaffold base com fundo Acolle + SafeArea.
  static Widget scaffoldBase({
    required Widget body,
    PreferredSizeWidget? appBar,
    Widget? floatingActionButton,
  }) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: appBar,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }

  /// SnackBar utilitário usado por todas as telas.
  static void snackbar(BuildContext context, String mensagem,
      {Color? cor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Diálogo de erro simples.
  static Future<void> dialogoErro(BuildContext context, String titulo, String mensagem) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_outline, color: Colors.red.shade700, size: 40),
        title: Text(titulo),
        content: Text(mensagem, style: const TextStyle(fontSize: 17)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  /// Indicador circular de carregamento central.
  static Widget carregandoCentral([String? mensagem]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: roxo),
          if (mensagem != null) ...[
            const SizedBox(height: 16),
            Text(mensagem,
                style: const TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ],
      ),
    );
  }
}