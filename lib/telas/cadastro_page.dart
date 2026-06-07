import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  bool carregando = false;

  Future<void> cadastrar() async {
    setState(() {
      carregando = true;
    });

    try {
      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .set({
        'nome': nomeController.text.trim(),
        'email': emailController.text.trim(),
        'telefone': telefoneController.text.trim(),
        'dataNascimento': nascimentoController.text.trim(),
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Erro ao cadastrar.';

      if (e.code == 'email-already-in-use') {
        mensagem = 'Esse e-mail já está cadastrado.';
      } else if (e.code == 'weak-password') {
        mensagem = 'A senha precisa ter pelo menos 6 caracteres.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'E-mail inválido.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } finally {
      setState(() {
        carregando = false;
      });
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
        title: const Text('Criar conta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.person_add_alt_1, size: 72, color: roxoAcolle),
            const SizedBox(height: 12),
            const Text(
              'Cadastro Acolle',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: roxoAcolle,
              ),
            ),
            const SizedBox(height: 30),

            campo('Nome completo', Icons.person_outline, nomeController),
            const SizedBox(height: 16),
            campo('E-mail', Icons.email_outlined, emailController),
            const SizedBox(height: 16),
            campo('Telefone', Icons.phone_outlined, telefoneController),
            const SizedBox(height: 16),
            campo('Data de nascimento', Icons.calendar_today_outlined,
                nascimentoController),
            const SizedBox(height: 16),
            campo('Senha', Icons.lock_outline, senhaController, senha: true),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 58,
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
                        'Cadastrar',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Já tenho conta',
                style: TextStyle(color: laranjaAcolle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget campo(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool senha = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: senha,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}