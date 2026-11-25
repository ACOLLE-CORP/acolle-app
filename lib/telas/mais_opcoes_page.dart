import 'package:flutter/material.dart';

import '../services/acessibilidade_service.dart';
import '../shared/acoes_conta.dart';
import '../shared/acolle_design.dart';
import '../shared/acolle_icons.dart';
import 'configurar_protecao_chamadas_page.dart';
import 'historico_chamadas_page.dart';
import 'historico_page.dart';
import 'perfil_page.dart';
import 'termos_page.dart';

class MaisOpcoesPage extends StatelessWidget {
  const MaisOpcoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final contraste = AcessibilidadeService.instance.altoContraste;
    final texto = AcolleDesign.corTexto(contraste);
    final icone = AcolleDesign.corIcone(contraste);

    void abrir(Widget pagina) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => pagina));

    Widget secao(String titulo) => Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(
          titulo,
          style: AcolleDesign.texto(
            tamanho: 20,
            peso: FontWeight.bold,
            cor: texto,
          ),
        ),
      ),
    );

    Widget item(
      IconData simbolo,
      String titulo,
      VoidCallback abrir, {
      String? descricao,
    }) => ListTile(
      leading: Icon(simbolo, color: icone),
      title: Text(titulo, style: AcolleDesign.texto(tamanho: 18, cor: texto)),
      subtitle: descricao == null
          ? null
          : Text(descricao, style: AcolleDesign.texto(tamanho: 15, cor: texto)),
      trailing: Icon(Icons.chevron_right, color: icone),
      onTap: abrir,
    );

    return Scaffold(
      backgroundColor: AcolleDesign.corFundo(contraste),
      appBar: AcolleDesign.appBarPadrao('Mais opções', centralizado: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          children: [
            secao('Proteção'),
            item(
              AcolleIcons.chamada,
              'Proteção de chamadas',
              () => abrir(
                ConfigurarProtecaoChamadasPage(
                  proxima: (_) => const HistoricoChamadasPage(),
                ),
              ),
            ),
            item(
              AcolleIcons.chamadasRecebidas,
              'Histórico de chamadas',
              () => abrir(const HistoricoChamadasPage()),
            ),
            item(
              AcolleIcons.historico,
              'Histórico de verificações',
              () => abrir(const HistoricoPage()),
              descricao: 'Consulte mensagens e links analisados.',
            ),
            secao('Minha conta'),
            item(
              AcolleIcons.perfil,
              'Meu perfil',
              () => abrir(const PerfilPage()),
            ),
            item(
              AcolleIcons.acessibilidade,
              'Acessibilidade',
              () => abrirAcessibilidade(context),
              descricao: 'Tamanho das letras e alto contraste.',
            ),
            item(
              Icons.privacy_tip_outlined,
              'Termos e privacidade',
              () => abrir(const TermosPage(onboarding: false)),
            ),
            item(
              AcolleIcons.sair,
              'Sair da conta',
              () => confirmarSaida(context),
            ),
            const Divider(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: contraste
                      ? Colors.redAccent.shade100
                      : Colors.red.shade800,
                ),
                onPressed: () => confirmarExclusaoConta(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir conta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
