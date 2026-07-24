export class AiTextAnalysis {
  normalizedTag: string = ''
  tone: string = 'slate'
  suggestedReminder: string = 'NONE'
  summary: string = ''

  constructor(
    normalizedTag: string,
    tone: string,
    suggestedReminder: string,
    summary: string
  ) {
    this.normalizedTag = normalizedTag
    this.tone = tone
    this.suggestedReminder = suggestedReminder
    this.summary = summary
  }
}

export class FragmentEmbedding {
  fragmentId: string = ''
  model: string = ''
  dimension: number = 0
  vector: number[] = []
  updatedAtTimestamp: number = 0

  constructor(
    fragmentId: string,
    model: string,
    dimension: number,
    vector: number[],
    updatedAtTimestamp: number
  ) {
    this.fragmentId = fragmentId
    this.model = model
    this.dimension = dimension
    this.vector = vector
    this.updatedAtTimestamp = updatedAtTimestamp
  }
}

export class AiAnalysisRecord {
  fragmentId: string = ''
  provider: string = 'deepseek'
  model: string = ''
  analysis: AiTextAnalysis = new AiTextAnalysis('', 'slate', 'NONE', '')
  createdAtTimestamp: number = 0

  constructor(
    fragmentId: string,
    provider: string,
    model: string,
    analysis: AiTextAnalysis,
    createdAtTimestamp: number
  ) {
    this.fragmentId = fragmentId
    this.provider = provider
    this.model = model
    this.analysis = analysis
    this.createdAtTimestamp = createdAtTimestamp
  }
}

export class AiGatewayResult {
  requestId: string = ''
  analysisProvider: string = 'deepseek'
  analysisModel: string = ''
  analysis: AiTextAnalysis = new AiTextAnalysis('', 'slate', 'NONE', '')
  embedding: FragmentEmbedding =
    new FragmentEmbedding('', '', 0, [], 0)

  constructor(
    requestId: string,
    analysisProvider: string,
    analysisModel: string,
    analysis: AiTextAnalysis,
    embedding: FragmentEmbedding
  ) {
    this.requestId = requestId
    this.analysisProvider = analysisProvider
    this.analysisModel = analysisModel
    this.analysis = analysis
    this.embedding = embedding
  }
}
