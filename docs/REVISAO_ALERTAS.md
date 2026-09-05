# Revisão dos alertas de mensagens

## O que foi corrigido

- Notificações MessagingStyle: usa apenas a mensagem mais recente, sem concatenar o histórico com o texto e o texto expandido.
- Ignora resumos de grupos, notificações contínuas de serviço e mensagens com timestamp mais antigo que dois minutos.
- A mesma combinação de aplicativo, remetente e texto é processada uma vez em 24 horas. Só o hash e o horário são guardados nesse controle, inclusive após reiniciar o serviço.
- Um intervalo de um minuto limita rajadas de alertas. Uma mudança de Médio para Alto pode interromper esse intervalo. Uma mensagem diferente pode gerar aviso após o intervalo.
- Um único cartão de notificação substitui o anterior e expira em dois minutos.
- A análise automática envia a mensagem completa sanitizada ao mesmo endpoint da análise manual. Não substitui mais o texto pelo link nem usa o score local antes da API. Timeout de leitura aumentado para 30 segundos.
- Em falha de rede, o modo local não gera aviso para pontuações médias; avisos locais altos explicitam que a IA estava indisponível.
- Correspondência de domínio usa o hostname, evitando considerar um domínio citado no caminho como o endereço real.
- Avisos e resultado manual de mensagens não apresentam porcentagens como chance de golpe.
- O cartão abre uma tela rolável com orientação, texto maior, origem WhatsApp/SMS, Pedir ajuda e Entendi, fechar.
- Notificações não substituem um resultado ou texto já em uso nas telas de análise.

## Limites

O modelo remoto pode variar entre consultas. Sanitização, truncamento e conteúdo da notificação também podem diferir do texto colado manualmente. Esta revisão não garante scores idênticos e não altera os Workers publicados.

Não há leitura da tela do WhatsApp: se ele não publicar uma notificação (conversa aberta, silenciada, prévia oculta ou restrição do sistema), o listener pode não receber texto analisável. Imagens e áudios não são analisados por este fluxo. Apenas a mensagem mais recente do lote é analisada; não há análise contextual da conversa inteira.

Repetir exatamente o mesmo teste com o mesmo remetente durante 24 horas não deve alertar outra vez. Use uma mensagem fictícia diferente para testar novamente. Durante um minuto, novos avisos do mesmo nível são limitados para evitar interrupções em sequência.

## Teste no aparelho (pendente)

1. Execute flutter pub get, flutter analyze e flutter run no ambiente Flutter.
2. Autorize acesso a notificações e exibição das notificações do Acolle.
3. De outro celular, envie um texto fictício de falso familiar + número novo + pedido urgente de PIX. Deixe o WhatsApp do aparelho receptor em segundo plano.
4. Confira o aviso, sem porcentagem. Toque em Ver orientação. Confira texto, rolagem com fonte grande, Pedir ajuda e fechar.
5. Atualize a notificação/reenvie o mesmo texto: não deve criar aviso repetido. Reabra o Acolle: o resultado manual em uso não deve mudar.
6. Após um minuto, envie outro texto de risco. Ele deve poder gerar novo aviso. Uma conversa cotidiana não deve gerar alerta alto.
7. Sem internet, confira que um aviso local alto informa indisponibilidade da IA. Falha de rede não comprova segurança.
8. Teste com TalkBack e fonte grande. Compare análise manual e automática considerando que o conteúdo capturado pode ser diferente.

## Validação nesta entrega

Revisão de código, git diff --check, XML e integridade do ZIP. Não foi executado build Flutter/Android nem teste em aparelho neste ambiente; a correção exige validação no dispositivo.

O ZIP original foi preservado. A pasta .git continua no pacote; não foi feito commit ou push.
