import relationalStore from '@ohos.data.relationalStore'
import { FragmentVisibility, SharingConsent } from '../model/FragmentModel'
import { DatabaseManager } from './DatabaseManager'

export class ConsentRepository {
  private database: DatabaseManager

  constructor(database: DatabaseManager) {
    this.database = database
  }

  async insert(consent: SharingConsent): Promise<void> {
    let values: relationalStore.ValuesBucket = {
      id: consent.id,
      fragment_id: consent.fragmentId,
      visibility: consent.visibility,
      specific_people: consent.specificPeople,
      consented_at: consent.consentedAtTimestamp,
      revoked_at: consent.revokedAtTimestamp
    }
    await this.database.getStore().insert(
      'sharing_consents',
      values,
      relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
    )
  }

  async revokeForFragment(fragmentId: string, revokedAtTimestamp: number): Promise<void> {
    await this.database.getStore().executeSql(
      `UPDATE sharing_consents
       SET visibility = ?, revoked_at = ?
       WHERE fragment_id = ? AND revoked_at = 0`,
      [FragmentVisibility.REVOKED, revokedAtTimestamp, fragmentId]
    )
  }

  async deleteForFragment(fragmentId: string): Promise<void> {
    await this.database.getStore().executeSql(
      'DELETE FROM sharing_consents WHERE fragment_id = ?',
      [fragmentId]
    )
  }
}
