import { RequestValidationError } from "./contracts";

const MAX_REQUEST_BYTES = 32 * 1024;

export async function readBoundedJson(request: Request): Promise<unknown> {
  const contentLength = request.headers.get("content-length");
  if (contentLength !== null) {
    const declaredLength = Number(contentLength);
    if (!Number.isFinite(declaredLength) || declaredLength < 0 || declaredLength > MAX_REQUEST_BYTES) {
      throw new RequestValidationError("请求正文过大");
    }
  }

  const text = await request.text();
  if (new TextEncoder().encode(text).byteLength > MAX_REQUEST_BYTES) {
    throw new RequestValidationError("请求正文过大");
  }
  try {
    return JSON.parse(text);
  } catch {
    throw new RequestValidationError("请求正文不是有效 JSON");
  }
}

export function bearerToken(request: Request): string {
  const authorization = request.headers.get("authorization") ?? "";
  const prefix = "Bearer ";
  if (!authorization.startsWith(prefix)) {
    return "";
  }
  return authorization.slice(prefix.length).trim();
}

export async function constantTimeEquals(provided: string, expected: string): Promise<boolean> {
  const encoder = new TextEncoder();
  const [providedHash, expectedHash] = await Promise.all([
    crypto.subtle.digest("SHA-256", encoder.encode(provided)),
    crypto.subtle.digest("SHA-256", encoder.encode(expected))
  ]);
  const providedBytes = new Uint8Array(providedHash);
  const expectedBytes = new Uint8Array(expectedHash);
  let difference = 0;
  for (let index = 0; index < providedBytes.length; index += 1) {
    difference |= providedBytes[index]! ^ expectedBytes[index]!;
  }
  return difference === 0;
}

export async function tokenRateLimitKey(token: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(token));
  return Array.from(new Uint8Array(digest))
    .slice(0, 12)
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("");
}
