import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/acolle_api.dart';

const Color roxoAcolle = Color(0xFF773FD1);
const Color fundoAcolle = Color(0xFFFAF7FC);

class AnalisarMensagemPage extends StatefulWidget {
  const AnalisarMensagemPage({super.key});

  @override
  State<AnalisarMensagemPage> createState() => _AnalisarMensagemPageState();
}

class _AnalisarMensagemPageState extends State<AnalisarMensagemPage> {
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechDisponivel = false;
  bool _ouvindo = false;
  bool _carregando = false;
  Map<String, dynamic>? _resultado;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _inicializarSpeech();
  }

  Future<void> _inicializarSpeech() async {
    _speechDisponivel = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _ouvindo = false);
        }
      },
      onError: (erro) {
        setState(() => _ouvindo = false);
      },
    );
    setState(() {});
  }

  Future<void> _alternarGravacao() async {
    if (!_speechDisponivel) {
      setState(() {
        _erro = 'Reconhecimento de voz não disponível neste dispositivo.';
      });
      return;
    }

    if (_ouvindo) {
      await _speech.stop();
      setState(() => _ouvindo = false);
      return;
    }

    setState(() {
      _ouvindo = true;
      _erro = null;
    });

    await _speech.listen(
      onResult: (resultado) {
        setState(() {
          _controller.text = resultado.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
    );
  }

  Future<void> _analisar() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _carregando = true;
      _resultado = null;
      _erro = null;
    });

    try {
      final resposta = await AcolleApi.analisarConversa(_controller.text);
      setState(() {
        _resultado = resposta;
      });

      // Salvar no Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('verificacoes').add({
          'usuarioId': user.uid,
          'tipo': 'mensagem',
          'conteudo': _controller.text,
          'risco': resposta['classificacao'] ?? 'desconhecido',
          'percentual': resposta['risco'] ?? 0,
          'data': FieldValue.serverTimestamp(),
        });
      }
    } on AcolleApiException catch (e) {
      // Erro vindo da API (status HTTP, timeout, formato inesperado, etc).
      // Isso te mostra o motivo real em vez de uma mensagem genérica.
      debugPrint('Erro Acolle API: $e');
      setState(() {
        _erro = 'Não foi possível analisar agora. Detalhe: $e';
      });
    } catch (e) {
      // Qualquer outro erro (ex: falha ao salvar no Firestore).
      debugPrint('Erro inesperado ao analisar: $e');
      setState(() {
        _erro = 'Ocorreu um erro inesperado. Tente novamente.';
      });
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  Color _corPorRisco(String? classificacao) {
    switch (classificacao) {
      case 'Alto':
        return Colors.red;
      case 'Médio':
        return Colors.orange;
      case 'Baixo':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoAcolle,
      appBar: AppBar(
        backgroundColor: fundoAcolle,
        elevation: 0,
        title: const Text(
          'Analisar Mensagem',
          style: TextStyle(color: roxoAcolle, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: roxoAcolle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cole a mensagem ou toque no microfone para falar:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Cole a conversa aqui ou use o microfone...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            // Botão do microfone
            Center(
              child: GestureDetector(
                onTap: _alternarGravacao,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _ouvindo ? Colors.red : roxoAcolle,
                  ),
                  child: Icon(
                    _ouvindo ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _ouvindo ? 'Ouvindo... toque para parar' : 'Toque para falar',
                style: const TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _carregando ? null : _analisar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: roxoAcolle,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Analisar',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            if (_erro != null)
              Text(_erro!, style: const TextStyle(color: Colors.red)),
            if (_resultado != null) _buildResultado(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultado() {
    final classificacao = _resultado!['classificacao'] as String?;
    final risco = _resultado!['risco'];
    final motivos = (_resultado!['motivos'] as List?) ?? [];
    final recomendacao = _resultado!['recomendacao'] as String?;
    final cor = _corPorRisco(classificacao);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                classificacao == 'Alto' ? Icons.warning_amber_rounded : Icons.shield_outlined,
                color: cor,
                size: 32,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Risco $classificacao ($risco%)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          if (motivos.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Motivos identificados:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...motivos.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $m'),
                )),
          ],
          if (recomendacao != null) ...[
            const SizedBox(height: 14),
            const Text('Recomendação:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(recomendacao),
          ],
        ],
      ),
    );
  }
}