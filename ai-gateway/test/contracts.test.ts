import { describe, expect, it } from "vitest";
import { parseAnalyzeRequest, RequestValidationError } from "../src/contracts";
import { constantTimeEquals, readBoundedJson } from "../src/security";

describe("AI gateway contracts", () => {
  it("accepts an explicitly consented request", () => {
    const result = parseAnalyzeRequest({
      fragmentId: "fragment_1",
      content: "把今天短暂消失的想法留下来",
      tag: "记录",
      reminder: "WEEKEND",
      locale: "zh-CN",
      aiConsent: true
    });
    expect(result.aiConsent).toBe(true);
    expect(result.content).toContain("想法");
  });

  it("rejects a request without explicit consent", () => {
    expect(() => parseAnalyzeRequest({
      fragmentId: "fragment_1",
      content: "测试",
      tag: "",
      reminder: "NONE",
      locale: "zh-CN",
      aiConsent: false
    })).toThrow(RequestValidationError);
  });

  it("rejects oversized bodies before parsing", async () => {
    const request = new Request("https://example.test/v1/fragments/analyze", {
      method: "POST",
      headers: {
        "Content-Length": "40000"
      },
      body: "{}"
    });
    await expect(readBoundedJson(request)).rejects.toThrow("请求正文过大");
  });

  it("compares gateway tokens without direct string comparison", async () => {
    await expect(constantTimeEquals("same-token", "same-token")).resolves.toBe(true);
    await expect(constantTimeEquals("wrong-token", "same-token")).resolves.toBe(false);
  });
});
