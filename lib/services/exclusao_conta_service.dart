import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'caller_id_service.dart';
import 'notificacao_service.dart';
import 'tutorial_service.dart';

class ExclusaoContaService {
  ExclusaoContaService._();

  static Future<void> excluir(String senha) async {
    final usuario = FirebaseAuth.instance.currentUser;
    final email = usuario?.email;
    if (usuario == null || email == null) {
      throw StateError('Conta indisponível.');
    }

    // Confirma a senha antes de qualquer alteração nos dados.
    await usuario.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: senha),
    );

    final firestore = FirebaseFirestore.instance;
    NotificacaoService.suspenderLembretes = true;
    CallerIdService.suspenderHistorico = true;
    try {
      await NotificacaoService.pararRegistroToken();
      await firestore.waitForPendingWrites();
      for (final colecao in [
        'verificacoes',
        'chamadas',
        'remedios',
        'contatos_emergencia',
      ]) {
        final consulta = firestore
            .collection(colecao)
            .where('usuarioId', isEqualTo: usuario.uid)
            .limit(400);
        while (true) {
          final pagina = await consulta.get(
            const GetOptions(source: Source.server),
          );
          if (pagina.docs.isEmpty) break;
          final lote = firestore.batch();
          for (final doc in pagina.docs) {
            lote.delete(doc.reference);
          }
          await lote.commit();
        }
      }
      await NotificacaoService.cancelarTodosLembretes();
      await firestore.collection('usuarios').doc(usuario.uid).delete();
      await usuario.delete();
      await TutorialService.reiniciar(usuario.uid);
    } finally {
      CallerIdService.suspenderHistorico = false;
      NotificacaoService.suspenderLembretes = false;
    }
  }
}
