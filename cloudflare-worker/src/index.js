const OPENSPAM_BASE_URL = "https://api.openspam.es/api/number/";
const CACHE_SECONDS = 24 * 60 * 60;

function normalizePhone(value) {
  const input = String(value ?? "").trim();
  let digits = input.replace(/\D/g, "");
  if (input.startsWith("00")) return digits.slice(2);
  if (!input.startsWith("+") && (digits.length === 10 || digits.length === 11)) {
    digits = `55${digits}`;
  }
  return digits;
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      "Referrer-Policy": "no-referrer",
    },
  });
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (request.method !== "POST" || url.pathname !== "/verificar") {
      return json({ error: "Rota nao encontrada" }, 404);
    }

    const contentLength = Number(request.headers.get("content-length") || 0);
    if (contentLength > 1024) return json({ error: "Requisicao muito grande" }, 413);

    let requestBody;
    try {
      requestBody = await request.json();
    } catch {
      return json({ error: "JSON invalido" }, 400);
    }

    const phone = normalizePhone(requestBody?.numero);
    if (phone.length < 10 || phone.length > 15) {
      return json({ error: "Numero invalido" }, 400);
    }

    const digest = await crypto.subtle.digest(
      "SHA-256",
      new TextEncoder().encode(phone),
    );
    const phoneHash = [...new Uint8Array(digest)]
      .map((byte) => byte.toString(16).padStart(2, "0"))
      .join("");
    const cache = caches.default;
    const cacheKey = new Request(`${url.origin}/cache/v2/${phoneHash}`, { method: "GET" });
    const cached = await cache.match(cacheKey);
    if (cached) return cached;

    const clientKey = request.headers.get("cf-connecting-ip") || "unknown";
    const clientLimit = await env.CLIENT_RATE_LIMITER.limit({ key: clientKey });
    if (!clientLimit.success) return json({ error: "Muitas consultas" }, 429);

    const upstreamLimit = await env.UPSTREAM_RATE_LIMITER.limit({ key: "openspam" });
    if (!upstreamLimit.success) return json({ error: "Tente novamente em instantes" }, 429);

    let upstream;
    try {
      upstream = await fetch(`${OPENSPAM_BASE_URL}+${phone}`, {
        headers: { "X-API-Key": env.OPENSPAM_API_KEY },
      });
    } catch {
      return json({ error: "OpenSpam indisponivel" }, 503);
    }

    if (!upstream.ok) {
      return json({
        error: "Falha ao consultar OpenSpam",
        statusOpenSpam: upstream.status,
      }, 502);
    }

    const body = await upstream.json().catch(() => null);
    const data = body?.data;
    const registro = data?.numero;
    const reportes = data?.encontrado === false ? 0 : registro?.total_reportes;
    if (body?.success !== true || typeof data?.encontrado !== "boolean" ||
        !Number.isInteger(reportes) || reportes < 0) {
      return json({ error: "Resposta invalida do OpenSpam" }, 502);
    }

    const response = json({
      suspeito: reportes > 0,
      reportes,
      nivelPerigo: registro?.nivel_peligro || "desconhecido",
      tipo: registro?.tipo_spam || "desconhecido",
      fonte: "OpenSpam",
    });
    response.headers.set("Cache-Control", `public, s-maxage=${CACHE_SECONDS}`);
    ctx.waitUntil(cache.put(cacheKey, response.clone()));
    return response;
  },
};
