<div align="center">

<!-- LOGO -->
<img src="./assets/images/mascote.png" alt="Logo Acolle" width="140"/>

# 💜 Acolle

### Segurança digital acessível para pessoas idosas

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.50.1-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=white)](https://firebase.google.com)
[![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)](#-status-do-projeto)
[![Licença](https://img.shields.io/badge/licença-MIT-green)](#-licença)

</div>

---

## 📖 Sobre o projeto

**Acolle** é um aplicativo para Android desenvolvido em **Flutter**, criado como **Trabalho de Conclusão de Curso (TCC)** do curso Técnico em Desenvolvimento de Sistemas.

O aplicativo tem como propósito oferecer **auxílio digital para pessoas idosas**, com foco especial na **prevenção de golpes digitais** — um dos problemas que mais crescem no Brasil e no mundo com o avanço da tecnologia e da comunicação por aplicativos de mensagens, ligações e redes sociais.

Todo o desenvolvimento do Acolle segue princípios de **acessibilidade e simplicidade**, priorizando uma experiência de uso confortável para pessoas com pouca familiaridade com tecnologia.

---

## 🧩 Contextualização do problema

Pessoas idosas estão entre as principais vítimas de golpes digitais, seja por ligações telefônicas fraudulentas, mensagens de phishing, links maliciosos ou falsos contatos de familiares e instituições financeiras.

Grande parte desse público enfrenta dificuldades ao lidar com aplicativos convencionais, que costumam ser complexos, cheios de elementos visuais e pouco intuitivos — fatores que aumentam a vulnerabilidade digital e reduzem a autonomia do usuário idoso.

O Acolle nasce como resposta a esse cenário: um aplicativo pensado **desde o início** para esse público, e não adaptado posteriormente.

---

## 🎯 Objetivo do projeto

Tornar o ambiente digital mais seguro e acessível para pessoas idosas, oferecendo uma interface extremamente simples, intuitiva e humanizada, capaz de auxiliar na identificação e prevenção de golpes digitais no dia a dia.

---

## 👵 Público-alvo

O Acolle é desenvolvido especialmente para **pessoas com 70 anos ou mais**, considerando suas particularidades de uso, como:

- Baixa familiaridade com tecnologia;
- Dificuldade de leitura de textos pequenos;
- Necessidade de navegação simples e direta;
- Preferência por linguagem clara e objetiva;
- Sensibilidade a golpes por ligação, SMS e mensagens de aplicativos.

---

## ✨ Principais funcionalidades

- Cadastro, login, recuperação de senha e gerenciamento do perfil.
- Análise de mensagens e links com histórico de verificações.
- No Android, avisos sobre notificações de WhatsApp e SMS, identificação de chamadas e consulta de reputação de números.
- Proteção rápida com botão flutuante e leitura de texto na tela, mediante autorização do usuário.
- Agenda de medicamentos com alarmes locais e opção sob demanda, sem alarme.
- Contatos de emergência por preenchimento manual ou escolha de um número na agenda do Android.
- Tutorial de 15 passos, dicas, ajuste do tamanho da letra e alto contraste.

---

## 🛠️ Tecnologias utilizadas

O projeto foi desenvolvido utilizando:

- **[Flutter](https://flutter.dev)** — framework multiplataforma para desenvolvimento mobile;
- **[Dart](https://dart.dev)** — linguagem de programação utilizada no desenvolvimento do app;
- Kotlin e APIs do Android para contatos, notificações, chamadas, captura de tela e sobreposição. ML Kit para reconhecimento de texto.
- Cloudflare Workers para análise e consulta de reputação. OpenSpam fornece dados de denúncias.
- **[Firebase](https://firebase.google.com)** — plataforma de backend, utilizada para autenticação e banco de dados de usuários.

---

## 📁 Estrutura de pastas

```
acolle/
├── android/            # Configurações e código nativo Android
├── assets/
│   └── images/         # Imagens e mascote do aplicativo
├── lib/
│   ├── main.dart        # Ponto de entrada do aplicativo
│   ├── telas/            # Telas (páginas) do aplicativo
│   ├── services/          # Serviços de integração
│   └── shared/             # Componentes e estilos reutilizáveis
├── test/               # Testes automatizados
├── pubspec.yaml        # Dependências e configurações do projeto Flutter
└── README.md           # Este arquivo
```

---

## ⚙️ Como instalar

### Pré-requisitos

Antes de começar, você vai precisar ter instalado em sua máquina:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (incluso no Flutter SDK)
- Um editor de código, como [VS Code](https://code.visualstudio.com/) ou [Android Studio](https://developer.android.com/studio)
- Um aparelho Android para testar os recursos nativos, ou um emulador Android configurado

### Passo a passo

```bash
# 1. Clone este repositório
git clone https://github.com/ACOLLE-CORP/acolle-app.git

# 2. Acesse a pasta do projeto
cd acolle-app

# 3. Instale as dependências
flutter pub get
```

> ℹ️ O projeto utiliza Firebase como backend. Para rodar localmente com suas próprias credenciais, será necessário configurar um projeto no [Firebase Console](https://console.firebase.google.com/) e adicionar os arquivos de configuração correspondentes (`google-services.json` para Android, por exemplo).

---

## ▶️ Como executar o projeto

```bash
# Verifique se há dispositivos/emuladores disponíveis
flutter devices

# Execute o aplicativo
flutter run
```

Para testar no Android com a configuração Firebase deste projeto, use
`flutter build apk --debug`. A variante release usa a chave de distribuição
quando existe um arquivo local `android/key.properties` com os campos abaixo.
Sem esse arquivo, o Android gera uma release sem assinatura.

```properties
storeFile=caminho/para/acolle-upload.jks
storePassword=SENHA_DA_LOJA
keyAlias=acolle
keyPassword=SENHA_DA_CHAVE
```

O caminho relativo da chave parte de `android/`. Para gerar o pacote de
distribuição assinado, execute `flutter build appbundle --release`.

O Firebase fornecido está registrado como `com.example.acolle1`. Para publicar
com um identificador definitivo, registre o app Android correspondente no mesmo
projeto Firebase, baixe o `google-services.json` para `android/app/` e defina
`acolleApplicationId` no arquivo Gradle de propriedades do ambiente de build
(por exemplo, pela variável `ORG_GRADLE_PROJECT_acolleApplicationId`).
Atualize também a configuração FlutterFire de Android em
`lib/firebase_options.dart` e `firebase.json`. Um identificador diferente
instala um aplicativo separado no aparelho.

### Lembretes de medicamentos

Ao entrar ou voltar ao app com conexão, o Acolle estende a agenda local dos
lembretes ativos. A janela é de 14 dias para frequências diárias e de 8
ocorrências para a frequência semanal. Abra o app com conexão antes de a janela
expirar para manter os alarmes programados.

---

## 🤝 Como contribuir

Contribuições são muito bem-vindas! Este projeto está em constante evolução como parte de um TCC, e sugestões são sempre bem-vindas.

1. Faça um **fork** do projeto;
2. Crie uma branch para sua feature (`git checkout -b feature/minha-feature`);
3. Faça o commit das suas alterações (`git commit -m 'feat: adiciona minha feature'`);
4. Faça o push para a branch (`git push origin feature/minha-feature`);
5. Abra um **Pull Request**.

---

## 📌 Status do projeto

🚧 **Em desenvolvimento**

O Acolle está sendo construído como parte de um Trabalho de Conclusão de Curso e segue em evolução contínua, com novas funcionalidades e melhorias de acessibilidade sendo adicionadas ao longo do tempo.

---

## 👥 Equipe

| Nome | GitHub |
|------|--------|
| Beatriz Carvalho da Silva | [@Zirtaeb24](https://github.com/Zirtaeb24) |
| Daniel Lucas Silva Paz | [@Danifff6](https://github.com/Danifff6) |
| Gabriel Henrique Xavier Oliveira | [@Hznq](https://github.com/Hznq) |
| Guilherme da Silva Moreira | [@gui231208](https://github.com/gui231208) |
| Kevin de Souza Novais | [@Kevin20ds](https://github.com/Kevin20ds) |

---

## 📄 Licença

Projeto desenvolvido para fins acadêmicos como Trabalho de Conclusão de Curso.

Todos os direitos reservados aos autores.

---

<div align="center">

Feito com 💜 pensando em quem mais precisa de cuidado no ambiente digital.

</div>
