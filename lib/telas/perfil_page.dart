import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../shared/acolle_design.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late User _user;
  Map<String, dynamic>? _dados;

  bool _carregando = true;
  bool _editando = false;

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _user = _auth.currentUser!;

    _nomeController.text = _user.displayName ?? '';

    _carregarDados();
  }

  // ============================================================
  // CARREGAR DADOS
  // ============================================================

  Future<void> _carregarDados() async {
    try {
      final doc =
          await _firestore.collection('usuarios').doc(_user.uid).get();

      if (!mounted) return;

      setState(() {
        _dados = doc.data() ?? {};

        _telefoneController.text =
            _dados?['telefone'] as String? ?? '';

        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _carregando = false);

      AcolleDesign.snackbar(
        context,
        'Erro ao carregar o perfil.',
        cor: AcolleDesign.vermelho,
      );
    }
  }

  // ============================================================
  // SALVAR ALTERAÇÕES
  // ============================================================

  Future<void> _salvarAlteracoes() async {
    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.trim();

    if (nome.isEmpty) {
      AcolleDesign.snackbar(
        context,
        'Digite seu nome.',
      );
      return;
    }

    try {
      setState(() => _carregando = true);

      await _user.updateDisplayName(nome);

      await _firestore.collection('usuarios').doc(_user.uid).set(
        {
          'nome': nome,
          'email': _user.email,
          'telefone': telefone,
          'ultimaAtualizacao': DateTime.now(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _editando = false;
        _carregando = false;
      });

      AcolleDesign.snackbar(
        context,
        'Perfil atualizado com sucesso!',
        cor: AcolleDesign.verde,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _carregando = false);

      AcolleDesign.snackbar(
        context,
        'Erro ao salvar alterações.',
        cor: AcolleDesign.vermelho,
      );
    }
  }

  // ============================================================
  // CANCELAR EDIÇÃO
  // ============================================================

  Future<void> _cancelarEdicao() async {
    _nomeController.text = _user.displayName ?? '';

    await _carregarDados();

    if (!mounted) return;

    setState(() {
      _editando = false;
    });
  }

  // ============================================================
  // ALTERAR SENHA
  // ============================================================

  Future<void> _mudarSenha() async {
    showDialog<void>(
      context: context,
      builder: (context) => const _MudarSenhaDialog(),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final contraste = AcolleDesign.altoContraste;

    if (_carregando) {
      return Scaffold(
        backgroundColor: AcolleDesign.corFundo(contraste),
        appBar: AcolleDesign.appBarPadrao('Meu Perfil'),
        body: Center(
          child: CircularProgressIndicator(
            color: AcolleDesign.corIcone(contraste),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AcolleDesign.corFundo(contraste),

      appBar: AcolleDesign.appBarPadrao(
        'Meu Perfil',
        centralizado: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFotoPerfilArea(),

              const SizedBox(height: 28),

              _buildSecaoInformacoes(),

              const SizedBox(height: 24),

              if (!_editando)
                _buildBotaoEditar()
              else
                _buildBotoesEdicao(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FOTO / CABEÇALHO DO PERFIL
  // ============================================================

  Widget _buildFotoPerfilArea() {
    final contraste = AcolleDesign.altoContraste;

    return Text(
      'Aqui ficam suas informações de acordo com seu cadastro. '
      'Elas são importantes para utilizar funcionalidades do aplicativo.',
      style: AcolleDesign.texto(
        tamanho: 18,
        cor: AcolleDesign.corTextoSecundario(contraste),
        altura: 1.5,
      ),
    );
  }

  // ============================================================
  // INFORMAÇÕES PESSOAIS
  // ============================================================

  Widget _buildSecaoInformacoes() {
    final contraste = AcolleDesign.altoContraste;

    return AcolleDesign.cartao(
      padding: const EdgeInsets.all(20),
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações Pessoais',
            style: AcolleDesign.texto(
              tamanho: 20,
              cor: AcolleDesign.corIcone(contraste),
              peso: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _buildCampoInfo(
            label: 'Nome Completo',
            controller: _nomeController,
            icone: Icons.person_rounded,
            editavel: true,
          ),

          const SizedBox(height: 16),

          _buildCampoInfo(
            label: 'Telefone',
            controller: _telefoneController,
            icone: Icons.phone_rounded,
            editavel: true,
          ),

          const SizedBox(height: 16),

          _buildCampoInfo(
            label: 'Email',
            controller: TextEditingController(
              text: _user.email ?? '',
            ),
            icone: Icons.email_rounded,
            editavel: false,
          ),

          const SizedBox(height: 8),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.lock_rounded,
              color: AcolleDesign.corIcone(contraste),
              size: 28,
            ),
            title: Text(
              'Alterar senha',
              style: AcolleDesign.texto(
                tamanho: 18,
                peso: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AcolleDesign.corTextoSecundario(contraste),
            ),
            onTap: _mudarSenha,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CAMPO DE INFORMAÇÃO
  // ============================================================

  Widget _buildCampoInfo({
    required String label,
    required TextEditingController controller,
    required IconData icone,
    required bool editavel,
  }) {
    final contraste = AcolleDesign.altoContraste;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,

          readOnly: !editavel || !_editando,

          style: AcolleDesign.texto(
            tamanho: 16,
            cor: AcolleDesign.corTexto(contraste),
          ),

          decoration: AcolleDesign.inputDecoration(
            label: label,
            icone: icone,
            altoContraste: contraste,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTÃO EDITAR
  // ============================================================

  Widget _buildBotaoEditar() {
    return AcolleDesign.botaoPrimario(
      texto: 'Editar Perfil',
      icone: Icons.edit_rounded,
      onPressed: () {
        setState(() {
          _editando = true;
        });
      },
    );
  }

  // ============================================================
  // BOTÕES DE EDIÇÃO
  // ============================================================

  Widget _buildBotoesEdicao() {
    final contraste = AcolleDesign.altoContraste;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 58,
            child: OutlinedButton(
              onPressed: _carregando
                  ? null
                  : _cancelarEdicao,

              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AcolleDesign.corIcone(contraste),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              child: Text(
                'Cancelar',
                style: AcolleDesign.texto(
                  tamanho: 16,
                  cor: AcolleDesign.corIcone(contraste),
                  peso: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: AcolleDesign.botaoPrimario(
            texto: 'Salvar',
            icone: Icons.check_rounded,
            carregando: _carregando,
            onPressed: _salvarAlteracoes,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// DIÁLOGO — ALTERAR SENHA
// ================================================================

class _MudarSenhaDialog extends StatefulWidget {
  const _MudarSenhaDialog();

  @override
  State<_MudarSenhaDialog> createState() =>
      _MudarSenhaDialogState();
}

class _MudarSenhaDialogState
    extends State<_MudarSenhaDialog> {
  final _senhaAtualController =
      TextEditingController();

  final _novaSenhaController =
      TextEditingController();

  final _confirmarSenhaController =
      TextEditingController();

  bool _carregando = false;
  bool _mostrarSenhaAtual = false;
  bool _mostrarNovaSenha = false;

  // ============================================================
  // ALTERAR SENHA
  // ============================================================

  Future<void> _mudarSenha() async {
    final novaSenha = _novaSenhaController.text;
    final confirmarSenha =
        _confirmarSenhaController.text;

    if (novaSenha != confirmarSenha) {
      AcolleDesign.snackbar(
        context,
        'As senhas não conferem.',
      );
      return;
    }

    if (novaSenha.length < 6) {
      AcolleDesign.snackbar(
        context,
        'A senha deve ter no mínimo 6 caracteres.',
      );
      return;
    }

    if (_senhaAtualController.text.isEmpty) {
      AcolleDesign.snackbar(
        context,
        'Digite sua senha atual.',
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final user =
          FirebaseAuth.instance.currentUser!;

      final email = user.email;

      if (email == null) {
        throw Exception(
          'Usuário não possui email.',
        );
      }

      final credential =
          EmailAuthProvider.credential(
        email: email,
        password: _senhaAtualController.text,
      );

      await user.reauthenticateWithCredential(
        credential,
      );

      await user.updatePassword(
        novaSenha,
      );

      if (!mounted) return;

      Navigator.pop(context);

      AcolleDesign.snackbar(
        context,
        'Senha alterada com sucesso!',
        cor: AcolleDesign.verde,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String mensagem =
          'Erro ao alterar senha.';

      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        mensagem = 'Senha atual incorreta.';
      } else if (e.code == 'weak-password') {
        mensagem =
            'A nova senha é muito fraca.';
      } else if (e.code ==
          'requires-recent-login') {
        mensagem =
            'Faça login novamente para alterar sua senha.';
      }

      AcolleDesign.snackbar(
        context,
        mensagem,
        cor: AcolleDesign.vermelho,
      );
    } catch (_) {
      if (!mounted) return;

      AcolleDesign.snackbar(
        context,
        'Não foi possível alterar a senha.',
        cor: AcolleDesign.vermelho,
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final contraste =
        AcolleDesign.altoContraste;

    return AlertDialog(
      backgroundColor:
          AcolleDesign.corFundo(contraste),

      title: Text(
        'Alterar Senha',
        style: AcolleDesign.tituloDialogo,
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller:
                  _senhaAtualController,

              obscureText:
                  !_mostrarSenhaAtual,

              style: AcolleDesign.texto(
                tamanho: 16,
              ),

              decoration:
                  AcolleDesign.inputDecoration(
                label: 'Senha Atual',
                icone: Icons.lock_rounded,
                altoContraste:
                    contraste,
              ).copyWith(
                suffixIcon: IconButton(
                  tooltip: _mostrarSenhaAtual
                      ? 'Ocultar senha'
                      : 'Mostrar senha',
                  icon: Icon(
                    _mostrarSenhaAtual
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color:
                        AcolleDesign.corIcone(
                      contraste,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _mostrarSenhaAtual =
                          !_mostrarSenhaAtual;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  _novaSenhaController,

              obscureText:
                  !_mostrarNovaSenha,

              style: AcolleDesign.texto(
                tamanho: 16,
              ),

              decoration:
                  AcolleDesign.inputDecoration(
                label: 'Nova Senha',
                icone: Icons.lock_rounded,
                altoContraste:
                    contraste,
              ).copyWith(
                suffixIcon: IconButton(
                  tooltip: _mostrarNovaSenha
                      ? 'Ocultar senha'
                      : 'Mostrar senha',
                  icon: Icon(
                    _mostrarNovaSenha
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color:
                        AcolleDesign.corIcone(
                      contraste,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _mostrarNovaSenha =
                          !_mostrarNovaSenha;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  _confirmarSenhaController,

              obscureText:
                  !_mostrarNovaSenha,

              style: AcolleDesign.texto(
                tamanho: 16,
              ),

              decoration:
                  AcolleDesign.inputDecoration(
                label: 'Confirmar Nova Senha',
                icone: Icons.lock_rounded,
                altoContraste:
                    contraste,
              ).copyWith(
                suffixIcon: IconButton(
                  tooltip: _mostrarNovaSenha
                      ? 'Ocultar senha'
                      : 'Mostrar senha',
                  icon: Icon(
                    _mostrarNovaSenha
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color:
                        AcolleDesign.corIcone(
                      contraste,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _mostrarNovaSenha =
                          !_mostrarNovaSenha;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: _carregando
              ? null
              : () => Navigator.pop(context),

          child: Text(
            'Cancelar',
            style: AcolleDesign.texto(
              tamanho: 16,
              cor: AcolleDesign.corIcone(
                contraste,
              ),
              peso: FontWeight.bold,
            ),
          ),
        ),

        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor:
                AcolleDesign.corIcone(
              contraste,
            ),
            foregroundColor:
                contraste
                    ? Colors.black
                    : Colors.white,
          ),

          onPressed:
              _carregando ? null : _mudarSenha,

          child: _carregando
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: contraste
                        ? Colors.black
                        : Colors.white,
                  ),
                )
              : Text(
                  'Alterar',
                  style: AcolleDesign.texto(
                    tamanho: 16,
                    cor: contraste
                        ? Colors.black
                        : Colors.white,
                    peso: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}