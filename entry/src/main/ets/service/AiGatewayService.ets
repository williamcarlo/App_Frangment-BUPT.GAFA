import http from '@ohos.net.http'
import {
  AiGatewayResult,
  AiTextAnalysis,
  FragmentEmbedding
} from '../model/AiModel'
import {
  FragmentItem,
  ReminderPreference
} from '../model/FragmentModel'

interface GatewayAnalysisPayload {
  normalizedTag: string
  tone: string
  suggestedReminder: string
  summary: string
}

interface GatewayEmbeddingPayload {
  model: string
  dimension: number
  vector: number[]
}

interface GatewayResponsePayload {
  requestId: string
  analysisProvider: string
  analysisModel: string
  analysis: GatewayAnalysisPayload
  embedding: GatewayEmbeddingPayload
}

export class AiGatewayService {
  static async testConnection(baseUrl: string): Promise<boolean> {
    let client: http.HttpRequest = http.createHttp()
    try {
      let response: http.HttpResponse = await client.request(
        AiGatewayService.endpoint(baseUrl, '/health'),
        {
          method: http.RequestMethod.GET,
          expectDataType: http.HttpDataType.STRING,
          usingCache: false,
          connectTimeout: 10000,
          readTimeout: 10000
        }
      )
      return response.responseCode === 200
    } finally {
      client.destroy()
    }
  }

  static async analyze(
    baseUrl: string,
    accessToken: string,
    fragment: FragmentItem
  ): Promise<AiGatewayResult> {
    let client: http.HttpRequest = http.createHttp()
    try {
      let response: http.HttpResponse = await client.request(
        AiGatewayService.endpoint(baseUrl, '/v1/fragments/analyze'),
        {
          method: http.RequestMethod.POST,
          header: {
            'Authorization': 'Bearer ' + accessToken,
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify({
            fragmentId: fragment.id,
            content: fragment.text,
            tag: fragment.tag === '未命名碎片' ? '' : fragment.tag,
            reminder: AiGatewayService.reminderCode(fragment.remind),
            locale: 'zh-CN',
            aiConsent: true
          }),
          expectDataType: http.HttpDataType.STRING,
          usingCache: false,
          connectTimeout: 20000,
          readTimeout: 25000
        }
      )
      if (response.responseCode !== 200 || typeof response.result !== 'string') {
        throw new Error('幕后整理服务暂时不可用')
      }
      let payload: GatewayResponsePayload =
        JSON.parse(response.result as string) as GatewayResponsePayload
      AiGatewayService.validatePayload(payload)
      return new AiGatewayResult(
        payload.requestId,
        payload.analysisProvider,
        payload.analysisModel,
        new AiTextAnalysis(
          payload.analysis.normalizedTag,
          payload.analysis.tone,
          payload.analysis.suggestedReminder,
          payload.analysis.summary
        ),
        new FragmentEmbedding(
          fragment.id,
          payload.embedding.model,
          payload.embedding.dimension,
          payload.embedding.vector,
          Date.now()
        )
      )
    } finally {
      client.destroy()
    }
  }

  static reminderFromCode(code: string, fallback: ReminderPreference): ReminderPreference {
    if (code === 'COMMUTE') {
      return ReminderPreference.COMMUTE
    }
    if (code === 'BEDTIME') {
      return ReminderPreference.BEDTIME
    }
    if (code === 'WEEKEND') {
      return ReminderPreference.WEEKEND
    }
    if (code === 'RANDOM') {
      return ReminderPreference.RANDOM
    }
    if (code === 'NONE') {
      return ReminderPreference.NONE
    }
    return fallback
  }

  private static reminderCode(value: ReminderPreference): string {
    if (value === ReminderPreference.COMMUTE) {
      return 'COMMUTE'
    }
    if (value === ReminderPreference.BEDTIME) {
      return 'BEDTIME'
    }
    if (value === ReminderPreference.WEEKEND) {
      return 'WEEKEND'
    }
    if (value === ReminderPreference.RANDOM) {
      return 'RANDOM'
    }
    return 'NONE'
  }

  private static endpoint(baseUrl: string, path: string): string {
    let normalized: string = baseUrl.trim()
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1)
    }
    if (!normalized.startsWith('https://')) {
      throw new Error('幕后整理地址必须使用 HTTPS')
    }
    return normalized + path
  }

  private static validatePayload(payload: GatewayResponsePayload): void {
    if (payload.requestId.length === 0 ||
      payload.analysisProvider !== 'deepseek' ||
      payload.analysisModel.length === 0 ||
      payload.analysis.normalizedTag.length === 0 ||
      payload.analysis.summary.length === 0 ||
      payload.embedding.model.length === 0 ||
      payload.embedding.dimension !== 1024 ||
      payload.embedding.vector.length !== payload.embedding.dimension) {
      throw new Error('幕后整理返回的数据不完整')
    }
    for (let i: number = 0; i < payload.embedding.vector.length; i++) {
      if (!Number.isFinite(payload.embedding.vector[i])) {
        throw new Error('幕后整理返回了无效向量')
      }
    }
  }
}
