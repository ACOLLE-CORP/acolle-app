# Revisão dos alertas de mensagens

## O que foi corrigido

- Notificações MessagingStyle: usa apenas a mensagem mais recente, sem concatenar o histórico com o texto e o texto expandido.
- Ignora resumos de grupos e notificações contínuas de serviço. Ao reconectar o leitor, considera as notificações de mensagens ainda presentes que o Android publicou nos últimos dois minutos.
- A chave da notificação, o horário da mensagem, o título e o texto identificam atualizações repetidas do mesmo evento. O controle local guarda o hash e o horário por 24 horas. O histórico da conta em `verificacoes` pode guardar o conteúdo da mensagem junto com o resultado.
- Um intervalo de um minuto limita rajadas de alertas. Uma mudança de Médio para Alto pode interromper esse intervalo. Uma mensagem diferente pode gerar aviso após o intervalo.
- Um único cartão de notificação substitui o anterior e permanece disponível para leitura. A versão pública do aviso traz uma orientação genérica para a tela bloqueada.
- Quando a triagem local detecta risco alto, o Acolle pode avisar imediatamente com a orientação local. Nos demais casos, a análise automática envia a mensagem sanitizada, incluindo o contexto dos links, ao mesmo endpoint da análise manual. O tempo limite de leitura é de 30 segundos.
- Em falha de rede, o modo local não gera aviso para pontuações médias; avisos locais altos explicitam que a IA estava indisponível.
- Correspondência de domínio usa o hostname, evitando considerar um domínio citado no caminho como o endereço real.
- Avisos e resultado manual de mensagens não apresentam porcentagens como chance de golpe.
- O cartão abre uma tela rolável com orientação, texto maior, origem WhatsApp/SMS, Pedir ajuda e Entendi, fechar.
- Notificações não substituem um resultado ou texto já em uso nas telas de análise.

## Limites

O modelo remoto pode variar entre consultas. Sanitização, truncamento e conteúdo da notificação também podem diferir do texto colado manualmente. Esta revisão não garante scores idênticos e não altera os Workers publicados.

Não há leitura da tela do WhatsApp: se ele não publicar uma notificação (conversa aberta, silenciada, prévia oculta ou restrição do sistema), o listener pode não receber texto analisável. Imagens e áudios não são analisados por este fluxo. Apenas a mensagem mais recente do lote é analisada; não há análise contextual da conversa inteira.

Uma atualização da mesma mensagem, com a mesma chave e horário, é ignorada. Uma nova mensagem com o mesmo texto e um novo horário pode gerar aviso. Durante um minuto, novos avisos do mesmo nível são limitados para evitar interrupções em sequência.

## Teste no aparelho (pendente)

1. Execute flutter pub get, flutter analyze e flutter run no ambiente Flutter.
2. Autorize acesso a notificações e exibição das notificações do Acolle.
3. De outro celular, envie um texto fictício de falso familiar + número novo + pedido urgente de PIX. Deixe o WhatsApp do aparelho receptor em segundo plano.
4. Confira o aviso, sem porcentagem. Toque em Ver orientação. Confira texto, rolagem com fonte grande, Pedir ajuda e fechar.
5. Atualize a mesma notificação mantendo o texto e o horário da mensagem. Confira que o Acolle não repete o aviso e que o resultado manual continua disponível ao reabrir o app.
6. Após um minuto, envie outro texto de risco. Ele deve poder gerar novo aviso. Uma conversa cotidiana não deve gerar alerta alto.
7. Sem internet, envie a mensagem de alto risco do passo 3. Confira que o aviso traz a orientação local para confirmar o pedido por outro meio.
8. Teste com TalkBack e fonte grande. Compare análise manual e automática considerando que o conteúdo capturado pode ser diferente.

## Validação nesta entrega

O APK de depuração foi gerado no computador e sua assinatura foi verificada com o `apksigner`. A exibição física da notificação depende das configurações de tela bloqueada do aparelho.
