import 'package:flutter/material.dart';

/// Vocabulário visual do Acolle.
///
/// Mantém ícones arredondados, familiares e consistentes. As telas devem usar
/// estes nomes por intenção, evitando escolher símbolos diferentes para a
/// mesma ação.
abstract final class AcolleIcons {
  static const proteger = Icons.health_and_safety_rounded;
  static const rotina = Icons.event_note_rounded;
  static const pedirAjuda = Icons.volunteer_activism_rounded;
  static const aprender = Icons.auto_stories_rounded;

  static const mensagem = Icons.chat_bubble_rounded;
  static const link = Icons.link_rounded;
  static const chamada = Icons.phone_in_talk_rounded;
  static const chamadasRecebidas = Icons.phone_callback_rounded;
  static const historico = Icons.manage_search_rounded;

  static const perfil = Icons.person_rounded;
  static const acessibilidade = Icons.accessibility_new_rounded;
  static const sair = Icons.logout_rounded;
  static const mais = Icons.more_horiz_rounded;
  static const avancar = Icons.chevron_right_rounded;

  static const medicamento = Icons.medication_rounded;
  static const contatos = Icons.contacts_rounded;
  static const ligar = Icons.call_rounded;
  static const alertas = Icons.notifications_active_rounded;
  static const fechar = Icons.close_rounded;
}
