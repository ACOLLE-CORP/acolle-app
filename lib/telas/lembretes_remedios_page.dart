import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../shared/acolle_design.dart';
import 'adicionar_lembrete_page.dart';
import '../services/notificacao_service.dart';

/// Tela de Lembretes de Remédios: lista horários cadastrados, com toggle para
/// ativar/desativar cada um, e botão "+" para adicionar novo lembrete.
class LembretesRemediosPage extends StatefulWidget {
  const LembretesRemediosPage({super.key});

  @override
  State<LembretesRemediosPage> createState() => _LembretesRemediosPageState();
}

class _LembretesRemediosPageState extends State<LembretesRemediosPage> {
  late final String _uid = FirebaseAuth.instance.currentUser!.uid;
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
    return Scaffold(
      backgroundColor: AcolleDesign.fundo,
      appBar: AcolleDesign.appBarPadrao('Lembretes de Remédios'),
      body: StreamBuilder<int>(
        stream: _tick?.stream,
        initialData: 0,
        builder: (context, tickSnap) {
          final tick = tickSnap.data ?? 0;
          if (tick != _tickValue) {
            _tickValue = tick;
          }
          return RefreshIndicator(
            onRefresh: () async {
              _tick?.add(_tickValue + 1);
              await Future.delayed(const Duration(seconds: 2));
            },
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('remedios')
                  .where('usuarioId', isEqualTo: _uid)
                  .orderBy('ativo', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final msg = snapshot.error.toString();
                  final waitingIndex = msg.contains('failed-precondition') ||
                      msg.contains('building') ||
                      msg.contains('currently building');
                  if (waitingIndex) {
                    Future.delayed(const Duration(seconds: 4), () {
                      if (!mounted) return;
                      _tick?.add(_tickValue + 1);
                    });
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Icon(Icons.hourglass_top,
                                    size: 72, color: Colors.orange),
                                const SizedBox(height: 16),
                                const Text(
                                  'Preparando índice do Firestore...\nAguarde alguns segundos.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 17),
                                ),
                                const SizedBox(height: 16),
                                const Text('Puxe para baixo para tentar de novo',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14)),
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
                          'ERRO ao carregar lembretes:\n${snapshot.error}',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Carregando lembretes...',
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
                        child: AcolleDesign.estadoVazio(
                          icone: Icons.medication_outlined,
                          texto:
                              'Nenhum lembrete cadastrado.\nToque no botão + para adicionar um remédio.',
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final dados = docs[index].data() as Map<String, dynamic>;
                    return _ItemLembrete(
                      id: docs[index].id,
                      nome: dados['nome'] as String? ?? '',
                      horario: dados['horario'] as String? ?? '',
                      frequencia: dados['frequencia'] as String? ?? 'Diário',
                      ativo: dados['ativo'] as bool? ?? true,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const AdicionarLembretePage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AcolleDesign.roxo,
        foregroundColor: AcolleDesign.fundo,
      ),
    );
  }
}

class _ItemLembrete extends StatefulWidget {
  const _ItemLembrete({
    required this.id,
    required this.nome,
    required this.horario,
    required this.frequencia,
    required this.ativo,
  });

  final String id;
  final String nome;
  final String horario;
  final String frequencia;
  final bool ativo;

  @override
  State<_ItemLembrete> createState() => _ItemLembreteState();
}

class _ItemLembreteState extends State<_ItemLembrete> {
  late bool _ativo = widget.ativo;

  Future<void> _alternar(bool valor) async {
    setState(() => _ativo = valor);
    try {
      await FirebaseFirestore.instance
          .collection('remedios')
          .doc(widget.id)
          .update({'ativo': valor});

      if (valor) {
        await NotificacaoService.agendarLembrete(
          docId: widget.id,
          nome: widget.nome,
          horario: widget.horario,
          frequencia: widget.frequencia,
        );
      } else {
        await NotificacaoService.cancelarLembrete(widget.id);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _ativo = !valor);
        AcolleDesign.snackbar(context, 'Erro ao atualizar lembrete.');
      }
    }
  }

  Future<void> _remover() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover lembrete'),
        content: Text('Deseja remover o lembrete de "${widget.nome}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await NotificacaoService.cancelarLembrete(widget.id);
      await FirebaseFirestore.instance.collection('remedios').doc(widget.id).delete();
      if (mounted) AcolleDesign.snackbar(context, 'Lembrete removido.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AcolleDesign.cartao(
      filho: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AcolleDesign.card,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medication, color: AcolleDesign.roxo),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.nome,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${widget.horario} • ${widget.frequencia}',
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _ativo,
            activeTrackColor: AcolleDesign.verde,
            activeThumbColor: AcolleDesign.verde,
            onChanged: _alternar,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            onPressed: _remover,
          ),
        ],
      ),
    );
  }
}
