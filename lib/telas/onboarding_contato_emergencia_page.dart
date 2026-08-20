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
    filter: {
      '#': RegExp(r'[0-9]'),
    },
  );

  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // SALVAR E CONTINUAR
  // ============================================================

  Future<void> _salvarEContinuar({
    bool pular = false,
  }) async {
    if (!pular) {
      if (_nomeController.text.trim().isEmpty) {
        AcolleDesign.snackbar(
          context,
          'Digite o nome do contato.',
        );
        return;
      }

      if (_telefoneController.text.trim().length < 15) {
        AcolleDesign.snackbar(
          context,
          'Digite um telefone válido.',
        );
        return;
      }
    }

    setState(() {
      _carregando = true;
    });

    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user != null &&
          !pular &&
          _nomeController.text.trim().isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('contatos_emergencia')
            .add({
          'usuarioId': user.uid,
          'nome': _nomeController.text.trim(),
          'telefone':
              _telefoneController.text.trim(),
          'criadoEm':
              FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const TudoProntoPage(),
        ),
      );
    } catch (e) {
      if (mounted) {
        AcolleDesign.snackbar(
          context,
          'Não foi possível salvar o contato. '
          'Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ============================================================
  // CONTATOS
  // ============================================================

  Future<void> _adicionarDeContatos() async {
    AcolleDesign.snackbar(
      context,
      'Toque em "Permitir contatos" para usar '
      'seus contatos.',
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final contraste =
        AcolleDesign.altoContraste;

    final corTexto =
        AcolleDesign.corTexto(
      contraste,
    );

    final corSecundaria =
        AcolleDesign.corTextoSecundario(
      contraste,
    );

    final corDestaque =
        AcolleDesign.corIcone(
      contraste,
    );

    return Scaffold(
      backgroundColor:
          AcolleDesign.corFundo(contraste),

      appBar: AcolleDesign.appBarPadrao(
        'Contato de Emergência',
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              // ========================================================
              // ÍCONE
              // ========================================================

              Icon(
                Icons.contact_emergency,
                size: AcolleDesign.tamanhoTexto(70),
                color: corDestaque,
              ),

              const SizedBox(height: 12),

              // ========================================================
              // TÍTULO
              // ========================================================

              Text(
                'Quem você quer avisar em caso '
                'de dúvida?',

                textAlign: TextAlign.center,

                style: AcolleDesign.texto(
                  tamanho: 28,
                  cor: corTexto,
                  peso: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // ========================================================
              // DESCRIÇÃO
              // ========================================================

              Text(
                'Adicione agora um familiar, vizinho '
                'ou pessoa de confiança. Você poderá '
                'ligar e avisar esta pessoa com um toque.',

                textAlign: TextAlign.center,

                style: AcolleDesign.texto(
                  tamanho: 17,
                  cor: corSecundaria,
                  altura: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // ========================================================
              // NOME
              // ========================================================

              AcolleDesign.campoTexto(
                label: 'Nome completo',
                controller: _nomeController,
                icone: Icons.person_outline,
                teclado: TextInputType.name,
              ),

              const SizedBox(height: 16),

              // ========================================================
              // TELEFONE
              // ========================================================

              TextField(
                controller: _telefoneController,

                keyboardType:
                    TextInputType.phone,

                inputFormatters: [
                  _telefoneMask,
                ],

                style: AcolleDesign.texto(
                  tamanho: 18,
                  cor: corTexto,
                ),

                decoration:
                    AcolleDesign.inputDecoration(
                  label: 'Telefone',
                  icone: Icons.phone_outlined,
                  altoContraste: contraste,
                ).copyWith(
                  suffixIcon: IconButton(
                    tooltip:
                        'Buscar nos contatos',

                    icon: Icon(
                      Icons.contact_page_outlined,
                      color: corDestaque,
                      size: 27,
                    ),

                    onPressed:
                        _adicionarDeContatos,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ========================================================
              // SALVAR
              // ========================================================

              AcolleDesign.botaoPrimario(
                texto: 'Salvar e continuar',
                icone: Icons.check,
                carregando: _carregando,
                onPressed: () =>
                    _salvarEContinuar(),
              ),

              const SizedBox(height: 12),

              // ========================================================
              // FAZER DEPOIS
              // ========================================================

              SizedBox(
                height: 58,
                width: double.infinity,

                child: OutlinedButton(
                  onPressed: _carregando
                      ? null
                      : () =>
                          _salvarEContinuar(
                            pular: true,
                          ),

                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        contraste
                            ? Colors.white
                            : Colors.grey.shade700,

                    side: BorderSide(
                      color:
                          AcolleDesign.corBorda(
                        contraste,
                      ),

                      width: contraste
                          ? 2
                          : 1.5,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),

                  child: Text(
                    'Fazer depois',

                    style:
                        AcolleDesign.texto(
                      tamanho: 17,
                      peso: FontWeight.bold,
                      cor: contraste
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ========================================================
              // INFORMAÇÃO
              // ========================================================

              Text(
                'Você poderá cadastrar ou alterar '
                'seus contatos de emergência depois.',

                textAlign: TextAlign.center,

                style: AcolleDesign.texto(
                  tamanho: 14,
                  cor: corSecundaria,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}