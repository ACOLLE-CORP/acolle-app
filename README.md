<div align="center">

<!-- LOGO -->
<img src="./assets/images/mascote.png" alt="Logo Acolle" width="140"/>

# 💜 Acolle

### Segurança digital acessível para pessoas idosas

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.12-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=white)](https://firebase.google.com)
[![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)](#-status-do-projeto)
[![Licença](https://img.shields.io/badge/licença-MIT-green)](#-licença)

</div>

---

## 📖 Sobre o projeto

**Acolle** é um aplicativo mobile desenvolvido em **Flutter**, criado como **Trabalho de Conclusão de Curso (TCC)** do curso Técnico em Desenvolvimento de Sistemas.

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

- 🔐 **Cadastro de usuários** — criação de conta simples e guiada;
- 🔑 **Login** — acesso seguro à conta do usuário;
- 👤 **Perfil** — visualização e gerenciamento dos dados do usuário;
- 🏠 **Tela inicial** — painel central de navegação do aplicativo;
- 💡 **Dicas de prevenção contra golpes** — conteúdo educativo em linguagem acessível;
- ♿ **Interface acessível** — botões grandes, fontes ampliadas, alto contraste e navegação simplificada.

> 🚧 O Acolle está em desenvolvimento contínuo. Novas funcionalidades — como verificação de links suspeitos, análise de mensagens, contatos de emergência e lembretes de medicamentos — estão sendo implementadas e serão documentadas conforme forem concluídas.

---

## 🛠️ Tecnologias utilizadas

O projeto foi desenvolvido utilizando:

- **[Flutter](https://flutter.dev)** — framework multiplataforma para desenvolvimento mobile;
- **[Dart](https://dart.dev)** — linguagem de programação utilizada no desenvolvimento do app;
- **[Firebase](https://firebase.google.com)** — plataforma de backend, utilizada para autenticação e banco de dados de usuários.

---

## 📁 Estrutura de pastas

```
acolle/
├── android/            # Configurações e código nativo Android
├── ios/                # Configurações e código nativo iOS
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
- Um emulador Android/iOS configurado ou um dispositivo físico conectado

### Passo a passo

```bash
# 1. Clone este repositório
git clone https://github.com/ACOLLE-CORP/acolle-app.git

# 2. Acesse a pasta do projeto
cd acolle

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

Para gerar um build de produção:

```bash
# Android (APK)
flutter build apk

# iOS
flutter build ios
```

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