import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);
const Color laranjaAcolle = Color(0xFFF47A07);

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final nascimentoController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  final telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final dataMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool carregando = false;
  bool mostrarSenha = false;
  bool mostrarConfirmarSenha = false;

  void mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> escolherData() async {
    final hoje = DateTime.now();

    final data = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: DateTime(1960),
      firstDate: DateTime(1900),
      lastDate: DateTime(hoje.year - 10, hoje.month, hoje.day),
      helpText: 'Escolha sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (data != null) {
      nascimentoController.text =
          '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    }
  }

  bool dataValida(String data) {
    if (data.length != 10) return false;

    final partes = data.split('/');
    if (partes.length != 3) return false;

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);

    if (dia == null || mes == null || ano == null) return false;

    try {
      final nascimento = DateTime(ano, mes, dia);
      final hoje = DateTime.now();

      final dataExiste = nascimento.day == dia &&
          nascimento.month == mes &&
          nascimento.year == ano;

      if (!dataExiste) return false;

      final idade = hoje.year -
          nascimento.year -
          ((hoje.month < nascimento.month ||
                  (hoje.month == nascimento.month && hoje.day < nascimento.day))
              ? 1
              : 0);

      return idade >= 10 && idade <= 120;
    } catch (_) {
      return false;
    }
  }

  bool senhaMinima(String senha) {
    return senha.length >= 6;
  }

  Future<void> cadastrar() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final telefone = telefoneController.text.trim();
    final nascimento = nascimentoController.text.trim();
    final senha = senhaController.text.trim();
    final confirmarSenha = confirmarSenhaController.text.trim();

    if (nome.isEmpty ||
        email.isEmpty ||
        telefone.isEmpty ||
        nascimento.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      mostrarMensagem('Preencha todos os campos com calma.');
      return;
    }

    if (telefone.length < 15) {
      mostrarMensagem('Digite um telefone válido.');
      return;
    }

    if (!dataValida(nascimento)) {
      mostrarMensagem('Digite uma data de nascimento válida.');
      return;
    }

    if (!senhaMinima(senha)) {
      mostrarMensagem('A senha precisa ter pelo menos 6 caracteres.');
      return;
    }

    if (senha != confirmarSenha) {
      mostrarMensagem('As senhas não são iguais.');
      return;
    }

    setState(() => carregando = true);

    try {
      final credencial =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .set({
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'dataNascimento': nascimento,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      mostrarMensagem('Conta criada com sucesso!');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Não foi possível criar a conta.';

      if (e.code == 'email-already-in-use') {
        mensagem = 'Este e-mail já está cadastrado.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'Digite um e-mail válido.';
      } else if (e.code == 'weak-password') {
        mensagem = 'Escolha uma senha um pouco mais forte.';
      }

      mostrarMensagem(mensagem);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoAcolle,
      appBar: AppBar(
        backgroundColor: fundoAcolle,
        elevation: 0,
        foregroundColor: roxoAcolle,
        title: const Text(
          'Criar conta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.person_add_alt_1, size: 64, color: roxoAcolle),
            const SizedBox(height: 10),
            const Text(
              'Vamos criar sua conta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: roxoAcolle,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Preencha seus dados com calma.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: Colors.black87),
            ),
            const SizedBox(height: 26),

            campoTexto(
              label: 'Nome completo',
              icon: Icons.person_outline,
              controller: nomeController,
              teclado: TextInputType.name,
            ),
            const SizedBox(height: 16),

            campoTexto(
              label: 'E-mail',
              icon: Icons.email_outlined,
              controller: emailController,
              teclado: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            campoTexto(
              label: 'Telefone',
              icon: Icons.phone_outlined,
              controller: telefoneController,
              teclado: TextInputType.phone,
              mascaras: [telefoneMask],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: nascimentoController,
              keyboardType: TextInputType.number,
              inputFormatters: [dataMask],
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Data de nascimento',
                hintText: 'dd/mm/aaaa',
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month_outlined),
                  onPressed: escolherData,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 16),

            campoSenha(
              label: 'Senha',
              controller: senhaController,
              mostrar: mostrarSenha,
              aoClicar: () => setState(() => mostrarSenha = !mostrarSenha),
            ),
            const SizedBox(height: 16),

            campoSenha(
              label: 'Confirmar senha',
              controller: confirmarSenhaController,
              mostrar: mostrarConfirmarSenha,
              aoClicar: () => setState(
                () => mostrarConfirmarSenha = !mostrarConfirmarSenha,
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 62,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: roxoAcolle,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: carregando ? null : cadastrar,
                child: carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Criar conta',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Já tenho conta',
                style: TextStyle(
                  color: laranjaAcolle,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget campoTexto({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required TextInputType teclado,
    List<MaskTextInputFormatter>? mascaras,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      inputFormatters: mascaras,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget campoSenha({
    required String label,
    required TextEditingController controller,
    required bool mostrar,
    required VoidCallback aoClicar,
  }) {
    return TextField(
      controller: controller,
      obscureText: !mostrar,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(mostrar ? Icons.visibility_off : Icons.visibility),
          onPressed: aoClicar,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}