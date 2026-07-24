import relationalStore from '@ohos.data.relationalStore'
import { DatabaseManager } from './DatabaseManager'

export class MetadataRepository {
  private database: DatabaseManager

  constructor(database: DatabaseManager) {
    this.database = database
  }

  async getValue(key: string): Promise<string> {
    let resultSet: relationalStore.ResultSet = await this.database.getStore().querySql(
      'SELECT meta_value FROM app_metadata WHERE meta_key = ? LIMIT 1',
      [key]
    )
    try {
      if (resultSet.goToNextRow()) {
        return resultSet.getString(resultSet.getColumnIndex('meta_value'))
      }
      return ''
    } finally {
      resultSet.close()
    }
  }

  async putValue(key: string, value: string): Promise<void> {
    await this.database.getStore().executeSql(
      'INSERT OR REPLACE INTO app_metadata(meta_key, meta_value) VALUES(?, ?)',
      [key, value]
    )
  }
}
