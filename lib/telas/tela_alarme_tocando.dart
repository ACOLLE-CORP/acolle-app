import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

/// Tela de tela-cheia exibida automaticamente quando um alarme de remédio
/// dispara. Cor, textos e tamanhos são livres pra customizar aqui.
class TelaAlarmeTocando extends StatelessWidget {
  const TelaAlarmeTocando({super.key, required this.alarm});

  final AlarmSettings alarm;

  Future<void> _pararAlarme(BuildContext context) async {
    await Alarm.stop(alarm.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // impede fechar na unha sem parar o alarme
      child: Scaffold(
        // Cor de fundo do alarme — troque aqui se quiser outra cor.
        backgroundColor: const Color(0xFF773FD1),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Icon(
                  Icons.medication_rounded,
                  size: 140,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hora do remédio!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  alarm.notificationSettings.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 72,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF773FD1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _pararAlarme(context),
                    child: const Text(
                      'JÁ TOMEI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
