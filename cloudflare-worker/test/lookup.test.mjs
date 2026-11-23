import assert from "node:assert/strict";
import { test } from "node:test";
import worker from "../src/index.js";

test("interpreta a consulta padrão do OpenSpam", async (t) => {
  const cacheWrites = [];
  const originalCaches = globalThis.caches;
  globalThis.caches = {
    default: {
      match: async () => undefined,
      put: async (key) => cacheWrites.push(key.url),
    },
  };
  t.after(() => {
    if (originalCaches === undefined) delete globalThis.caches;
    else globalThis.caches = originalCaches;
  });

  const limiter = { limit: async () => ({ success: true }) };
  const env = {
    CLIENT_RATE_LIMITER: limiter,
    UPSTREAM_RATE_LIMITER: limiter,
    OPENSPAM_API_KEY: "test-key",
  };
  const ctx = { waitUntil: () => {} };

  async function lookup(input, expectedNumber, upstreamBody, upstreamStatus = 200) {
    const fetch = t.mock.method(globalThis, "fetch", async (url) => {
      assert.equal(url, `https://api.openspam.es/api/number/+${expectedNumber}`);
      return Response.json(upstreamBody, { status: upstreamStatus });
    });
    try {
      return await worker.fetch(new Request("https://worker.example/verificar", {
        method: "POST",
        body: JSON.stringify({ numero: input }),
      }), env, ctx);
    } finally {
      assert.equal(fetch.mock.callCount(), 1);
      fetch.mock.restore();
    }
  }

  const reported = await lookup("(55) 98765-4321", "5555987654321", {
    success: true,
    data: {
      encontrado: true,
      numero: { total_reportes: 12, nivel_peligro: "alto", tipo_spam: "fraude" },
    },
  });
  assert.equal(reported.status, 200);
  assert.deepEqual(await reported.json(), {
    suspeito: true, reportes: 12, nivelPerigo: "alto", tipo: "fraude", fonte: "OpenSpam",
  });

  const missing = await lookup("+1 202 555 0100", "12025550100", {
    success: true, data: { encontrado: false },
  });
  assert.equal(missing.status, 200);
  assert.equal((await missing.json()).suspeito, false);

  const invalid = await lookup("+1 202 555 0100", "12025550100", {
    success: true, data: { encontrado: true, numero: {} },
  });
  assert.equal(invalid.status, 502);
  assert.equal((await invalid.json()).suspeito, undefined);

  const wrongEndpoint = await lookup("+1 202 555 0100", "12025550100", {
    success: false, code: "endpoint_not_found",
  }, 404);
  assert.equal(wrongEndpoint.status, 502);
  assert.equal((await wrongEndpoint.json()).suspeito, undefined);
  assert.equal(cacheWrites.length, 2);
  assert.ok(cacheWrites.every((key) => key.includes("/cache/v2/")));
});
