import { afterEach, describe, expect, it, vi } from "vitest";
import worker from "../src/index";
import { isRecord } from "../src/contracts";

function testEnv(rateLimitSuccess: boolean = true): Env {
  return {
    DEEPSEEK_API_KEY: "test-deepseek",
    DASHSCOPE_API_KEY: "test-dashscope",
    FRAGMENT_GATEWAY_TOKEN: "test-gateway",
    DEEPSEEK_BASE_URL: "https://api.deepseek.com",
    DEEPSEEK_MODEL: "deepseek-v4-flash",
    DASHSCOPE_BASE_URL: "https://dashscope.aliyuncs.com/compatible-mode/v1",
    EMBEDDING_MODEL: "text-embedding-v4",
    EMBEDDING_DIMENSION: "1024",
    PROVIDER_TIMEOUT_MS: "20000",
    ALLOWED_ORIGIN: "",
    AI_RATE_LIMITER: {
      limit: async () => ({ success: rateLimitSuccess })
    }
  };
}

function analyzeRequest(token: string): Request {
  return new Request("https://gateway.test/v1/fragments/analyze", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      fragmentId: "fragment_1",
      content: "把今天短暂消失的想法留下来",
      tag: "记录",
      reminder: "WEEKEND",
      locale: "zh-CN",
      aiConsent: true
    })
  });
}

describe("AI gateway handler", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("rejects invalid gateway credentials before calling providers", async () => {
    const providerFetch = vi.fn();
    vi.stubGlobal("fetch", providerFetch);

    const response = await worker.fetch(analyzeRequest("wrong-token"), testEnv());
    const body: unknown = await response.json();
    expect(response.status).toBe(401);
    expect(isRecord(body) && body.error === "unauthorized").toBe(true);
    expect(providerFetch).not.toHaveBeenCalled();
  });

  it("returns validated DeepSeek analysis and 1024-dimensional embedding", async () => {
    const vector = Array.from({ length: 1024 }, (_, index) => index / 1024);
    vi.stubGlobal("fetch", vi.fn(async (input: RequestInfo | URL) => {
      const url = input.toString();
      if (url.includes("/embeddings")) {
        return Response.json({
          data: [{
            embedding: vector
          }]
        });
      }
      return Response.json({
        choices: [{
          message: {
            content: JSON.stringify({
              normalizedTag: "短暂想法",
              tone: "idea",
              suggestedReminder: "WEEKEND",
              summary: "把容易消失的想法先留在纸面上。"
            })
          }
        }]
      });
    }));

    const response = await worker.fetch(analyzeRequest("test-gateway"), testEnv());
    const body: unknown = await response.json();
    expect(response.status).toBe(200);
    expect(isRecord(body) && isRecord(body.embedding) && body.embedding.dimension === 1024).toBe(true);
  });

  it("enforces the provider-cost rate limit", async () => {
    const providerFetch = vi.fn();
    vi.stubGlobal("fetch", providerFetch);

    const response = await worker.fetch(analyzeRequest("test-gateway"), testEnv(false));
    expect(response.status).toBe(429);
    expect(providerFetch).not.toHaveBeenCalled();
  });
});
