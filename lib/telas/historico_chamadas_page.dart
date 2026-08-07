import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../shared/acolle_design.dart';

/// Tela de Histórico de Chamadas: lista chamadas recebidas com indicador ⚠️
/// para números da lista `numeros_suspeitos`. Lista cronológica (mais recente primeiro).
class HistoricoChamadasPage extends StatefulWidget {
  const HistoricoChamadasPage({super.key});

  @override
  State<HistoricoChamadasPage> createState() => _HistoricoChamadasPageState();
}

class _HistoricoChamadasPageState extends State<HistoricoChamadasPage> {
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
      appBar: AcolleDesign.appBarPadrao('Histórico de Chamadas'),
      body: StreamBuilder<int>(
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
              stream: FirebaseFirestore.instance
                  .collection('chamadas')
                  .where('usuarioId', isEqualTo: _uid)
                  .orderBy('data', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final msg = snapshot.error.toString();
                  final waiting = msg.contains('failed-precondition') ||
                      msg.contains('building') ||
                      msg.contains('currently building');
                  if (waiting) {
                    Future.delayed(const Duration(seconds: 4), () {
                      if (!mounted) return;
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
                                SizedBox(height: 16),
                                Text('Puxe para baixo para tentar de novo',
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
                          'ERRO ao carregar chamadas:\n${snapshot.error}',
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
                          child: Text('Carregando chamadas...',
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
                          icone: Icons.call_received,
                          texto:
                              'Nenhuma chamada registrada.\nAs chamadas suspeitas aparecerão automaticamente aqui.',
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data() as Map<String, dynamic>;
                    return _ItemChamada(
                      numero: d['numero'] as String? ?? 'Desconhecido',
                      suspeito: d['suspeito'] as bool? ?? false,
                      data: (d['data'] as Timestamp?)?.toDate(),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ItemChamada extends StatelessWidget {
  const _ItemChamada({
    required this.numero,
    required this.suspeito,
    required this.data,
  });

  final String numero;
  final bool suspeito;
  final DateTime? data;

  @override
  Widget build(BuildContext context) {
    final formatada = data != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(data!)
        : 'Data desconhecida';
    return AcolleDesign.cartao(
      padding: const EdgeInsets.all(16),
      filho: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (suspeito ? Colors.red : AcolleDesign.verde)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              suspeito ? Icons.warning_amber_rounded : Icons.phone_missed,
              color: suspeito ? Colors.red : AcolleDesign.verde,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (suspeito)
                      const Text('⚠️ ', style: TextStyle(fontSize: 18)),
                    // FIX: Text(numero) sem Expanded/Flexible dentro da Row
                    // interna podia estourar a largura em números longos +
                    // fonte ampliada. Flexible + ellipsis evita o overflow.
                    Flexible(
                      child: Text(
                        numero,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: suspeito ? Colors.red : AcolleDesign.texto,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  suspeito ? 'Chamada suspeita de golpe' : 'Chamada comum',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: suspeito ? Colors.red : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(formatada,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}