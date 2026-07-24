import relationalStore from '@ohos.data.relationalStore'
import {
  AiAnalysisRecord,
  FragmentEmbedding
} from '../model/AiModel'
import { DatabaseManager } from './DatabaseManager'

export class AiRepository {
  private database: DatabaseManager

  constructor(database: DatabaseManager) {
    this.database = database
  }

  async loadEmbeddings(): Promise<FragmentEmbedding[]> {
    let result: FragmentEmbedding[] = []
    let resultSet: relationalStore.ResultSet = await this.database.getStore().querySql(
      `SELECT fragment_id, model, dimension, vector_json, updated_at
       FROM fragment_embeddings ORDER BY updated_at ASC`
    )
    try {
      while (resultSet.goToNextRow()) {
        let vector: number[] = JSON.parse(
          resultSet.getString(resultSet.getColumnIndex('vector_json'))
        ) as number[]
        result.push(new FragmentEmbedding(
          resultSet.getString(resultSet.getColumnIndex('fragment_id')),
          resultSet.getString(resultSet.getColumnIndex('model')),
          resultSet.getLong(resultSet.getColumnIndex('dimension')),
          vector,
          resultSet.getLong(resultSet.getColumnIndex('updated_at'))
        ))
      }
    } finally {
      resultSet.close()
    }
    return result
  }

  async grantConsent(fragmentId: string, consentedAtTimestamp: number): Promise<void> {
    await this.database.getStore().executeSql(
      `INSERT OR REPLACE INTO ai_processing_consents(
         fragment_id, provider_scope, consented_at, revoked_at
       ) VALUES(?, ?, ?, 0)`,
      [fragmentId, 'deepseek+dashscope', consentedAtTimestamp]
    )
  }

  async saveAnalysis(record: AiAnalysisRecord): Promise<void> {
    await this.database.getStore().executeSql(
      `INSERT OR REPLACE INTO ai_analyses(
         fragment_id, provider, model, normalized_tag, tone,
         reminder, summary, created_at
       ) VALUES(?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        record.fragmentId,
        record.provider,
        record.model,
        record.analysis.normalizedTag,
        record.analysis.tone,
        record.analysis.suggestedReminder,
        record.analysis.summary,
        record.createdAtTimestamp
      ]
    )
  }

  async saveEmbedding(embedding: FragmentEmbedding): Promise<void> {
    await this.database.getStore().executeSql(
      `INSERT OR REPLACE INTO fragment_embeddings(
         fragment_id, model, dimension, vector_json, updated_at
       ) VALUES(?, ?, ?, ?, ?)`,
      [
        embedding.fragmentId,
        embedding.model,
        embedding.dimension,
        JSON.stringify(embedding.vector),
        embedding.updatedAtTimestamp
      ]
    )
  }

  async deleteForFragment(fragmentId: string): Promise<void> {
    await this.database.getStore().executeSql(
      'DELETE FROM ai_analyses WHERE fragment_id = ?',
      [fragmentId]
    )
    await this.database.getStore().executeSql(
      'DELETE FROM fragment_embeddings WHERE fragment_id = ?',
      [fragmentId]
    )
    await this.database.getStore().executeSql(
      'DELETE FROM ai_processing_consents WHERE fragment_id = ?',
      [fragmentId]
    )
  }
}
