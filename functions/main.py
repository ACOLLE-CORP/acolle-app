from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from google import genai
import json

set_global_options(max_instances=10)

client = genai.Client(api_key="AQ.Ab8RN6JQw6oQ8amrSjRXY2txiMUx2Dj4HJ5u3fqrWijXvh92LA")

PROMPT_BASE = """
Você é um sistema de análise de golpes contra idosos.
Analise a conversa abaixo e responda APENAS em JSON, no formato:
{{
  "risco": 0-100,
  "classificacao": "Baixo" | "Médio" | "Alto",
  "motivos": ["motivo 1", "motivo 2"],
  "recomendacao": "texto curto"
}}

Considere como sinais de risco: pedido de PIX/transferência, urgência,
pedido de sigilo, troca de número alegando ser familiar, solicitação
de senha ou código, ameaças, pressão emocional.

Conversa:
{conversa}
"""

@https_fn.on_request()
def analisar_conversa(req: https_fn.Request) -> https_fn.Response:
    dados = req.get_json(silent=True)

    if not dados or "texto" not in dados:
        return https_fn.Response(
            json.dumps({"erro": "Envie um campo 'texto' no corpo da requisição."}),
            status=400,
            content_type="application/json"
        )

    texto_conversa = dados["texto"]
    prompt = PROMPT_BASE.format(conversa=texto_conversa)

    resposta = client.models.generate_content(
        model="gemini-3.5-flash",
        contents=prompt
    )
    texto_resposta = resposta.text.replace("```json", "").replace("```", "").strip()

    try:
        analise = json.loads(texto_resposta)
    except json.JSONDecodeError:
        return https_fn.Response(
            json.dumps({"erro": "A IA não retornou um JSON válido.", "resposta_bruta": texto_resposta}),
            status=500,
            content_type="application/json"
        )

    return https_fn.Response(
        json.dumps(analise, ensure_ascii=False),
        status=200,
        content_type="application/json"
    )