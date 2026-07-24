import relationalStore from '@ohos.data.relationalStore'
import { CommunitySaveRecord } from '../model/CommunityModel'
import { DatabaseManager } from './DatabaseManager'

export class CommunitySaveRepository {
  private database: DatabaseManager

  constructor(database: DatabaseManager) {
    this.database = database
  }

  async loadAll(): Promise<CommunitySaveRecord[]> {
    let records: CommunitySaveRecord[] = []
    let resultSet: relationalStore.ResultSet = await this.database.getStore().querySql(
      'SELECT * FROM community_saves ORDER BY saved_at DESC'
    )
    try {
      while (resultSet.goToNextRow()) {
        records.push(new CommunitySaveRecord(
          resultSet.getString(resultSet.getColumnIndex('source_community_node_id')),
          resultSet.getString(resultSet.getColumnIndex('saved_fragment_id')),
          resultSet.getLong(resultSet.getColumnIndex('saved_at'))
        ))
      }
    } finally {
      resultSet.close()
    }
    return records
  }

  async findBySource(sourceCommunityNodeId: string): Promise<CommunitySaveRecord | null> {
    let resultSet: relationalStore.ResultSet = await this.database.getStore().querySql(
      'SELECT * FROM community_saves WHERE source_community_node_id = ? LIMIT 1',
      [sourceCommunityNodeId]
    )
    try {
      if (resultSet.goToNextRow()) {
        return new CommunitySaveRecord(
          resultSet.getString(resultSet.getColumnIndex('source_community_node_id')),
          resultSet.getString(resultSet.getColumnIndex('saved_fragment_id')),
          resultSet.getLong(resultSet.getColumnIndex('saved_at'))
        )
      }
      return null
    } finally {
      resultSet.close()
    }
  }

  async insert(record: CommunitySaveRecord): Promise<void> {
    let values: relationalStore.ValuesBucket = {
      source_community_node_id: record.sourceCommunityNodeId,
      saved_fragment_id: record.savedFragmentId,
      saved_at: record.savedAtTimestamp
    }
    await this.database.getStore().insert('community_saves', values)
  }

  async deleteForFragment(fragmentId: string): Promise<void> {
    await this.database.getStore().executeSql(
      'DELETE FROM community_saves WHERE saved_fragment_id = ?',
      [fragmentId]
    )
  }
}
