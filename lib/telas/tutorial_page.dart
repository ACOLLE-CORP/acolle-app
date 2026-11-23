import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/acessibilidade_service.dart';
import '../shared/acolle_design.dart';
import '../shared/acolle_icons.dart';

/// Tutorial prático de primeiro acesso do Acolle.
///
/// Abre sozinho na primeira vez que o usuário chega à tela inicial e pode
/// ser aberto de novo em Aprender > Ver tutorial.
///
/// [aoFinalizar] é chamado quando o usuário conclui, pula ou sai do
/// tutorial (inclusive pelo botão voltar do aparelho).
class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key, this.aoFinalizar});

  final Future<void> Function()? aoFinalizar;

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

enum _GrupoPermissoes { chamadas, outras }

class _Passo {
  const _Passo({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.texto,
    this.destaque,
    this.mascote = false,
    this.grupo,
  });

  final _GrupoPermissoes? grupo;
  final IconData icone;
  final Color cor;
  final String titulo;
  final String texto;
  final String? destaque;
  final bool mascote;
}

const List<_Passo> _passos = [
  _Passo(
    icone: Icons.waving_hand_rounded,
    cor: AcolleDesign.roxo,
    titulo: 'Olá! Eu sou o Collin',
    texto:
        'Seja bem-vindo ao Acolle. Vou mostrar, em poucos passos, '
        'como usar o aplicativo.',
    mascote: true,
  ),
  _Passo(
    icone: AcolleIcons.proteger,
    cor: AcolleDesign.roxo,
    titulo: 'Para que serve o Acolle',
    texto:
        'O Acolle ajuda você a perceber golpes em mensagens, links e '
        'ligações, antes de cair neles.',
  ),
  _Passo(
    icone: Icons.home_rounded,
    cor: AcolleDesign.azul,
    titulo: 'A tela inicial',
    texto:
        'Na tela inicial há quatro botões grandes: PROTEÇÃO, AGENDA, '
        'AJUDA e DICAS. Toque no que você precisar.',
    destaque:
        'Acessibilidade, perfil e sair da conta ficam em Mais opções.',
  ),
  _Passo(
    icone: AcolleIcons.proteger,
    cor: AcolleDesign.roxo,
    titulo: 'Proteção',
    texto:
        'Aqui você verifica mensagens, links e chamadas que parecem '
        'suspeitas.',
    destaque: 'Toque em PROTEÇÃO e escolha o que quer verificar.',
  ),
  _Passo(
    icone: AcolleIcons.mensagem,
    cor: AcolleDesign.roxo,
    titulo: 'Verificar uma mensagem',
    texto:
        'Recebeu uma mensagem estranha? Escreva, cole ou fale o texto em '
        '"Verificar mensagem" e o Acolle analisa para você.',
    destaque: 'Para links, use "Verificar link" antes de abrir.',
  ),
  _Passo(
    icone: Icons.warning_amber_rounded,
    cor: AcolleDesign.vermelho,
    titulo: 'Entenda o resultado',
    texto:
        'O resultado mostra o risco: Baixo, Médio ou Alto. '
        'Se for Médio ou Alto, não clique, não responda e não passe seus '
        'dados.',
  ),
  _Passo(
    icone: AcolleIcons.chamada,
    cor: AcolleDesign.vermelho,
    titulo: 'Aviso de chamada suspeita',
    texto:
        'Se o número que está ligando estiver na lista de números '
        'suspeitos, o Acolle mostra o aviso "Atenção!". '
        'Tenha cuidado ao atender.',
    destaque: 'Configure em Mais opções > Proteção de chamadas.',
  ),
  _Passo(
    icone: Icons.phone_in_talk_rounded,
    cor: AcolleDesign.roxo,
    titulo: 'Ative a proteção de chamadas',
    texto:
        'Toque em "Ativar" em cada item. '
        'Você só precisa fazer isso uma vez neste celular.',
    destaque:
        'Se o celular abrir as Configurações, toque em Permissões e '
        'ative a opção.',
    grupo: _GrupoPermissoes.chamadas,
  ),
  _Passo(
    icone: Icons.shield_rounded,
    cor: AcolleDesign.roxo,
    titulo: 'Proteção rápida',
    texto:
        'Ative a Proteção rápida na tela PROTEÇÃO. O Collin fica na lateral '
        'da tela: toque nele para analisar uma mensagem, verificar um link, '
        'ver alertas ou pedir ajuda.',
    destaque:
        'O aparelho pode pedir permissão para aparecer sobre outros apps.',
    mascote: true,
  ),
  _Passo(
    icone: AcolleIcons.rotina,
    cor: AcolleDesign.azul,
    titulo: 'Agenda',
    texto:
        'Cadastre seus remédios e horários. O Acolle avisa na hora certa.',
    destaque: 'Toque em AGENDA > Lembretes de remédios.',
  ),
  _Passo(
    icone: AcolleIcons.pedirAjuda,
    cor: AcolleDesign.verde,
    titulo: 'Ajuda',
    texto:
        'Precisa de alguém de confiança? Toque em AJUDA para ligar '
        'para o seu contato principal.',
    destaque: 'Você também pode adicionar ou remover contatos ali.',
  ),
  _Passo(
    icone: AcolleIcons.aprender,
    cor: AcolleDesign.laranja,
    titulo: 'Dicas e acessibilidade',
    texto:
        'Em DICAS você encontra dicas para evitar golpes. '
        'Em Mais opções > Acessibilidade, você pode '
        'aumentar as letras e usar alto contraste.',
  ),
  _Passo(
    icone: Icons.notifications_active_rounded,
    cor: AcolleDesign.laranja,
    titulo: 'Ative os outros avisos',
    texto:
        'Estas permissões deixam o Acolle avisar você e ajudar nas '
        'horas certas.',
    destaque: 'Você pode ativar depois, em Configurações do celular.',
    grupo: _GrupoPermissoes.outras,
  ),
  _Passo(
    icone: Icons.check_circle_rounded,
    cor: AcolleDesign.verde,
    titulo: 'Tudo certo!',
    texto:
        'Agora você já sabe usar o Acolle. Para ver este tutorial de novo, '
        'toque no ? na tela inicial.',
    mascote: true,
  ),
];

