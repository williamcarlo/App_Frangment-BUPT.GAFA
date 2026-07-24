import { CommunityNode, CommunitySaveRecord } from '../model/CommunityModel'
import {
  FragmentItem,
  FragmentModerationStatus,
  FragmentVisibility,
  ReminderPreference
} from '../model/FragmentModel'
import { IdService } from '../utils/IdService'

export class CommunityService {
  static canUseAsCommunityRoot(fragment: FragmentItem): boolean {
    return !fragment.archived && fragment.visibility === FragmentVisibility.COMMUNITY
  }

  static findSavedRecord(records: CommunitySaveRecord[], sourceCommunityNodeId: string): CommunitySaveRecord | null {
    for (let i: number = 0; i < records.length; i++) {
      if (records[i].sourceCommunityNodeId === sourceCommunityNodeId) {
        return records[i]
      }
    }
    return null
  }

  static createPrivateCopy(
    node: CommunityNode,
    nowTimestamp: number = Date.now()
  ): FragmentItem {
    return new FragmentItem({
      id: IdService.create('fragment', nowTimestamp),
      displayCode: '',
      tag: node.tag,
      text: node.text,
      tone: node.tone,
      remind: ReminderPreference.WEEKEND,
      visibility: FragmentVisibility.PRIVATE,
      createdAt: '今天',
      createdAtTimestamp: nowTimestamp,
      updatedAtTimestamp: nowTimestamp,
      sourceCommunityNodeId: node.key,
      moderationStatus: FragmentModerationStatus.LOCAL_ONLY
    })
  }
}
