import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'onboarding_contato_emergencia_page.dart';
import 'permissao_page.dart';
import 'configurar_protecao_chamadas_page.dart';
import '../shared/acolle_design.dart';

/// Tela de Termos e Condições + Privacidade no onboarding do Acolle.
class TermosPage extends StatelessWidget {
  const TermosPage({super.key, this.onboarding = true});

  final bool onboarding;

  static const String _conteudo = '''
ACOLLE — TERMOS DE USO E POLÍTICA DE PRIVACIDADE

1. Quem somos
O Acolle é um projeto acadêmico gratuito que ajuda a identificar possíveis golpes em mensagens, links e chamadas.

2. O que guardamos
• Nome, e-mail, telefone e data de nascimento para manter sua conta. Se você ativar notificações, podemos guardar o identificador usado para entregá-las.
• Nome ou descrição do remédio, horário e frequência para agendar lembretes. Essas informações podem aparecer na notificação.
• Nome e telefone dos contatos de emergência que você cadastrar para pedir ajuda.
• Mensagens, endereços de links e resultados das verificações no histórico da conta. Dependendo da origem, o histórico pode incluir o texto integral. Nas análises de captura de tela, o histórico usa uma descrição da captura.
• Números de chamadas recebidas, data e indicação de suspeita quando o monitoramento registra a chamada no histórico.

3. Como as verificações funcionam
Quando você pede uma análise, o conteúdo da mensagem ou o endereço do link é enviado ao serviço de análise hospedado na Cloudflare. A análise pode usar Cloudflare Workers AI ou Google Gemini, conforme o provedor disponível. Evite incluir senhas, códigos de segurança e dados bancários nas análises.

Com a proteção automática ativada, o Acolle pode ler notificações de aplicativos de mensagens e enviar trechos para análise. Nesse fluxo, o app tenta ocultar alguns dados, como CPF, cartão, código e e-mail. Para evitar alertas repetidos, o aparelho guarda um código gerado a partir da notificação e o horário. O histórico de verificações é armazenado separadamente.

Na proteção de chamadas, o Acolle usa a lista de suspeitos no aparelho e verifica se o número está salvo nos contatos, quando essa permissão está ativa. Quando é necessária uma consulta externa de reputação, o número é enviado a um serviço na Cloudflare que pode consultá-lo no OpenSpam.

4. Serviços usados
O Google Firebase fornece autenticação, banco de dados e notificações. Cloudflare, Google Gemini e OpenSpam podem receber os dados descritos acima para realizar as verificações. Esses serviços podem processar dados fora do Brasil.

5. Seus dados e a LGPD
Você pode consultar e corrigir dados do perfil no app e remover registros do histórico de verificações. Em Mais opções → Excluir conta, você pode confirmar com sua senha a exclusão da conta, do perfil, dos históricos, dos lembretes e dos contatos de emergência cadastrados. Esse fluxo apaga os registros da conta no Firebase. O processamento e a retenção dos serviços externos seguem suas próprias políticas.

A Lei Geral de Proteção de Dados Pessoais (Lei nº 13.709/2018) prevê direitos como acesso, correção e eliminação dos dados nas hipóteses legais.
''';

  void _prosseguir(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PermissaoPage(
          icone: Icons.phone_in_talk_rounded,
          titulo: 'Permitir acesso a chamadas',
          explicacao:
              'Para avisar se uma chamada recebida está na lista de números '
              'suspeitos, precisamos identificar o número de quem está ligando.',
          permissao: Permission.phone,
          rotuloPermitir: 'Permitir chamadas',
          proxima: (context) => ConfigurarProtecaoChamadasPage(
            proxima: (context) => PermissaoPage(
              icone: Icons.mic_rounded,
              titulo: 'Permitir microfone',
              explicacao:
                  'Você pode falar a mensagem que quer analisar. Precisamos do '
                  'microfone para transformar sua voz em texto.',
              permissao: Permission.microphone,
              rotuloPermitir: 'Permitir microfone',
              proxima: (context) => PermissaoPage(
                icone: Icons.notifications_active_rounded,
                titulo: 'Ativar notificações',
                explicacao:
                    'Vamos avisar você sobre chamadas suspeitas, lembretes de '
                    'remédios e dicas de segurança. Para isso, ative as notificações.',
                permissao: Permission.notification,
                rotuloPermitir: 'Ativar notificações',
                proxima: (context) => PermissaoPage(
                  icone: Icons.contact_page_rounded,
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
                    const Icon(
                      Icons.privacy_tip_rounded,
                      size: 60,
                      color: AcolleDesign.roxo,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      onboarding
                          ? 'Leia com calma antes de continuar'
                          : 'Como usamos seus dados',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AcolleDesign.textoBase,
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
            if (onboarding)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AcolleDesign.botaoPrimario(
                      texto: 'Entendi',
                      icone: Icons.check_circle_outline_rounded,
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