class _TutorialPageState extends State<TutorialPage> {
  int _indice = 0;
  bool _finalizado = false;

  bool get _ehPrimeiro => _indice == 0;
  bool get _ehUltimo => _indice == _passos.length - 1;

  void _avancar() {
    if (_ehUltimo) {
      _finalizar();
      return;
    }
    setState(() => _indice++);
  }

  void _voltar() {
    if (_ehPrimeiro) return;
    setState(() => _indice--);
  }

  void _finalizar() {
    Navigator.of(context).maybePop();
  }

  void _registrarSaida() {
    if (_finalizado) return;
    _finalizado = true;
    widget.aoFinalizar?.call();
  }

  @override
  Widget build(BuildContext context) {
    final acessibilidade = AcessibilidadeService.instance;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _registrarSaida();
      },
      child: AnimatedBuilder(
        animation: acessibilidade,
        builder: (context, _) {
          final altoContraste = acessibilidade.altoContraste;
          final passo = _passos[_indice];

          return Scaffold(
            backgroundColor: AcolleDesign.corFundo(altoContraste),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cabecalho(altoContraste),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _conteudo(
                            passo,
                            altoContraste,
                            key: ValueKey<int>(_indice),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _rodape(altoContraste),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cabecalho(bool altoContraste) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Passo ${_indice + 1} de ${_passos.length}',
                style: AcolleDesign.texto(
                  tamanho: 18,
                  peso: FontWeight.bold,
                  cor: AcolleDesign.corTextoSecundario(altoContraste),
                ),
              ),
            ),
            if (!_ehUltimo)
              TextButton(
                onPressed: _finalizar,
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, 48),
                  foregroundColor: AcolleDesign.corIcone(altoContraste),
                ),
                child: Text(
                  'Pular',
                  style: AcolleDesign.texto(
                    tamanho: 19,
                    peso: FontWeight.bold,
                    cor: AcolleDesign.corIcone(altoContraste),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_indice + 1) / _passos.length,
            minHeight: 10,
            color: AcolleDesign.corIcone(altoContraste),
            backgroundColor:
                altoContraste ? Colors.white24 : AcolleDesign.roxoSuave,
          ),
        ),
      ],
    );
  }

  Widget _conteudo(_Passo passo, bool altoContraste, {Key? key}) {
    final corDestaque = altoContraste ? AcolleDesign.laranja : passo.cor;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: passo.mascote
              ? ExcludeSemantics(
                  child: Image.asset(
                    'assets/images/mascote_home.png',
                    height: 150,
                  ),
                )
              : Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: altoContraste
                        ? Colors.black
                        : corDestaque.withValues(alpha: 0.12),
                    border: Border.all(color: corDestaque, width: 3),
                  ),
                  child: ExcludeSemantics(
                    child: Icon(passo.icone, size: 64, color: corDestaque),
                  ),
                ),
        ),
        const SizedBox(height: 22),
        Semantics(
          header: true,
          child: Text(
            passo.titulo,
            textAlign: TextAlign.center,
            style: AcolleDesign.texto(
              tamanho: 29,
              peso: FontWeight.w800,
              cor: AcolleDesign.corTexto(altoContraste),
              altura: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          passo.texto,
          textAlign: TextAlign.center,
          style: AcolleDesign.texto(
            tamanho: 21,
            cor: AcolleDesign.corTexto(altoContraste),
            altura: 1.5,
          ),
        ),
        if (passo.grupo != null) ...[
          const SizedBox(height: 18),
          _ListaPermissoes(grupo: passo.grupo!),
        ],
        if (passo.destaque != null) ...[
          const SizedBox(height: 18),
          AcolleDesign.cartao(
            padding: const EdgeInsets.all(14),
            cor: altoContraste ? Colors.black : AcolleDesign.roxoSuave,
            filho: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  size: 28,
                  color: AcolleDesign.corIcone(altoContraste),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    passo.destaque!,
                    style: AcolleDesign.texto(
                      tamanho: 18,
                      peso: FontWeight.w600,
                      cor: AcolleDesign.corTexto(altoContraste),
                      altura: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _rodape(bool altoContraste) {
    final corBotao = AcolleDesign.corIcone(altoContraste);
    final corTextoBotao = altoContraste ? Colors.black : Colors.white;

    final botaoAvancar = SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: _avancar,
        style: ElevatedButton.styleFrom(
          backgroundColor: corBotao,
          foregroundColor: corTextoBotao,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          _ehUltimo ? 'Concluir' : 'Avançar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: corTextoBotao,
          ),
        ),
      ),
    );

    if (_ehPrimeiro) return botaoAvancar;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 60,
            child: OutlinedButton(
              onPressed: _voltar,
              style: OutlinedButton.styleFrom(
                foregroundColor: corBotao,
                side: BorderSide(color: corBotao, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Voltar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: botaoAvancar),
      ],
    );
  }
}

// ============================================================
// PASSOS INTERATIVOS DE PERMISSÕES
// ============================================================

const MethodChannel _canalChamadas = MethodChannel('acolle/caller_id');

Future<bool> _canalAtivo(String metodo) async {
  try {
    return (await _canalChamadas.invokeMethod<bool>(metodo)) ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> _pedirPeloCanal(String metodo) async {
  try {
    await _canalChamadas.invokeMethod<bool>(metodo);
  } catch (_) {}
}

Future<bool> _permissaoAtiva(Permission permissao) async {
  try {
    final status = await permissao.status;
    return status.isGranted || status.isLimited;
  } catch (_) {
    return false;
  }
}

Future<void> _pedirPermissao(Permission permissao) async {
  try {
    final status = await permissao.request();
    // Se o usuário recusou "para sempre", só as Configurações resolvem.
    if (status.isPermanentlyDenied) await openAppSettings();
  } catch (_) {}
}

class _ItemPermissao {
  const _ItemPermissao({
    required this.icone,
    required this.titulo,
    required this.dica,
    required this.verificar,
    required this.pedir,
  });

  final IconData icone;
  final String titulo;
  final String dica;
  final Future<bool> Function() verificar;
  final Future<void> Function() pedir;
}

List<_ItemPermissao> _itensDoGrupo(_GrupoPermissoes grupo) {
  switch (grupo) {
    case _GrupoPermissoes.chamadas:
      return [
        _ItemPermissao(
          icone: Icons.phone_in_talk_rounded,
          titulo: 'Ver quem está ligando',
          dica: 'Permite ao Acolle ler o número que está chamando.',
          verificar: () => _permissaoAtiva(Permission.phone),
          pedir: () => _pedirPermissao(Permission.phone),
        ),
        _ItemPermissao(
          icone: Icons.verified_user_rounded,
          titulo: 'Identificar chamadas',
          dica: 'Na próxima tela, escolha Acolle e confirme.',
          verificar: () => _canalAtivo('isScreeningRoleEnabled'),
          pedir: () => _pedirPeloCanal('requestScreeningRole'),
        ),
        _ItemPermissao(
          icone: Icons.warning_amber_rounded,
          titulo: 'Mostrar o aviso grande',
          dica: 'Ative a chave "Permitir exibição sobre outros apps".',
          verificar: () => _canalAtivo('isOverlayPermissionEnabled'),
          pedir: () => _pedirPeloCanal('requestOverlayPermission'),
        ),
      ];
    case _GrupoPermissoes.outras:
      return [
        _ItemPermissao(
          icone: Icons.notifications_active_rounded,
          titulo: 'Notificações',
          dica: 'Avisos de chamadas suspeitas e lembretes de remédios.',
          verificar: () => _permissaoAtiva(Permission.notification),
          pedir: () => _pedirPermissao(Permission.notification),
        ),
        _ItemPermissao(
          icone: Icons.mic_rounded,
          titulo: 'Microfone',
          dica: 'Para falar a mensagem em vez de escrever.',
          verificar: () => _permissaoAtiva(Permission.microphone),
          pedir: () => _pedirPermissao(Permission.microphone),
        ),
        _ItemPermissao(
          icone: Icons.contact_page_rounded,
          titulo: 'Contatos',
          dica: 'Para chamar alguém de confiança quando sentir dúvida.',
          verificar: () => _permissaoAtiva(Permission.contacts),
          pedir: () => _pedirPermissao(Permission.contacts),
        ),
      ];
  }
}

/// Lista de permissões com o estado real de cada uma e botão "Ativar".
/// Atualiza sozinha quando o usuário volta das telas do sistema.
class _ListaPermissoes extends StatefulWidget {
  const _ListaPermissoes({required this.grupo});

  final _GrupoPermissoes grupo;

  @override
  State<_ListaPermissoes> createState() => _ListaPermissoesState();
}

class _ListaPermissoesState extends State<_ListaPermissoes>
    with WidgetsBindingObserver {
  late final List<_ItemPermissao> _itens;
  late List<bool> _ativos;

  @override
  void initState() {
    super.initState();
    _itens = _itensDoGrupo(widget.grupo);
    _ativos = List<bool>.filled(_itens.length, false);
    WidgetsBinding.instance.addObserver(this);
    _atualizar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _atualizar();
  }

  Future<void> _atualizar() async {
    final novos = <bool>[];
    for (final item in _itens) {
      novos.add(await item.verificar());
    }
    if (!mounted) return;
    setState(() => _ativos = novos);
  }

  Future<void> _ativar(_ItemPermissao item) async {
    await item.pedir();
    await _atualizar();
  }

  @override
  Widget build(BuildContext context) {
    final altoContraste = AcessibilidadeService.instance.altoContraste;
    final corOk = altoContraste ? Colors.greenAccent : AcolleDesign.verde;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _itens.length; i++)
          AcolleDesign.cartao(
            margem: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            filho: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      _itens[i].icone,
                      size: 30,
                      color: AcolleDesign.corIcone(altoContraste),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _itens[i].titulo,
                        style: AcolleDesign.texto(
                          tamanho: 20,
                          peso: FontWeight.bold,
                          cor: AcolleDesign.corTexto(altoContraste),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _itens[i].dica,
                  style: AcolleDesign.texto(
                    tamanho: 17,
                    cor: AcolleDesign.corTextoSecundario(altoContraste),
                    altura: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                if (_ativos[i])
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: corOk, size: 30),
                      const SizedBox(width: 8),
                      Text(
                        'Ativado',
                        style: AcolleDesign.texto(
                          tamanho: 20,
                          peso: FontWeight.bold,
                          cor: corOk,
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _ativar(_itens[i]),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AcolleDesign.corIcone(altoContraste),
                        foregroundColor:
                            altoContraste ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Ativar',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
