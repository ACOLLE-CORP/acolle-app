import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);
const Color cinzaCardAcolle = Color(0xFFF3EEFA);

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
  final _telefonController = TextEditingController();
  final _cidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _nomeController.text = _user.displayName ?? '';
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final doc = await _firestore.collection('usuarios').doc(_user.uid).get();
      setState(() {
        _dados = doc.data() ?? {};
        _telefonController.text = _dados?['telefone'] ?? '';
        _cidadeController.text = _dados?['cidade'] ?? '';
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Erro perfil: $e',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 12),
          ),
        );
      }
    }
  }

  Future<void> _salvarAlteracoes() async {
    try {
      await _user.updateDisplayName(_nomeController.text.trim());
      
      await _firestore.collection('usuarios').doc(_user.uid).set({
        'nome': _nomeController.text.trim(),
        'email': _user.email,
        'telefone': _telefonController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'ultimaAtualizacao': DateTime.now(),
      }, SetOptions(merge: true));

      setState(() => _editando = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar alterações')),
        );
      }
    }
  }

  Future<void> _mudarSenha() async {
    showDialog<void>(
      context: context,
      builder: (context) => const _MudarSenhaDialog(),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefonController.dispose();
    _cidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meu Perfil'),
          backgroundColor: fundoAcolle,
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: fundoAcolle,
      appBar: AppBar(
        backgroundColor: fundoAcolle,
        title: const Text('Meu Perfil', style: TextStyle(color: roxoAcolle, fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFotoPerfilArea(),
            const SizedBox(height: 28),
            _buildSecaoInformacoes(),
            const SizedBox(height: 24),
            _buildSecaoSeguranca(),
            const SizedBox(height: 24),
            if (!_editando) _buildBotaoEditar() else _buildBotoesEdicao(),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoPerfilArea() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roxoAcolle,
              boxShadow: [BoxShadow(color: roxoAcolle.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)],
            ),
            child: const Center(
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _nomeController.text.isNotEmpty ? _nomeController.text : 'Usuário',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: roxoAcolle),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _user.email ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoInformacoes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cinzaCardAcolle, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informações Pessoais', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: roxoAcolle)),
          const SizedBox(height: 16),
          _buildCampoInfo('Nome Completo', _nomeController, Icons.person),
          const SizedBox(height: 14),
          _buildCampoInfo('Telefone', _telefonController, Icons.phone, readonly: !_editando),
          const SizedBox(height: 14),
          _buildCampoInfo('Cidade', _cidadeController, Icons.location_city, readonly: !_editando),
          const SizedBox(height: 14),
          _buildCampoInfo('Email', TextEditingController(text: _user.email ?? ''), Icons.email, readonly: true),
        ],
      ),
    );
  }

  Widget _buildCampoInfo(String label, TextEditingController controller, IconData icone, {bool readonly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readonly,
          enabled: _editando && !readonly,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icone, color: roxoAcolle),
            filled: true,
            fillColor: readonly ? Colors.grey.shade100 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoSeguranca() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cinzaCardAcolle, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Segurança', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: roxoAcolle)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock, color: roxoAcolle, size: 28),
            title: const Text('Alterar Senha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            subtitle: const Text('Atualize sua senha regularmente', style: TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            onTap: _mudarSenha,
          ),
          const Divider(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.verified_user, color: roxoAcolle, size: 28),
            title: const Text('Verificação em Duas Etapas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            subtitle: const Text('Proteja sua conta com segurança extra', style: TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recurso em desenvolvimento')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoEditar() {
    // FIX: SizedBox(height: 54) fixo trocado por ConstrainedBox(minHeight)
    // para o botão crescer com o texto em vez de estourar quando a fonte
    // do sistema é ampliada.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54, minWidth: double.infinity),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: roxoAcolle,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => setState(() => _editando = true),
        icon: const Icon(Icons.edit, size: 22),
        label: const Text('Editar Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBotoesEdicao() {
    return Row(
      children: [
        Expanded(
          // FIX: mesmo ajuste — ConstrainedBox(minHeight) no lugar de
          // SizedBox(height) fixo.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: roxoAcolle, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                _nomeController.text = _user.displayName ?? '';
                _carregarDados();
                setState(() => _editando = false);
              },
              child: const Text('Cancelar', style: TextStyle(fontSize: 16, color: roxoAcolle, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          // FIX: mesmo ajuste — ConstrainedBox(minHeight) no lugar de
          // SizedBox(height) fixo.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: roxoAcolle,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _salvarAlteracoes,
              icon: const Icon(Icons.check, size: 22),
              label: const Text('Salvar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}

class _MudarSenhaDialog extends StatefulWidget {
  const _MudarSenhaDialog();

  @override
  State<_MudarSenhaDialog> createState() => _MudarSenhaDialogState();
}

class _MudarSenhaDialogState extends State<_MudarSenhaDialog> {
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _carregando = false;
  bool _mostrarSenhasAtuais = false;
  bool _mostrarNovasSenhas = false;

  Future<void> _mudarSenha() async {
    if (_novaSenhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não conferem')),
      );
      return;
    }

    if (_novaSenhaController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A senha deve ter no mínimo 6 caracteres')),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _senhaAtualController.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_novaSenhaController.text);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha alterada com sucesso!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String mensagem = 'Erro ao alterar senha';
        if (e.code == 'wrong-password') {
          mensagem = 'Senha atual incorreta';
        } else if (e.code == 'weak-password') {
          mensagem = 'A nova senha é muito fraca';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem)),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar Senha'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _senhaAtualController,
              obscureText: !_mostrarSenhasAtuais,
              decoration: InputDecoration(
                labelText: 'Senha Atual',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(_mostrarSenhasAtuais ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _mostrarSenhasAtuais = !_mostrarSenhasAtuais),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _novaSenhaController,
              obscureText: !_mostrarNovasSenhas,
              decoration: InputDecoration(
                labelText: 'Nova Senha',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(_mostrarNovasSenhas ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _mostrarNovasSenhas = !_mostrarNovasSenhas),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmarSenhaController,
              obscureText: !_mostrarNovasSenhas,
              decoration: InputDecoration(
                labelText: 'Confirmar Nova Senha',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(_mostrarNovasSenhas ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _mostrarNovasSenhas = !_mostrarNovasSenhas),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _carregando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _carregando ? null : _mudarSenha,
          child: _carregando
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
              : const Text('Alterar'),
        ),
      ],
    );
  }
}