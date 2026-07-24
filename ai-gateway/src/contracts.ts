export type ReminderPreference = "COMMUTE" | "BEDTIME" | "WEEKEND" | "NONE" | "RANDOM";
export type FragmentTone = "memory" | "self" | "idea" | "slate" | "rose";

export interface AnalyzeRequest {
  fragmentId: string;
  content: string;
  tag: string;
  reminder: ReminderPreference;
  locale: string;
  aiConsent: true;
}

export interface AiTextAnalysis {
  normalizedTag: string;
  tone: FragmentTone;
  suggestedReminder: ReminderPreference;
  summary: string;
}

export interface EmbeddingResult {
  model: string;
  dimension: number;
  vector: number[];
}

export interface AnalyzeResponse {
  requestId: string;
  analysisProvider: "deepseek";
  analysisModel: string;
  analysis: AiTextAnalysis;
  embedding: EmbeddingResult;
}

export class RequestValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "RequestValidationError";
  }
}

const REMINDERS: ReminderPreference[] = ["COMMUTE", "BEDTIME", "WEEKEND", "NONE", "RANDOM"];

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function isReminder(value: unknown): value is ReminderPreference {
  return typeof value === "string" && REMINDERS.includes(value as ReminderPreference);
}

export function parseAnalyzeRequest(value: unknown): AnalyzeRequest {
  if (!isRecord(value)) {
    throw new RequestValidationError("请求正文必须是 JSON 对象");
  }

  const fragmentId = readString(value.fragmentId, "fragmentId", 1, 128);
  const content = readString(value.content, "content", 1, 2000);
  const tag = readString(value.tag, "tag", 0, 40);
  const locale = readString(value.locale, "locale", 2, 16);
  if (!isReminder(value.reminder)) {
    throw new RequestValidationError("reminder 不在允许范围内");
  }
  if (value.aiConsent !== true) {
    throw new RequestValidationError("必须取得明确的 AI 处理同意");
  }

  return {
    fragmentId,
    content,
    tag,
    reminder: value.reminder,
    locale,
    aiConsent: true
  };
}

function readString(
  value: unknown,
  fieldName: string,
  minimumLength: number,
  maximumLength: number
): string {
  if (typeof value !== "string") {
    throw new RequestValidationError(`${fieldName} 必须是字符串`);
  }
  const normalized = value.trim();
  if (normalized.length < minimumLength || normalized.length > maximumLength) {
    throw new RequestValidationError(`${fieldName} 长度不符合要求`);
  }
  return normalized;
}
