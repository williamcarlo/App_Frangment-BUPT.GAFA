import {
  AiTextAnalysis,
  AnalyzeRequest,
  EmbeddingResult,
  FragmentTone,
  isRecord,
  isReminder
} from "./contracts";

type Fetcher = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

export class ProviderError extends Error {
  readonly provider: string;

  constructor(provider: string, message: string) {
    super(message);
    this.name = "ProviderError";
    this.provider = provider;
  }
}

export async function createEmbedding(
  request: AnalyzeRequest,
  env: Env,
  fetcher: Fetcher = fetch
): Promise<EmbeddingResult> {
  const dimension = parsePositiveInteger(env.EMBEDDING_DIMENSION, 1024);
  const response = await providerFetch(
    `${trimTrailingSlash(env.DASHSCOPE_BASE_URL)}/embeddings`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${env.DASHSCOPE_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: env.EMBEDDING_MODEL,
        input: request.content,
        dimensions: dimension
      })
    },
    parsePositiveInteger(env.PROVIDER_TIMEOUT_MS, 20000),
    fetcher,
    "dashscope"
  );

  if (!isRecord(response) || !Array.isArray(response.data) || response.data.length === 0) {
    throw new ProviderError("dashscope", "Embedding 返回缺少 data");
  }
  const first = response.data[0];
  if (!isRecord(first) || !Array.isArray(first.embedding)) {
    throw new ProviderError("dashscope", "Embedding 返回缺少向量");
  }
  const vector: number[] = [];
  for (const value of first.embedding) {
    if (typeof value !== "number" || !Number.isFinite(value)) {
      throw new ProviderError("dashscope", "Embedding 向量包含非法值");
    }
    vector.push(value);
  }
  if (vector.length !== dimension) {
    throw new ProviderError("dashscope", "Embedding 维度与配置不一致");
  }
  return {
    model: env.EMBEDDING_MODEL,
    dimension,
    vector
  };
}

export async function analyzeText(
  request: AnalyzeRequest,
  env: Env,
  fetcher: Fetcher = fetch
): Promise<AiTextAnalysis> {
  const response = await providerFetch(
    `${trimTrailingSlash(env.DEEPSEEK_BASE_URL)}/chat/completions`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${env.DEEPSEEK_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: env.DEEPSEEK_MODEL,
        messages: [
          {
            role: "system",
            content:
              "你是 Fragment 应用的幕后整理器。只输出 json 对象，不解释。"
              + "字段必须为 normalizedTag、tone、suggestedReminder、summary。"
              + "normalizedTag 不超过 12 个中文字符；tone 只能是 memory/self/idea/slate/rose；"
              + "suggestedReminder 只能是 COMMUTE/BEDTIME/WEEKEND/NONE/RANDOM；"
              + "summary 不超过 60 个中文字符。不要推断身份、健康、政治或其他敏感属性。"
          },
          {
            role: "user",
            content: JSON.stringify({
              locale: request.locale,
              originalTag: request.tag,
              originalReminder: request.reminder,
              fragment: request.content
            })
          }
        ],
        response_format: {
          type: "json_object"
        },
        temperature: 0.2,
        max_tokens: 300
      })
    },
    parsePositiveInteger(env.PROVIDER_TIMEOUT_MS, 20000),
    fetcher,
    "deepseek"
  );

  const content = deepSeekContent(response);
  let parsed: unknown;
  try {
    parsed = JSON.parse(content);
  } catch {
    throw new ProviderError("deepseek", "DeepSeek 没有返回有效 JSON");
  }
  if (!isRecord(parsed)) {
    throw new ProviderError("deepseek", "DeepSeek JSON 结构无效");
  }

  const normalizedTag =
    typeof parsed.normalizedTag === "string" && parsed.normalizedTag.trim().length > 0
      ? parsed.normalizedTag.trim().slice(0, 12)
      : request.tag;
  const tone = isTone(parsed.tone) ? parsed.tone : "slate";
  const suggestedReminder = isReminder(parsed.suggestedReminder)
    ? parsed.suggestedReminder
    : request.reminder;
  const summary =
    typeof parsed.summary === "string" && parsed.summary.trim().length > 0
      ? parsed.summary.trim().slice(0, 60)
      : request.content.slice(0, 60);

  return {
    normalizedTag,
    tone,
    suggestedReminder,
    summary
  };
}

async function providerFetch(
  url: string,
  init: RequestInit,
  timeoutMs: number,
  fetcher: Fetcher,
  provider: string
): Promise<unknown> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort("provider timeout"), timeoutMs);
  try {
    const response = await fetcher(url, {
      ...init,
      signal: controller.signal
    });
    const contentLength = Number(response.headers.get("content-length") ?? "0");
    if (Number.isFinite(contentLength) && contentLength > 1024 * 1024) {
      throw new ProviderError(provider, "供应商响应过大");
    }
    const text = await response.text();
    if (new TextEncoder().encode(text).byteLength > 1024 * 1024) {
      throw new ProviderError(provider, "供应商响应过大");
    }
    if (!response.ok) {
      throw new ProviderError(provider, `供应商请求失败 (${response.status})`);
    }
    try {
      return JSON.parse(text);
    } catch {
      throw new ProviderError(provider, "供应商返回了无效 JSON");
    }
  } catch (error) {
    if (error instanceof ProviderError) {
      throw error;
    }
    throw new ProviderError(provider, error instanceof Error ? error.message : "供应商请求失败");
  } finally {
    clearTimeout(timeout);
  }
}

function deepSeekContent(response: unknown): string {
  if (!isRecord(response) || !Array.isArray(response.choices) || response.choices.length === 0) {
    throw new ProviderError("deepseek", "DeepSeek 返回缺少 choices");
  }
  const choice = response.choices[0];
  if (!isRecord(choice) || !isRecord(choice.message) || typeof choice.message.content !== "string") {
    throw new ProviderError("deepseek", "DeepSeek 返回缺少消息内容");
  }
  return choice.message.content;
}

function isTone(value: unknown): value is FragmentTone {
  return value === "memory" || value === "self" || value === "idea" || value === "slate" || value === "rose";
}

function parsePositiveInteger(value: string, fallback: number): number {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
}

function trimTrailingSlash(value: string): string {
  return value.endsWith("/") ? value.slice(0, -1) : value;
}
