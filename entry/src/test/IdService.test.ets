import { describe, expect, it } from '@ohos/hypium'
import { IdService } from '../main/ets/utils/IdService'

export default function idServiceTest() {
  describe('IdService', () => {
    it('creates unique IDs even for the same timestamp', 0, () => {
      IdService.resetSequenceForTesting()
      let first: string = IdService.create('fragment', 1000)
      let second: string = IdService.create('fragment', 1000)
      expect(first === second).assertEqual(false)
      expect(first.indexOf('fragment_') === 0).assertEqual(true)
    })

  })
}
