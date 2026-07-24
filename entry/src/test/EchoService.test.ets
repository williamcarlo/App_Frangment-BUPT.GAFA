import { describe, expect, it } from '@ohos/hypium'
import { EchoRecord } from '../main/ets/model/EchoModel'
import { FragmentItem, ReminderPreference } from '../main/ets/model/FragmentModel'
import { EchoService } from '../main/ets/service/EchoService'
import { DateUtils } from '../main/ets/utils/DateUtils'

export default function echoServiceTest() {
  describe('EchoService', () => {
    it('excludes archived and sleeping fragments', 0, () => {
      let nowTimestamp: number = new Date(2026, 6, 25, 12, 0, 0).getTime()
      let archived: FragmentItem = new FragmentItem(
        'archived',
        '归档',
        '不应出现',
        'self',
        ReminderPreference.RANDOM,
        false,
        '',
        nowTimestamp - 2 * DateUtils.DAY_MS
      )
      archived.archivedAtTimestamp = nowTimestamp - 1000
      let sleeping: FragmentItem = new FragmentItem(
        'sleeping',
        '沉睡',
        '不应出现',
        'self',
        ReminderPreference.NONE,
        false,
        '',
        nowTimestamp - 2 * DateUtils.DAY_MS
      )
      expect(EchoService.selectCandidate([archived, sleeping], [], nowTimestamp) === null).assertEqual(true)
    })

    it('limits resurfacing to one item per local day', 0, () => {
      let nowTimestamp: number = new Date(2026, 6, 25, 12, 0, 0).getTime()
      let fragment: FragmentItem = new FragmentItem(
        'candidate',
        '随机',
        '可以出现',
        'self',
        ReminderPreference.RANDOM,
        false,
        '',
        nowTimestamp - 2 * DateUtils.DAY_MS
      )
      let record: EchoRecord = new EchoRecord('echo', 'other', nowTimestamp - 1000, 0, 0, '今日已出现')
      expect(EchoService.selectCandidate([fragment], [record], nowTimestamp) === null).assertEqual(true)
    })

    it('returns a reason for an eligible candidate', 0, () => {
      let nowTimestamp: number = new Date(2026, 6, 25, 12, 0, 0).getTime()
      let fragment: FragmentItem = new FragmentItem(
        'candidate',
        '随机',
        '可以出现',
        'self',
        ReminderPreference.RANDOM,
        false,
        '',
        nowTimestamp - 2 * DateUtils.DAY_MS
      )
      let candidate = EchoService.selectCandidate([fragment], [], nowTimestamp)
      expect(candidate === null).assertEqual(false)
      expect(candidate?.fragmentId).assertEqual('candidate')
    })
  })
}
