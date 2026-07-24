import { describe, expect, it } from '@ohos/hypium'
import { StableCommunityNodeIdService } from '../main/ets/service/StableCommunityNodeIdService'

export default function stableCommunityNodeIdServiceTest() {
  describe('StableCommunityNodeIdService', () => {
    it('keeps logical node identity independent from expansion order', 0, () => {
      let root: string = 'fragment-root'
      let parent: string = StableCommunityNodeIdService.create(
        root, '', 'root', '当前碎片', 'local'
      )
      let firstOrder: string = StableCommunityNodeIdService.create(
        root, parent, 'similar', '相同的社区内容', 'anonymous'
      )
      StableCommunityNodeIdService.create(
        root, parent, 'opposite', '另一个节点', 'boxer'
      )
      let secondOrder: string = StableCommunityNodeIdService.create(
        root, parent, 'similar', '相同的社区内容', 'anonymous'
      )
      expect(firstOrder).assertEqual(secondOrder)
    })
  })
}
