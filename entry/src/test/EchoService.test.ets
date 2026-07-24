import { describe, expect, it } from '@ohos/hypium'
import { EchoRecord } from '../main/ets/model/EchoModel'
import {
  FragmentItem,
  FragmentVisibility,
  ReminderPreference
} from '../main/ets/model/FragmentModel'
import { EchoService } from '../main/ets/service/EchoService'
import { DateUtils } from '../main/ets/utils/DateUtils'

function fragment(
  id: string,
  reminder: ReminderPreference,
  createdAtTimestamp: number
): FragmentItem {
  return new FragmentItem({
    id: id,
    displayCode: id,
    tag: '测试',
    text: '测试内容',
    tone: 'self',
    remind: reminder,
    visibility: FragmentVisibility.PRIVATE,
    createdAtTimestamp: createdAtTimestamp
  })
}

export default function echoServiceTest() {
  describe('EchoService', () => {
    it('excludes archived and sleeping fragments', 0, () => {
      let nowTimestamp: number = new Date(2026, 6, 25, 12, 0, 0).getTime()
      let archived: FragmentItem = fragment(
        'archived',
        ReminderPreference.RANDOM,
        nowTimestamp - 2 * DateUtils.DAY_MS
      )
      archived.archivedAtTimestamp = nowTimestamp - 1000
      let sleeping: FragmentItem = fragment(
        'sleeping',
        ReminderPreference.NONE,
        nowTimestamp - 2 * DateUtils.DAY_MS
      )
      expect(EchoService.selectCandidate(
        [archived, sleeping],
        [],
        nowTimestamp
      ) === null).assertEqual(true)
    })

    it('limits resurfacing to one item per local day', 0, () => {
      let nowTimestamp: number = new Date(2026, 6, 25, 12, 0, 0).getTime()
      let candidate: FragmentItem = fragment(
        'candidate',
        ReminderPreference.RANDOM,
        nowTimestamp - 2 * DateUtils.DAY_MS
      )
      let record: EchoRecord =
        new EchoRecord('echo', 'other', nowTimestamp - 1000, 0, 0, '今日已出现')
      expect(EchoService.selectCandidate(
        [candidate],
        [record],
        nowTimestamp
      ) === null).assertEqual(true)
    })

    it('keeps deterministic random selection stable during one day', 0, () => {
      let nowTimestamp: number = new Date(2026, 6, 25, 12, 0, 0).getTime()
      let candidates: FragmentItem[] = [
        fragment('candidate-a', ReminderPreference.RANDOM, nowTimestamp - 5 * DateUtils.DAY_MS),
        fragment('candidate-b', ReminderPreference.RANDOM, nowTimestamp - 4 * DateUtils.DAY_MS),
        fragment('candidate-c', ReminderPreference.RANDOM, nowTimestamp - 3 * DateUtils.DAY_MS)
      ]
      let first = EchoService.selectCandidate(candidates, [], nowTimestamp)
      let second = EchoService.selectCandidate(candidates, [], nowTimestamp + 1000)
      expect(first?.fragmentId).assertEqual(second?.fragmentId)
    })

    it('allows daily deterministic selection to rotate', 0, () => {
      let firstDay: number = new Date(2026, 6, 25, 12, 0, 0).getTime()
      let secondDay: number = new Date(2026, 6, 26, 12, 0, 0).getTime()
      let candidates: FragmentItem[] = [
        fragment('candidate-a', ReminderPreference.RANDOM, firstDay - 5 * DateUtils.DAY_MS),
        fragment('candidate-b', ReminderPreference.RANDOM, firstDay - 5 * DateUtils.DAY_MS),
        fragment('candidate-c', ReminderPreference.RANDOM, firstDay - 5 * DateUtils.DAY_MS)
      ]
      let first = EchoService.selectCandidate(candidates, [], firstDay)
      let second = EchoService.selectCandidate(candidates, [], secondDay)
      expect(first?.fragmentId === second?.fragmentId).assertEqual(false)
    })

    it('honors cooldown and dismissed-until constraints', 0, () => {
      let nowTimestamp: number = new Date(2026, 6, 25, 12, 0, 0).getTime()
      let candidate: FragmentItem = fragment(
        'candidate',
        ReminderPreference.RANDOM,
        nowTimestamp - 10 * DateUtils.DAY_MS
      )
      let cooldown: EchoRecord = new EchoRecord(
        'cooldown',
        candidate.id,
        nowTimestamp - DateUtils.DAY_MS,
        0,
        0,
        'recent'
      )
      let dismissed: EchoRecord = new EchoRecord(
        'dismissed',
        candidate.id,
        0,
        0,
        nowTimestamp + DateUtils.DAY_MS,
        'later'
      )
      expect(EchoService.selectCandidate([candidate], [cooldown], nowTimestamp) === null)
        .assertEqual(true)
      expect(EchoService.selectCandidate([candidate], [dismissed], nowTimestamp) === null)
        .assertEqual(true)
    })
  })
}
