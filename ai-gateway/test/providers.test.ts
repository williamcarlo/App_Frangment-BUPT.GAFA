import { describe, expect, it, vi } from "vitest";
import { AnalyzeRequest } from "../src/contracts";
import { analyzeText, createEmbedding } from "../src/providers";

const REQUEST: AnalyzeRequest = {
  fragmentId: "fragment_1",
  content: "有些想法需要晚一点再回来看",
  tag: "记录",
  reminder: "WEEKEND",
  locale: "zh-CN",
  aiConsent: true
};

function testEnv(): Env {
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
      limit: async () => ({ success: true })
    }
  };
}

describe("AI providers", () => {
  it("validates embedding dimensions", async () => {
    const vector = Array.from({ length: 1024 }, (_, index) => index / 1024);
    const fetcher = vi.fn(async () => Response.json({
      data: [{
        embedding: vector
      }]
    }));
    const result = await createEmbedding(REQUEST, testEnv(), fetcher);
    expect(result.dimension).toBe(1024);
    expect(result.vector).toEqual(vector);
  });

  it("parses constrained DeepSeek JSON", async () => {
    const fetcher = vi.fn(async () => Response.json({
      choices: [{
        message: {
          content: JSON.stringify({
            normalizedTag: "延迟回看",
            tone: "memory",
            suggestedReminder: "BEDTIME",
            summary: "给想法一点时间，再回来观察它。"
          })
        }
      }]
    }));
    const result = await analyzeText(REQUEST, testEnv(), fetcher);
    expect(result.normalizedTag).toBe("延迟回看");
    expect(result.suggestedReminder).toBe("BEDTIME");
  });
});
