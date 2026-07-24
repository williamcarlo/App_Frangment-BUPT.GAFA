import { describe, expect, it } from '@ohos/hypium'
import { CommunityNode, CommunitySaveRecord } from '../main/ets/model/CommunityModel'
import { FragmentVisibility } from '../main/ets/model/FragmentModel'
import { CommunityService } from '../main/ets/service/CommunityService'

export default function communityServiceTest() {
  describe('CommunityService', () => {
    it('creates a private copy with stable source metadata', 0, () => {
      let node: CommunityNode = new CommunityNode(
        'community-1',
        'root',
        '相似经验',
        '边界',
        '匿名',
        '相似',
        '社区内容',
        'slate',
        0,
        0,
        0,
        0
      )
      let copy = CommunityService.createPrivateCopy(node, 1000)
      expect(copy.visibility).assertEqual(FragmentVisibility.PRIVATE)
      expect(copy.sourceCommunityNodeId).assertEqual('community-1')
      expect(copy.displayCode).assertEqual('')
    })

    it('detects a previously saved community node', 0, () => {
      let records: CommunitySaveRecord[] = [
        new CommunitySaveRecord('community-1', 'fragment-1', 1000)
      ]
      let result = CommunityService.findSavedRecord(records, 'community-1')
      expect(result === null).assertEqual(false)
      expect(result?.savedFragmentId).assertEqual('fragment-1')
    })
  })
}
