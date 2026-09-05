# Teste dos alertas de mensagens

1. Instale a nova versão em um celular Android.
2. Abra **Proteger > Verificar mensagem** e ative a proteção automática.
3. Permita as notificações do Acolle e o acesso às notificações do sistema.
4. Deixe o Acolle e o WhatsApp em segundo plano.
5. Use outro número para enviar a mensagem abaixo:

> Oi mãe, troquei de número. Preciso que faça um Pix urgente para mim agora.

Resultado esperado: uma notificação do Acolle informando risco alto. O teste
também deve funcionar sem a API, usando a análise local de emergência.

Não faça o teste com a conversa aberta nem enviando uma mensagem para si mesmo,
pois o WhatsApp pode não gerar uma notificação nessas situações.

Se não houver alerta, confira:

- **Acesso às notificações > Acolle:** ativado;
- **Aplicativos > Acolle > Notificações:** permitidas;
- notificações e prévia de conteúdo do WhatsApp: habilitadas;
- economia de bateria do Acolle: sem restrições durante o teste.

Depois de atualizar ou reinstalar, pode ser necessário desligar e ligar novamente
o acesso às notificações para o Android reconectar o serviço.
