import relationalStore from '@ohos.data.relationalStore'
import { EchoRecord } from '../model/EchoModel'
import { DatabaseManager } from './DatabaseManager'

export class EchoRepository {
  private database: DatabaseManager

  constructor(database: DatabaseManager) {
    this.database = database
  }

  async loadAll(): Promise<EchoRecord[]> {
    let records: EchoRecord[] = []
    let resultSet: relationalStore.ResultSet = await this.database.getStore().querySql(
      'SELECT * FROM echo_records ORDER BY surfaced_at DESC'
    )
    try {
      while (resultSet.goToNextRow()) {
        records.push(new EchoRecord(
          resultSet.getString(resultSet.getColumnIndex('id')),
          resultSet.getString(resultSet.getColumnIndex('fragment_id')),
          resultSet.getLong(resultSet.getColumnIndex('surfaced_at')),
          resultSet.getLong(resultSet.getColumnIndex('opened_at')),
          resultSet.getLong(resultSet.getColumnIndex('dismissed_until')),
          resultSet.getString(resultSet.getColumnIndex('reason'))
        ))
      }
    } finally {
      resultSet.close()
    }
    return records
  }

  async insert(record: EchoRecord): Promise<void> {
    let values: relationalStore.ValuesBucket = {
      id: record.id,
      fragment_id: record.fragmentId,
      surfaced_at: record.surfacedAtTimestamp,
      opened_at: record.openedAtTimestamp,
      dismissed_until: record.dismissedUntilTimestamp,
      reason: record.reason
    }
    await this.database.getStore().insert('echo_records', values)
  }

  async markOpened(recordId: string, openedAtTimestamp: number): Promise<void> {
    await this.database.getStore().executeSql(
      'UPDATE echo_records SET opened_at = ? WHERE id = ?',
      [openedAtTimestamp, recordId]
    )
  }

  async dismiss(recordId: string, dismissedUntilTimestamp: number): Promise<void> {
    await this.database.getStore().executeSql(
      'UPDATE echo_records SET dismissed_until = ? WHERE id = ?',
      [dismissedUntilTimestamp, recordId]
    )
  }

  async deleteForFragment(fragmentId: string): Promise<void> {
    await this.database.getStore().executeSql(
      'DELETE FROM echo_records WHERE fragment_id = ?',
      [fragmentId]
    )
  }
}
