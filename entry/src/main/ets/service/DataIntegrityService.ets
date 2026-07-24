import relationalStore from '@ohos.data.relationalStore'
import { DatabaseManager } from '../data/DatabaseManager'

export class IntegrityReport {
  checkedAt: number = 0
  repairedCount: number = 0
  warningCodes: string[] = []

  constructor(checkedAt: number = Date.now()) {
    this.checkedAt = checkedAt
  }
}

export class DataIntegrityService {
  private database: DatabaseManager

  constructor(database: DatabaseManager) {
    this.database = database
  }

  async inspectAndRepair(nowTimestamp: number = Date.now()): Promise<IntegrityReport> {
    let report: IntegrityReport = new IntegrityReport(nowTimestamp)
    let store: relationalStore.RdbStore = this.database.getStore()
    store.beginTransaction()
    try {
      report.repairedCount += await this.removeOrphans(
        store,
        `SELECT COUNT(*) AS total FROM fragment_relations
         WHERE from_fragment_id NOT IN (SELECT id FROM fragments)
            OR to_fragment_id NOT IN (SELECT id FROM fragments)`,
        `DELETE FROM fragment_relations
         WHERE from_fragment_id NOT IN (SELECT id FROM fragments)
            OR to_fragment_id NOT IN (SELECT id FROM fragments)`,
        'ORPHAN_RELATION',
        report
      )
      report.repairedCount += await this.removeOrphans(
        store,
        'SELECT COUNT(*) AS total FROM echo_records WHERE fragment_id NOT IN (SELECT id FROM fragments)',
        'DELETE FROM echo_records WHERE fragment_id NOT IN (SELECT id FROM fragments)',
        'ORPHAN_ECHO',
        report
      )
      report.repairedCount += await this.removeOrphans(
        store,
        `SELECT COUNT(*) AS total FROM sharing_consents
         WHERE fragment_id NOT IN (SELECT id FROM fragments)`,
        'DELETE FROM sharing_consents WHERE fragment_id NOT IN (SELECT id FROM fragments)',
        'ORPHAN_CONSENT',
        report
      )
      report.repairedCount += await this.removeOrphans(
        store,
        `SELECT COUNT(*) AS total FROM community_saves
         WHERE saved_fragment_id NOT IN (SELECT id FROM fragments)`,
        'DELETE FROM community_saves WHERE saved_fragment_id NOT IN (SELECT id FROM fragments)',
        'ORPHAN_COMMUNITY_SAVE',
        report
      )

      let duplicateActiveCount: number = await this.count(
        store,
        `SELECT COALESCE(SUM(total - 1), 0) AS total FROM (
           SELECT COUNT(*) AS total FROM sharing_consents
           WHERE is_active = 1 GROUP BY fragment_id HAVING COUNT(*) > 1
         )`
      )
      if (duplicateActiveCount > 0) {
        report.warningCodes.push('MULTIPLE_ACTIVE_CONSENT')
        await store.executeSql(
          `UPDATE sharing_consents
           SET is_active = 0, superseded_at = ?
           WHERE is_active = 1 AND rowid NOT IN (
             SELECT MAX(rowid) FROM sharing_consents
             WHERE is_active = 1 GROUP BY fragment_id
           )`,
          [nowTimestamp]
        )
        report.repairedCount += duplicateActiveCount
      }

      let duplicateCodeGroups: number = await this.count(
        store,
        `SELECT COUNT(*) AS total FROM (
           SELECT display_code FROM fragments
           GROUP BY display_code HAVING COUNT(*) > 1
         )`
      )
      if (duplicateCodeGroups > 0) {
        report.warningCodes.push('DUPLICATE_DISPLAY_CODE')
      }

      let maximumCode: number = await this.scalar(
        store,
        'SELECT COALESCE(MAX(CAST(display_code AS INTEGER)), 0) AS value FROM fragments',
        'value'
      )
      let nextCodeText: string = await this.metadataValue(store, 'next_display_code')
      let nextCode: number = Number(nextCodeText)
      if (!Number.isInteger(nextCode) || nextCode <= maximumCode) {
        report.warningCodes.push('NEXT_DISPLAY_CODE_ADVANCED')
        await store.executeSql(
          `INSERT OR REPLACE INTO app_metadata(meta_key, meta_value)
           VALUES('next_display_code', ?)`,
          [(maximumCode + 1).toString()]
        )
        report.repairedCount++
      }
      store.commit()
      return report
    } catch (error) {
      store.rollBack()
      throw new Error('DATA_INTEGRITY_CHECK_FAILED')
    }
  }

  private async removeOrphans(
    store: relationalStore.RdbStore,
    countSql: string,
    deleteSql: string,
    warningCode: string,
    report: IntegrityReport
  ): Promise<number> {
    let orphanCount: number = await this.count(store, countSql)
    if (orphanCount > 0) {
      report.warningCodes.push(warningCode)
      await store.executeSql(deleteSql)
    }
    return orphanCount
  }

  private async count(store: relationalStore.RdbStore, sql: string): Promise<number> {
    return this.scalar(store, sql, 'total')
  }

  private async scalar(
    store: relationalStore.RdbStore,
    sql: string,
    columnName: string
  ): Promise<number> {
    let resultSet: relationalStore.ResultSet = await store.querySql(sql)
    try {
      if (resultSet.goToNextRow()) {
        return resultSet.getLong(resultSet.getColumnIndex(columnName))
      }
      return 0
    } finally {
      resultSet.close()
    }
  }

  private async metadataValue(
    store: relationalStore.RdbStore,
    key: string
  ): Promise<string> {
    let resultSet: relationalStore.ResultSet = await store.querySql(
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
}
