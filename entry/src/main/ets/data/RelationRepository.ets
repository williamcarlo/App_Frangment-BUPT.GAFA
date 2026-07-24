import relationalStore from '@ohos.data.relationalStore'
import { FragmentRelation } from '../model/FragmentModel'
import { DatabaseManager } from './DatabaseManager'

export class RelationRepository {
  private database: DatabaseManager

  constructor(database: DatabaseManager) {
    this.database = database
  }

  async loadAll(): Promise<FragmentRelation[]> {
    let result: FragmentRelation[] = []
    let resultSet: relationalStore.ResultSet = await this.database.getStore().querySql(
      'SELECT * FROM fragment_relations ORDER BY created_at ASC'
    )
    try {
      while (resultSet.goToNextRow()) {
        result.push(new FragmentRelation(
          resultSet.getString(resultSet.getColumnIndex('id')),
          resultSet.getString(resultSet.getColumnIndex('from_fragment_id')),
          resultSet.getString(resultSet.getColumnIndex('to_fragment_id')),
          resultSet.getString(resultSet.getColumnIndex('relation_type')),
          resultSet.getLong(resultSet.getColumnIndex('created_at'))
        ))
      }
    } finally {
      resultSet.close()
    }
    return result
  }

  async insert(relation: FragmentRelation): Promise<void> {
    let values: relationalStore.ValuesBucket = {
      id: relation.id,
      from_fragment_id: relation.fromFragmentId,
      to_fragment_id: relation.toFragmentId,
      relation_type: relation.relationType,
      created_at: relation.createdAtTimestamp
    }
    await this.database.getStore().insert('fragment_relations', values)
  }

  async insertOrReplace(relation: FragmentRelation): Promise<void> {
    await this.database.getStore().executeSql(
      `INSERT OR REPLACE INTO fragment_relations(
         id, from_fragment_id, to_fragment_id, relation_type, created_at
       ) VALUES(?, ?, ?, ?, ?)`,
      [
        relation.id,
        relation.fromFragmentId,
        relation.toFragmentId,
        relation.relationType,
        relation.createdAtTimestamp
      ]
    )
  }

  async deleteForFragment(fragmentId: string): Promise<void> {
    await this.database.getStore().executeSql(
      'DELETE FROM fragment_relations WHERE from_fragment_id = ? OR to_fragment_id = ?',
      [fragmentId, fragmentId]
    )
  }
}
