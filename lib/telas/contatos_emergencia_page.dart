// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/acolle_design.dart';
import '../services/emergencia_service.dart';

/// Tela de Contatos de Emergência: lista os contatos cadastrados no Firestore
/// e permite ligar / enviar SMS rapidamente.
class ContatosEmergenciaPage extends StatefulWidget {
  const ContatosEmergenciaPage({super.key});

  @override
  State<ContatosEmergenciaPage> createState() => _ContatosEmergenciaPageState();
}

class _ContatosEmergenciaPageState extends State<ContatosEmergenciaPage> {
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
      appBar: AcolleDesign.appBarPadrao('Contatos de Emergência'),
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
                  .collection('contatos_emergencia')
                  .where('usuarioId', isEqualTo: _uid)
                  .orderBy('criadoEm', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final msg = snapshot.error.toString();
                  final waiting =
                      msg.contains('failed-precondition') ||
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
                                Icon(
                                  Icons.hourglass_top,
                                  size: 72,
                                  color: Colors.orange,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Preparando índice do Firestore...\nAguarde alguns segundos.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 17),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Puxe para baixo para tentar de novo',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
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
                          'ERRO ao carregar contatos:\n${snapshot.error}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
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
                          child: Text(
                            'Carregando contatos...',
                            style: TextStyle(fontSize: 18),
                          ),
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
                          icone: Icons.contact_emergency_outlined,
                          texto:
                              'Você ainda não cadastrou nenhum contato de emergência.\nToque no botão + para adicionar.',
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
                    return _ItemContato(
                      id: docs[index].id,
                      nome: dados['nome'] as String? ?? '',
                      telefone: dados['telefone'] as String? ?? '',
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
            builder: (context) => const AdicionarContatoEmergenciaPage(),
          ),
        ),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          'Adicionar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AcolleDesign.roxo,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ItemContato extends StatelessWidget {
  const _ItemContato({
    required this.id,
    required this.nome,
    required this.telefone,
  });

  final String id;
  final String nome;
  final String telefone;

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
            child: const Icon(Icons.person, color: AcolleDesign.roxo),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  telefone,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
          // FIX: os 3 IconButton soltos direto na Row podiam espremer o
          // Expanded do nome/telefone em telas estreitas. Wrap permite que
          // eles quebrem linha em vez de forçar overflow/aperto.
          Wrap(
            children: [
              IconButton(
                tooltip: 'Ligar',
                icon: const Icon(Icons.phone, color: AcolleDesign.verde),
                onPressed: () async {
                  final ok = await EmergenciaService.ligarPara(telefone);
                  if (ok) AcolleDesign.snackbar(context, 'Discador aberto.');
                },
              ),
              IconButton(
                tooltip: 'Enviar pelo WhatsApp',
                icon: const Icon(Icons.message, color: AcolleDesign.roxo),
                onPressed: () async {
                  final ok = await EmergenciaService.abrirWhatsApp(
                    telefone,
                    'Oi $nome, preciso de ajuda. Mensagem do app Acolle.',
                  );
                  if (!context.mounted) return;
                  AcolleDesign.snackbar(
                    context,
                    ok
                        ? 'WhatsApp aberto.'
                        : 'Não foi possível abrir o WhatsApp.',
                  );
                },
              ),
              IconButton(
                tooltip: 'Remover',
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: () => _confirmarRemover(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmarRemover(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover contato'),
        content: Text('Deseja remover "$nome" dos contatos de emergência?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('contatos_emergencia')
                  .doc(id)
                  .delete();
              Navigator.pop(context);
              AcolleDesign.snackbar(context, 'Contato removido.');
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

/// Tela para adicionar um contato de emergência (nome + telefone).
class AdicionarContatoEmergenciaPage extends StatefulWidget {
  const AdicionarContatoEmergenciaPage({super.key});

  @override
  State<AdicionarContatoEmergenciaPage> createState() =>
      _AdicionarContatoEmergenciaPageState();
}

class _AdicionarContatoEmergenciaPageState
    extends State<AdicionarContatoEmergenciaPage> {
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  bool _carregando = false;

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.trim();

    if (nome.isEmpty) {
      AcolleDesign.snackbar(context, 'Digite o nome do contato.');
      return;
    }
    if (telefone.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
      AcolleDesign.snackbar(context, 'Digite um telefone válido.');
      return;
    }

    setState(() => _carregando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('contatos_emergencia').add({
        'usuarioId': user.uid,
        'nome': nome,
        'telefone': telefone,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      AcolleDesign.snackbar(
        context,
        'Contato adicionado!',
        cor: AcolleDesign.verde,
      );
    } catch (e) {
      if (mounted) {
        AcolleDesign.snackbar(context, 'Erro ao salvar: $e');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirContatos() async {
    final Uri uri = Uri.parse('content://contacts/people');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        AcolleDesign.snackbar(
          context,
          'Conceda permissão de contatos nas Configurações.',
        );
      }
    } catch (_) {
      AcolleDesign.snackbar(context, 'Não foi possível abrir os contatos.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcolleDesign.fundo,
      appBar: AcolleDesign.appBarPadrao('Adicionar contato'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.person_add_alt_1,
                size: 70,
                color: AcolleDesign.roxo,
              ),
              const SizedBox(height: 12),
              const Text(
                'Adicionar contato de emergência',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AcolleDesign.texto,
                ),
              ),
              const SizedBox(height: 24),
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
                suffix: IconButton(
                  icon: const Icon(
                    Icons.contact_page_outlined,
                    color: AcolleDesign.roxo,
                  ),
                  onPressed: _abrirContatos,
                ),
              ),
              const SizedBox(height: 28),
              AcolleDesign.botaoPrimario(
                texto: 'Salvar contato',
                icone: Icons.check,
                carregando: _carregando,
                onPressed: _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
