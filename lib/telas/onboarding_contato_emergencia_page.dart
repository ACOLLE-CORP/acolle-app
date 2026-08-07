import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../shared/acolle_design.dart';
import 'tudo_pronto_page.dart';

/// Cadastro do primeiro contato de emergência durante o onboarding.
class OnboardingContatoEmergenciaPage extends StatefulWidget {
  const OnboardingContatoEmergenciaPage({super.key});

  @override
  State<OnboardingContatoEmergenciaPage> createState() =>
      _OnboardingContatoEmergenciaPageState();
}

class _OnboardingContatoEmergenciaPageState
    extends State<OnboardingContatoEmergenciaPage> {
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _salvarEContinuar({bool pular = false}) async {
    if (!pular) {
      if (_nomeController.text.trim().isEmpty) {
        AcolleDesign.snackbar(context, 'Digite o nome do contato.');
        return;
      }
      if (_telefoneController.text.trim().length < 15) {
        AcolleDesign.snackbar(context, 'Digite um telefone válido.');
        return;
      }
    }

    setState(() => _carregando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !pular &&
          _nomeController.text.trim().isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('contatos_emergencia')
            .add({
          'usuarioId': user.uid,
          'nome': _nomeController.text.trim(),
          'telefone': _telefoneController.text.trim(),
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TudoProntoPage()),
      );
    } catch (e) {
      if (mounted) {
        AcolleDesign.snackbar(
            context, 'Não foi possível salvar o contato. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _adicionarDeContatos() async {
    AcolleDesign.snackbar(
        context, 'Toque em "Permitir contatos" para usar seus contatos.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcolleDesign.fundo,
      appBar: AcolleDesign.appBarPadrao('Contato de Emergência'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.contact_emergency,
                  size: 70, color: AcolleDesign.roxo),
              const SizedBox(height: 12),
              const Text(
                'Quem você quer avisar em caso de dúvida?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AcolleDesign.texto,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cadicione agora um familiar, vizinho ou pessoa de confiança. '
                'Você poderá ligar e avisar esta pessoa com um toque.',
                textAlign: TextAlign.center,
                style: AcolleDesign.estiloCorpo,
              ),
              const SizedBox(height: 28),
              AcolleDesign.campoTexto(
                label: 'Nome completo',
                controller: _nomeController,
                icone: Icons.person_outline,
                teclado: TextInputType.name,
              ),
              const SizedBox(height: 16),
              AcolleDesign.campoTexto(
                label: 'Telefone',
                controller: _telefoneController,
                icone: Icons.phone_outlined,
                teclado: TextInputType.phone,
                mascaras: [_telefoneMask],
                suffix: IconButton(
                  tooltip: 'Buscar nos contatos',
                  icon: const Icon(Icons.contact_page_outlined,
                      color: AcolleDesign.roxo),
                  onPressed: _adicionarDeContatos,
                ),
              ),
              const SizedBox(height: 32),
              AcolleDesign.botaoPrimario(
                texto: 'Salvar e continuar',
                icone: Icons.check,
                carregando: _carregando,
                onPressed: () => _salvarEContinuar(),
              ),
              const SizedBox(height: 12),
              AcolleDesign.botaoSecundario(
                texto: 'Fazer depois',
                cor: Colors.grey.shade700,
                onPressed: () => _salvarEContinuar(pular: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
