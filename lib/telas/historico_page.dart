import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);
const Color cinzaCardAcolle = Color(0xFFF3EEFA);

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _filtro = 'todos';
  StreamController<int>? _tick;
  int _tickValue = 0;

  @override
  void initState() {
    super.initState();
    _tick = StreamController<int>.broadcast();
  }

  @override
  void dispose() {
    _tick?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: fundoAcolle,
      appBar: AppBar(
        backgroundColor: fundoAcolle,
        elevation: 0,
        title: const Text('Histórico', style: TextStyle(color: roxoAcolle, fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: roxoAcolle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFiltroChip('Todos', 'todos'),
                  const SizedBox(width: 8),
                  _buildFiltroChip('Mensagens', 'mensagem'),
                  const SizedBox(width: 8),
                  _buildFiltroChip('Links', 'link'),
                  const SizedBox(width: 8),
                  _buildFiltroChip('Chamadas', 'chamada'),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<int>(
              stream: _tick?.stream,
              initialData: 0,
              builder: (context, tickSnap) {
                final tick = tickSnap.data ?? 0;
                if (tick != _tickValue) _tickValue = tick;
                return RefreshIndicator(
                  onRefresh: () async {
                    _tick?.add(_tickValue + 1);
                    await Future.delayed(const Duration(seconds: 2));
                  },
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _construirStream(userId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        final msg = snapshot.error.toString();
                        final waiting = msg.contains('failed-precondition') ||
                            msg.contains('building') ||
                            msg.contains('currently building');
                        if (waiting) {
                          Future.delayed(const Duration(seconds: 4), () {
                            if (!(context.mounted)) return;
                            _tick?.add(_tickValue + 1);
                          });
                          return ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      Icon(Icons.hourglass_top,
                                          size: 72, color: Colors.orange),
                                      SizedBox(height: 16),
                                      Text(
                                        'Preparando índice do Firestore...\nAguarde alguns segundos.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 17),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return ListView(
                          children: [
                            const SizedBox(height: 80),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: SelectableText(
                                'ERRO ao carregar histórico:\n${snapshot.error}',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        );
                      }
                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('Carregando histórico...',
                                    style: TextStyle(fontSize: 18)),
                              ),
                            ),
                          ],
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return ListView(
                          children: [
                            const SizedBox(height: 100),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history,
                                      size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhum histórico encontrado',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final dados =
                              doc.data() as Map<String, dynamic>;
                          return _buildItemHistorico(dados, doc.id);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _construirStream(String userId) {
    var query = _firestore
        .collection('verificacoes')
        .where('usuarioId', isEqualTo: userId)
        .orderBy('data', descending: true);

    if (_filtro != 'todos') {
      query = query.where('tipo', isEqualTo: _filtro);
    }

    return query.limit(50).snapshots();
  }

  Widget _buildFiltroChip(String label, String valor) {
    final ativo = _filtro == valor;
    return FilterChip(
      label: Text(label),
      selected: ativo,
      onSelected: (selecionado) {
        setState(() => _filtro = valor);
      },
      backgroundColor: Colors.white,
      selectedColor: roxoAcolle,
      labelStyle: TextStyle(
        color: ativo ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: ativo ? roxoAcolle : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildItemHistorico(Map<String, dynamic> dados, String docId) {
    final tipo = dados['tipo'] as String? ?? 'desconhecido';
    final conteudo = dados['conteudo'] as String? ?? '';
    final risco = dados['risco'] as String? ?? 'desconhecido';
    final percentual = dados['percentual'] as int? ?? 0;
    final data = (dados['data'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formatada = DateFormat('dd/MM/yyyy HH:mm').format(data);

    IconData icone = Icons.info;
    Color cor = Colors.grey;

    if (tipo == 'mensagem') {
      icone = Icons.message_outlined;
    } else if (tipo == 'link') {
      icone = Icons.link;
    } else if (tipo == 'chamada') {
      icone = Icons.phone_missed;
    }

    if (risco == 'alto' || risco == 'malicioso') {
      cor = Colors.red;
    } else if (risco == 'médio' || risco == 'suspeito') {
      cor = Colors.orange;
    } else if (risco == 'baixo' || risco == 'confiável') {
      cor = Colors.green;
    }

    return GestureDetector(
      onLongPress: () => _mostrarMenuOpcoes(docId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Icon(icone, color: cor, size: 26)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _obterTituloTipo(tipo),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatada,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percentual%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cor),
                  ),
                ),
              ],
            ),
            if (conteudo.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                conteudo.length > 100 ? '${conteudo.substring(0, 100)}...' : conteudo,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(_iconePorRisco(risco), size: 16, color: cor),
                const SizedBox(width: 6),
                // FIX: Text do risco sem Expanded/Flexible podia estourar a
                // largura do card com fonte do sistema bem ampliada.
                Flexible(
                  child: Text(
                    _obterTextoRisco(risco),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarMenuOpcoes(String docId) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: roxoAcolle),
              title: const Text('Ver detalhes'),
              onTap: () {
                Navigator.pop(context);
                _mostrarDetalhes(docId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Deletar do histórico'),
              onTap: () {
                Navigator.pop(context);
                _deletarItemHistorico(docId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalhes(String docId) {
    _firestore.collection('verificacoes').doc(docId).get().then((doc) {
      if (!mounted) return;
      final dados = doc.data();
      if (dados == null) return;

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Detalhes da Verificação'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetalheLinha('Tipo:', _obterTituloTipo(dados['tipo'] as String? ?? '')),
                const SizedBox(height: 12),
                _buildDetalheLinha('Risco:', dados['risco'] as String? ?? 'Desconhecido'),
                const SizedBox(height: 12),
                _buildDetalheLinha('Percentual:', '${dados['percentual'] as int? ?? 0}%'),
                if (dados['conteudo'] != null && (dados['conteudo'] as String).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Conteúdo:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SelectableText(dados['conteudo'] as String),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDetalheLinha(String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(child: Text(valor, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  void _deletarItem(String docId) {
    _firestore.collection('verificacoes').doc(docId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removido do histórico')),
      );
    }
  }

  void _deletarItemHistorico(String docId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar item'),
        content: const Text('Deseja remover este item do histórico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.pop(context);
              _deletarItem(docId);
            },
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }

  String _obterTituloTipo(String tipo) {
    switch (tipo) {
      case 'mensagem':
        return 'Análise de Mensagem';
      case 'link':
        return 'Verificação de Link';
      case 'chamada':
        return 'Alerta de Chamada';
      default:
        return 'Verificação';
    }
  }

  String _obterTextoRisco(String risco) {
    switch (risco) {
      case 'alto':
      case 'malicioso':
        return 'Alto risco';
      case 'médio':
      case 'suspeito':
        return 'Risco médio';
      case 'baixo':
      case 'confiável':
        return 'Baixo risco';
      default:
        return 'Desconhecido';
    }
  }

  IconData _iconePorRisco(String risco) {
    switch (risco) {
      case 'alto':
      case 'malicioso':
        return Icons.dangerous;
      case 'médio':
      case 'suspeito':
        return Icons.warning_amber_rounded;
      case 'baixo':
      case 'confiável':
        return Icons.verified;
      default:
        return Icons.help_outline;
    }
  }
}