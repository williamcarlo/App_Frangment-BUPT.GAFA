import { AnalyzeResponse, parseAnalyzeRequest, RequestValidationError } from "./contracts";
import { analyzeText, createEmbedding, ProviderError } from "./providers";
import {
  bearerToken,
  constantTimeEquals,
  readBoundedJson,
  tokenRateLimitKey
} from "./security";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const requestId = crypto.randomUUID();
    const url = new URL(request.url);
    const corsHeaders = corsHeadersFor(request, env);

    if (url.pathname === "/health" && request.method === "GET") {
      return jsonResponse({
        ok: true,
        service: "fragment-ai-gateway",
        embeddingModel: env.EMBEDDING_MODEL,
        embeddingDimension: Number(env.EMBEDDING_DIMENSION),
        deepSeekModel: env.DEEPSEEK_MODEL
      }, 200, corsHeaders);
    }

    if (request.method === "OPTIONS") {
      return corsHeaders === null
        ? jsonResponse({ error: "origin_not_allowed", requestId }, 403, null)
        : new Response(null, { status: 204, headers: corsHeaders });
    }

    if (url.pathname !== "/v1/fragments/analyze" || request.method !== "POST") {
      return jsonResponse({ error: "not_found", requestId }, 404, corsHeaders);
    }
    if (corsHeaders === null && request.headers.has("origin")) {
      return jsonResponse({ error: "origin_not_allowed", requestId }, 403, null);
    }

    try {
      const token = bearerToken(request);
      if (token.length === 0 || !(await constantTimeEquals(token, env.FRAGMENT_GATEWAY_TOKEN))) {
        return jsonResponse({ error: "unauthorized", requestId }, 401, corsHeaders);
      }

      const rateLimit = await env.AI_RATE_LIMITER.limit({
        key: await tokenRateLimitKey(token)
      });
      if (!rateLimit.success) {
        return jsonResponse({ error: "rate_limited", requestId }, 429, corsHeaders);
      }

      const payload = parseAnalyzeRequest(await readBoundedJson(request));
      const [analysis, embedding] = await Promise.all([
        analyzeText(payload, env),
        createEmbedding(payload, env)
      ]);
      const response: AnalyzeResponse = {
        requestId,
        analysisProvider: "deepseek",
        analysisModel: env.DEEPSEEK_MODEL,
        analysis,
        embedding
      };
      console.log(JSON.stringify({
        event: "fragment_analyzed",
        requestId,
        fragmentId: payload.fragmentId,
        embeddingDimension: embedding.dimension
      }));
      return jsonResponse(response, 200, corsHeaders);
    } catch (error) {
      if (error instanceof RequestValidationError) {
        return jsonResponse({
          error: "invalid_request",
          message: error.message,
          requestId
        }, 400, corsHeaders);
      }
      if (error instanceof ProviderError) {
        console.error(JSON.stringify({
          event: "provider_error",
          requestId,
          provider: error.provider,
          message: error.message
        }));
        return jsonResponse({
          error: "provider_unavailable",
          requestId
        }, 502, corsHeaders);
      }
      console.error(JSON.stringify({
        event: "unhandled_error",
        requestId,
        message: error instanceof Error ? error.message : "unknown"
      }));
      return jsonResponse({
        error: "internal_error",
        requestId
      }, 500, corsHeaders);
    }
  }
} satisfies ExportedHandler<Env>;

function corsHeadersFor(request: Request, env: Env): Headers | null {
  const origin = request.headers.get("origin");
  const headers = new Headers({
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Vary": "Origin"
  });
  if (origin === null) {
    return headers;
  }
  if (env.ALLOWED_ORIGIN.length === 0 || origin !== env.ALLOWED_ORIGIN) {
    return null;
  }
  headers.set("Access-Control-Allow-Origin", origin);
  headers.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
  headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  headers.set("Access-Control-Max-Age", "600");
  return headers;
}

function jsonResponse(value: object, status: number, extraHeaders: Headers | null): Response {
  const headers = extraHeaders ?? new Headers({
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store"
  });
  return Response.json(value, {
    status,
    headers
  });
}
