import relationalStore from '@ohos.data.relationalStore'
import { DatabaseManager } from './DatabaseManager'
import {
  FragmentItem,
  FragmentModerationStatus,
  FragmentVisibility,
  ReminderPreference
} from '../model/FragmentModel'

export class FragmentRepository {
  private database: DatabaseManager

  constructor(database: DatabaseManager) {
    this.database = database
  }

  async count(): Promise<number> {
    let resultSet: relationalStore.ResultSet = await this.database.getStore().querySql(
      'SELECT COUNT(*) AS total FROM fragments'
    )
    try {
      if (resultSet.goToNextRow()) {
        return resultSet.getLong(resultSet.getColumnIndex('total'))
      }
      return 0
    } finally {
      resultSet.close()
    }
  }

  async findById(fragmentId: string): Promise<FragmentItem | null> {
    let resultSet: relationalStore.ResultSet = await this.database.getStore().querySql(
      'SELECT * FROM fragments WHERE id = ? LIMIT 1',
      [fragmentId]
    )
    try {
      if (resultSet.goToNextRow()) {
        return this.mapFragment(resultSet)
      }
      return null
    } finally {
      resultSet.close()
    }
  }

  async loadActive(): Promise<FragmentItem[]> {
    return this.queryFragments(
      'SELECT * FROM fragments WHERE archived_at = 0 ORDER BY created_at ASC'
    )
  }

  async loadArchived(): Promise<FragmentItem[]> {
    return this.queryFragments(
      'SELECT * FROM fragments WHERE archived_at > 0 ORDER BY archived_at DESC'
    )
  }

  async insert(fragment: FragmentItem): Promise<void> {
    let values: relationalStore.ValuesBucket = {
      id: fragment.id,
      display_code: fragment.displayCode,
      tag: fragment.tag,
      content: fragment.text,
      tone: fragment.tone,
      reminder: fragment.remind,
      visibility: fragment.visibility,
      created_at: fragment.createdAtTimestamp,
      updated_at: fragment.updatedAtTimestamp,
      archived_at: fragment.archivedAtTimestamp,
      source_community_node_id: fragment.sourceCommunityNodeId,
      moderation_status: fragment.moderationStatus
    }
    await this.database.getStore().insert('fragments', values)
  }

  async update(fragment: FragmentItem): Promise<void> {
    await this.database.getStore().executeSql(
      `UPDATE fragments
       SET tag = ?, content = ?, tone = ?, reminder = ?, visibility = ?, updated_at = ?,
           source_community_node_id = ?, moderation_status = ?
       WHERE id = ?`,
      [
        fragment.tag,
        fragment.text,
        fragment.tone,
        fragment.remind,
        fragment.visibility,
        fragment.updatedAtTimestamp,
        fragment.sourceCommunityNodeId,
        fragment.moderationStatus,
        fragment.id
      ]
    )
  }

  async archive(fragmentId: string, archivedAtTimestamp: number): Promise<void> {
    await this.database.getStore().executeSql(
      'UPDATE fragments SET archived_at = ?, updated_at = ? WHERE id = ?',
      [archivedAtTimestamp, archivedAtTimestamp, fragmentId]
    )
  }

  async restore(fragmentId: string, updatedAtTimestamp: number): Promise<void> {
    await this.database.getStore().executeSql(
      'UPDATE fragments SET archived_at = 0, updated_at = ? WHERE id = ?',
      [updatedAtTimestamp, fragmentId]
    )
  }

  async deletePermanently(fragmentId: string): Promise<void> {
    await this.database.getStore().executeSql(
      'DELETE FROM fragments WHERE id = ?',
      [fragmentId]
    )
  }

  async revokeSharing(fragmentId: string, updatedAtTimestamp: number): Promise<void> {
    await this.database.getStore().executeSql(
      'UPDATE fragments SET visibility = ?, moderation_status = ?, updated_at = ? WHERE id = ?',
      [
        FragmentVisibility.REVOKED,
        FragmentModerationStatus.LOCAL_ONLY,
        updatedAtTimestamp,
        fragmentId
      ]
    )
  }

  private async queryFragments(sql: string): Promise<FragmentItem[]> {
    let result: FragmentItem[] = []
    let resultSet: relationalStore.ResultSet = await this.database.getStore().querySql(sql)
    try {
      while (resultSet.goToNextRow()) {
        result.push(this.mapFragment(resultSet))
      }
    } finally {
      resultSet.close()
    }
    return result
  }

  private mapFragment(resultSet: relationalStore.ResultSet): FragmentItem {
    let visibility: FragmentVisibility = this.parseVisibility(
      resultSet.getString(resultSet.getColumnIndex('visibility'))
    )
    let reminder: ReminderPreference = this.parseReminder(
      resultSet.getString(resultSet.getColumnIndex('reminder'))
    )
    let moderationStatus: FragmentModerationStatus = this.parseModerationStatus(
      resultSet.getString(resultSet.getColumnIndex('moderation_status'))
    )
    return new FragmentItem({
      id: resultSet.getString(resultSet.getColumnIndex('id')),
      displayCode: resultSet.getString(resultSet.getColumnIndex('display_code')),
      tag: resultSet.getString(resultSet.getColumnIndex('tag')),
      text: resultSet.getString(resultSet.getColumnIndex('content')),
      tone: resultSet.getString(resultSet.getColumnIndex('tone')),
      remind: reminder,
      visibility: visibility,
      createdAt: '',
      createdAtTimestamp: resultSet.getLong(resultSet.getColumnIndex('created_at')),
      updatedAtTimestamp: resultSet.getLong(resultSet.getColumnIndex('updated_at')),
      archivedAtTimestamp: resultSet.getLong(resultSet.getColumnIndex('archived_at')),
      sourceCommunityNodeId:
        resultSet.getString(resultSet.getColumnIndex('source_community_node_id')),
      moderationStatus: moderationStatus
    })
  }

  private parseVisibility(value: string): FragmentVisibility {
    if (value === FragmentVisibility.COMMUNITY) {
      return FragmentVisibility.COMMUNITY
    }
    if (value === FragmentVisibility.SPECIFIC_PEOPLE) {
      return FragmentVisibility.SPECIFIC_PEOPLE
    }
    if (value === FragmentVisibility.REVOKED) {
      return FragmentVisibility.REVOKED
    }
    return FragmentVisibility.PRIVATE
  }

  private parseReminder(value: string): ReminderPreference {
    if (value === ReminderPreference.COMMUTE) {
      return ReminderPreference.COMMUTE
    }
    if (value === ReminderPreference.BEDTIME) {
      return ReminderPreference.BEDTIME
    }
    if (value === ReminderPreference.WEEKEND) {
      return ReminderPreference.WEEKEND
    }
    if (value === ReminderPreference.RANDOM) {
      return ReminderPreference.RANDOM
    }
    return ReminderPreference.NONE
  }

  private parseModerationStatus(value: string): FragmentModerationStatus {
    if (value === FragmentModerationStatus.PENDING) {
      return FragmentModerationStatus.PENDING
    }
    if (value === FragmentModerationStatus.APPROVED) {
      return FragmentModerationStatus.APPROVED
    }
    if (value === FragmentModerationStatus.REJECTED) {
      return FragmentModerationStatus.REJECTED
    }
    return FragmentModerationStatus.LOCAL_ONLY
  }
}
