import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../shared/acolle_design.dart';
import '../services/notificacao_service.dart';

/// Tela para adicionar um novo lembrete de remédio: nome, horário e frequência.
class AdicionarLembretePage extends StatefulWidget {
  const AdicionarLembretePage({super.key});

  @override
  State<AdicionarLembretePage> createState() => _AdicionarLembretePageState();
}

class _AdicionarLembretePageState extends State<AdicionarLembretePage> {
  final _nomeController = TextEditingController();
  TimeOfDay? _horario;
  String _frequencia = 'Diário';
  bool _carregando = false;

  static const List<String> _opcoesFrequencia = [
    'Diário',
    'A cada 8 horas',
    'A cada 12 horas',
    'Semanal',
    'Sob demanda',
  ];

  Future<void> _escolherHorario() async {
    final agora = TimeOfDay.now();
    final horario = await showTimePicker(
      context: context,
      initialTime: _horario ?? agora,
      helpText: 'Escolha o horário do remédio',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (horario != null) setState(() => _horario = horario);
  }

  String _formatarHorario(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      AcolleDesign.snackbar(context, 'Digite o nome do remédio.');
      return;
    }
    if (_horario == null) {
      AcolleDesign.snackbar(context, 'Escolha o horário do remédio.');
      return;
    }

    setState(() => _carregando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final horarioFormatado = _formatarHorario(_horario!);
      final doc = await FirebaseFirestore.instance.collection('remedios').add({
        'usuarioId': user.uid,
        'nome': nome,
        'horario': horarioFormatado,
        'frequencia': _frequencia,
        'ativo': true,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      // Agenda o(s) alarme(s) local(is) para este lembrete.
      await NotificacaoService.agendarLembrete(
        docId: doc.id,
        nome: nome,
        horario: horarioFormatado,
        frequencia: _frequencia,
      );

      if (!mounted) return;
      Navigator.pop(context);
      AcolleDesign.snackbar(context, 'Lembrete adicionado!', cor: AcolleDesign.verde);
    } catch (e) {
      if (mounted) {
        AcolleDesign.snackbar(context, 'Erro ao salvar lembrete: $e');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcolleDesign.fundo,
      appBar: AcolleDesign.appBarPadrao('Adicionar lembrete'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.medication_outlined,
                  size: 70, color: AcolleDesign.roxo),
              const SizedBox(height: 12),
              const Text(
                'Adicionar lembrete de remédio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 24),
              AcolleDesign.campoTexto(
                label: 'Nome do remédio',
                controller: _nomeController,
                icone: Icons.medication,
                teclado: TextInputType.text,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _escolherHorario,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AcolleDesign.borda, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: AcolleDesign.roxo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _horario == null
                              ? 'Escolher horário'
                              : 'Horário: ${_formatarHorario(_horario!)}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AcolleDesign.roxo),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AcolleDesign.borda, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _frequencia,
                    isExpanded: true,
                    icon: const Icon(Icons.repeat, color: AcolleDesign.roxo),
                    items: _opcoesFrequencia
                        .map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 18))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _frequencia = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AcolleDesign.botaoPrimario(
                texto: 'Salvar lembrete',
                icone: Icons.check_circle_outline,
                carregando: _carregando,
                onPressed: _salvar,
              ),
              const SizedBox(height: 12),
              const Text(
                'Você receberá uma notificação no horário escolhido.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}