/// Encontra links dentro de um texto (ex.: texto lido da tela por OCR).
/// Aceita http(s)://, www. e endereços soltos como bit.ly/abc.
final RegExp _regexLinks = RegExp(
  r'(?:https?:\/\/|www\.)[^\s<>"]+|'
  r'\b[a-z0-9][a-z0-9\-]*(?:\.[a-z0-9\-]+)*\.'
  r'(?:com|net|org|br|io|xyz|tk|top|online|site|club|info|link|app|me|co|ly|gl|cc|ru|cn|click|shop|store|live|vip)'
  r'(?:\/[^\s<>"]*)?',
  caseSensitive: false,
);

List<String> extrairLinks(String texto, {int maximo = 5}) {
  final encontrados = <String>[];

  for (final m in _regexLinks.allMatches(texto)) {
    // Ignora endereços de e-mail (ex.: nome@gmail.com).
    if (m.start > 0 && texto[m.start - 1] == '@') continue;

    var link = m.group(0)!.replaceAll(RegExp(r'[.,;:!?)\]]+$'), '');
    if (link.length < 4) continue;

    if (!link.toLowerCase().startsWith('http')) {
      link = 'https://$link';
    }

    if (!encontrados.contains(link)) encontrados.add(link);
    if (encontrados.length >= maximo) break;
  }

  return encontrados;
}
