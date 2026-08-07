import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../shared/acolle_design.dart';
import '../services/acolle_api.dart';

/// Tela de Verificar Link: campo de URL, análise via API IA + Firestore.
class VerificarLinkPage extends StatefulWidget {
  const VerificarLinkPage({super.key});

  @override
  State<VerificarLinkPage> createState() => _VerificarLinkPageState();
}

class _VerificarLinkPageState extends State<VerificarLinkPage> {
  final _linkController = TextEditingController();
  bool _carregando = false;
  Map<String, dynamic>? _resultado;
  String? _erro;

  Future<void> _analisarLink() async {
    final link = _linkController.text.trim();

    if (link.isEmpty) {
      setState(() => _erro = 'Digite um link para analisar');
      return;
    }
    if (!_isLinkValido(link)) {
      setState(
          () => _erro = 'Link inválido. Digite um link que comece com http:// ou https://');
      return;
    }

    setState(() {
      _carregando = true;
      _resultado = null;
      _erro = null;
    });

    try {
      final resposta = await AcolleApi.analisarLink(link);
      setState(() => _resultado = resposta);

      // Salvar no Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('verificacoes').add({
          'usuarioId': user.uid,
          'tipo': 'link',
          'conteudo': link,
          'risco': resposta['classificacao'] ?? 'desconhecido',
          'percentual': resposta['risco'] ?? 0,
          'data': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      setState(() => _erro = 'Erro ao analisar o link. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  bool _isLinkValido(String link) {
    try {
      Uri.parse(link);
      return link.startsWith('http://') || link.startsWith('https://');
    } catch (_) {
      return false;
    }
  }

  Color _corPorRisco(String classificacao) {
    switch (classificacao) {
      case 'Alto':
        return Colors.red;
      case 'Médio':
        return Colors.orange;
      case 'Baixo':
        return AcolleDesign.verde;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcolleDesign.fundo,
      appBar: AcolleDesign.appBarPadrao('Verificar Link'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Verifique se um link é seguro antes de clicar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cole o link completo para análise.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            AcolleDesign.campoTexto(
              label: 'Cole o link aqui',
              controller: _linkController,
              icone: Icons.link,
              dica: 'https://exemplo.com',
            ),
            const SizedBox(height: 20),
            AcolleDesign.botaoPrimario(
              texto: 'Analisar',
              icone: Icons.search,
              carregando: _carregando,
              onPressed: _analisarLink,
            ),
            if (_erro != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _erro!,
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_resultado != null) ...[
              const SizedBox(height: 24),
              _buildResultado(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultado() {
    final classificacao = _resultado!['classificacao'] as String? ?? 'Desconhecido';
    final risco = _resultado!['risco'];
    final motivos = (_resultado!['motivos'] as List?) ?? [];
    final recomendacao = _resultado!['recomendacao'] as String?;
    final cor = _corPorRisco(classificacao);
    final IconData icone = classificacao == 'Alto'
        ? Icons.dangerous
        : classificacao == 'Médio'
            ? Icons.warning_amber_rounded
            : Icons.verified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cor, width: 2),
          ),
          child: Column(
            children: [
              Icon(icone, color: cor, size: 48),
              const SizedBox(height: 12),
              Text(
                'Risco $classificacao',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cor),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: $risco%',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('URL Analisada:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              SelectableText(
                _linkController.text.trim(),
                style: const TextStyle(fontSize: 14, color: Colors.black87, wordSpacing: 1),
              ),
            ],
          ),
        ),
        if (motivos.isNotEmpty) ...[
          const SizedBox(height: 16),
          AcolleDesign.cartao(
            filho: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AcolleDesign.roxo, size: 22),
                    const SizedBox(width: 10),
                    const Text('Motivos identificados:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AcolleDesign.roxo)),
                  ],
                ),
                const SizedBox(height: 8),
                ...motivos.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $m', style: const TextStyle(fontSize: 15, height: 1.5)),
                    )),
              ],
            ),
          ),
        ],
        if (recomendacao != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                const SizedBox(width: 10),
                Expanded(child: Text(recomendacao, style: TextStyle(fontSize: 14, height: 1.5, color: Colors.amber.shade900))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  }