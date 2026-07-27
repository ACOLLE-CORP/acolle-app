import 'package:http/http.dart' as http;
import 'dart:convert';

class AcolleApi {
  static const String baseUrl = 'https://acolle-api.onrender.com';

  static Future<Map<String, dynamic>> analisarConversa(String texto) async {
    final url = Uri.parse('$baseUrl/analisar');

    final resposta = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'texto': texto}),
    );

    return jsonDecode(resposta.body);
  }
}