import relationalStore from '@ohos.data.relationalStore'
import { FragmentVisibility, SharingConsent } from '../model/FragmentModel'
import { DatabaseManager } from './DatabaseManager'

export class ConsentRepository {
  private database: DatabaseManager

  constructor(database: DatabaseManager) {
    this.database = database
  }

  async recordTransition(consent: SharingConsent): Promise<void> {
    await this.database.getStore().executeSql(
      `UPDATE sharing_consents
       SET is_active = 0, superseded_at = ?
       WHERE fragment_id = ? AND is_active = 1`,
      [consent.consentedAtTimestamp, consent.fragmentId]
    )
    let values: relationalStore.ValuesBucket = {
      id: consent.id,
      fragment_id: consent.fragmentId,
      visibility: consent.visibility,
      specific_people: consent.specificPeople,
      consented_at: consent.consentedAtTimestamp,
      revoked_at: consent.revokedAtTimestamp,
      superseded_at: consent.supersededAtTimestamp,
      is_active: consent.isActive ? 1 : 0
    }
    await this.database.getStore().insert('sharing_consents', values)
  }

  async loadForFragment(fragmentId: string): Promise<SharingConsent[]> {
    let result: SharingConsent[] = []
    let resultSet: relationalStore.ResultSet = await this.database.getStore().querySql(
      `SELECT * FROM sharing_consents
       WHERE fragment_id = ?
       ORDER BY consented_at ASC, rowid ASC`,
      [fragmentId]
    )
    try {
      while (resultSet.goToNextRow()) {
        result.push(new SharingConsent(
          resultSet.getString(resultSet.getColumnIndex('id')),
          resultSet.getString(resultSet.getColumnIndex('fragment_id')),
          this.parseVisibility(resultSet.getString(resultSet.getColumnIndex('visibility'))),
          resultSet.getString(resultSet.getColumnIndex('specific_people')),
          resultSet.getLong(resultSet.getColumnIndex('consented_at')),
          resultSet.getLong(resultSet.getColumnIndex('revoked_at')),
          resultSet.getLong(resultSet.getColumnIndex('superseded_at')),
          resultSet.getLong(resultSet.getColumnIndex('is_active')) === 1
        ))
      }
    } finally {
      resultSet.close()
    }
    return result
  }

  async deleteForFragment(fragmentId: string): Promise<void> {
    await this.database.getStore().executeSql(
      'DELETE FROM sharing_consents WHERE fragment_id = ?',
      [fragmentId]
    )
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
}
