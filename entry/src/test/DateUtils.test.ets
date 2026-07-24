import { describe, expect, it } from '@ohos/hypium'
import { DateUtils } from '../main/ets/utils/DateUtils'

export default function dateUtilsTest() {
  describe('DateUtils', () => {
    it('uses local calendar boundaries around midnight', 0, () => {
      let yesterday: number = new Date(2026, 6, 24, 23, 59, 0).getTime()
      let today: number = new Date(2026, 6, 25, 0, 1, 0).getTime()
      expect(DateUtils.relativeLabel(yesterday, today)).assertEqual('昨天')
    })

    it('does not label a future timestamp as today', 0, () => {
      let nowTimestamp: number = new Date(2026, 6, 25, 9, 0, 0).getTime()
      let futureTimestamp: number = new Date(2026, 6, 25, 18, 0, 0).getTime()
      expect(DateUtils.relativeLabel(futureTimestamp, nowTimestamp)).assertEqual('07.25')
    })
  })
}
