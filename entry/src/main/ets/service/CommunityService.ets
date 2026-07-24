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
    displayCode: string,
    nowTimestamp: number = Date.now()
  ): FragmentItem {
    return new FragmentItem(
      IdService.create('fragment', nowTimestamp),
      node.tag,
      node.text,
      node.tone,
      ReminderPreference.WEEKEND,
      false,
      '今天',
      nowTimestamp,
      displayCode,
      FragmentVisibility.PRIVATE,
      nowTimestamp,
      0,
      node.key,
      FragmentModerationStatus.LOCAL_ONLY
    )
  }
}
