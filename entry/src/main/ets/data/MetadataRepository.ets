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

  async allocateNextDisplayCode(): Promise<string> {
    let value: string = await this.getValue('next_display_code')
    let nextCode: number = Number(value)
    if (!Number.isInteger(nextCode) || nextCode < 1) {
      nextCode = await this.maximumDisplayCode() + 1
    }
    await this.putValue('next_display_code', (nextCode + 1).toString())
    if (nextCode < 10) {
      return '0' + nextCode.toString()
    }
    return nextCode.toString()
  }

  async maximumDisplayCode(): Promise<number> {
    let resultSet: relationalStore.ResultSet = await this.database.getStore().querySql(
      'SELECT COALESCE(MAX(CAST(display_code AS INTEGER)), 0) AS max_code FROM fragments'
    )
    try {
      if (resultSet.goToNextRow()) {
        return resultSet.getLong(resultSet.getColumnIndex('max_code'))
      }
      return 0
    } finally {
      resultSet.close()
    }
  }
}
