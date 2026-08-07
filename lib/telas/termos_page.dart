import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'onboarding_contato_emergencia_page.dart';
import 'permissao_page.dart';
import '../shared/acolle_design.dart';

/// Tela de Termos e Condições + Privacidade no onboarding do Acolle.
class TermosPage extends StatelessWidget {
  const TermosPage({super.key});

  static const String _conteudo = '''
ACOLLE — TERMOS DE USO E POLÍTICA DE PRIVACIDADE

Resumo para você:
• O Acolle existe para proteger você de golpes digitais.
• Tudo o que você analisar (mensagem, link ou chamada) fica salvo só para você ver depois.
• Nunca enviaremos sua senha, dados bancários ou códigos de segurança por e-mail, SMS ou telefone.

1. Quem somos
O Acolle é um aplicativo gratuito (projeto acadêmico) que ajuda pessoas a identificarem mensagens, links e chamadas suspeitas.

2. O que coletamos
• Seu nome, e-mail, telefone e data de nascimento (para criar sua conta).
• As mensagens e links que você colar para analisar.
• O número das chamadas recebidas (somente para comparar com a lista de números suspeitos).

3. Como usamos seus dados
• Para identificar padrões de golpe usando nossa inteligência artificial.
• Para avisar você em tempo real sobre chamadas suspeitas.
• Para gerar um histórico que só você vê.

4. Com quem compartilhamos
Não vendemos nem compartilhamos seus dados com terceiros. Suas análises ficam protegidas no seu espaço pessoal.

5. Segurança
Salvamos seus dados com criptografia no Firebase. Pedimos senha a cada novo acesso.

6. Seus direitos
Você pode apagar qualquer registro do seu histórico quando quiser. Para excluir a conta, fale com o suporte.

7. Mudanças
Este termo pode ser atualizado. Sempre que mudar algo importante, mostraremos este texto novamente.
''';

  void _prosseguir(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PermissaoPage(
          icone: Icons.phone_in_talk,
          titulo: 'Permitir acesso a chamadas',
          explicacao:
              'Para avisar se uma chamada recebida está na lista de números '
              'suspeitos, precisamos identificar o número de quem está ligando.',
          permissao: Permission.phone,
          rotuloPermitir: 'Permitir chamadas',
          proxima: (context) => PermissaoPage(
            icone: Icons.mic,
            titulo: 'Permitir microfone',
            explicacao:
                'Você pode falar a mensagem que quer analisar. Precisamos do '
                'microfone para transformar sua voz em texto.',
            permissao: Permission.microphone,
            rotuloPermitir: 'Permitir microfone',
            proxima: (context) => PermissaoPage(
              icone: Icons.notifications_active,
              titulo: 'Ativar notificações',
              explicacao:
                  'Vamos avisar você sobre chamadas suspeitas, lembretes de '
                  'remédios e dicas de segurança. Para isso, ative as notificações.',
              permissao: Permission.notification,
              rotuloPermitir: 'Ativar notificações',
              proxima: (context) => PermissaoPage(
                icone: Icons.contact_page_outlined,
                titulo: 'Permitir acesso aos contatos',
                explicacao:
                    'Com os seus contatos, podemos ajudar você a chamar alguém de '
                    'confiança quando sentir dúvida.',
                permissao: Permission.contacts,
                rotuloPermitir: 'Permitir contatos',
                proxima: (context) => const OnboardingContatoEmergenciaPage(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcolleDesign.fundo,
      appBar: AcolleDesign.appBarPadrao('Termos e Condições'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.privacy_tip_outlined,
                        size: 60, color: AcolleDesign.roxo),
                    const SizedBox(height: 12),
                    const Text(
                      'Leia com calma antes de continuar',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AcolleDesign.texto,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AcolleDesign.cartao(
                      filho: const SelectableText(
                        _conteudo,
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AcolleDesign.botaoPrimario(
                    texto: 'Entendi',
                    icone: Icons.check_circle_outline,
                    onPressed: () => _prosseguir(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
