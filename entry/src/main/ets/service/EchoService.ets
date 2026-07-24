import { EchoCandidate, EchoRecord } from '../model/EchoModel'
import { FragmentItem, ReminderPreference } from '../model/FragmentModel'
import { DateUtils } from '../utils/DateUtils'

export class EchoService {
  static readonly MINIMUM_AGE_MS: number = 12 * 60 * 60 * 1000
  static readonly FRAGMENT_COOLDOWN_MS: number = 7 * DateUtils.DAY_MS

  static selectCandidate(
    fragments: FragmentItem[],
    records: EchoRecord[],
    nowTimestamp: number = Date.now()
  ): EchoCandidate | null {
    if (EchoService.hasSurfacedToday(records, nowTimestamp)) {
      return null
    }

    let candidates: FragmentItem[] = []
    for (let i: number = 0; i < fragments.length; i++) {
      let fragment: FragmentItem = fragments[i]
      if (EchoService.isEligible(fragment, records, nowTimestamp)) {
        candidates.push(fragment)
      }
    }
    if (candidates.length === 0) {
      return null
    }

    let selected: FragmentItem =
      EchoService.selectDeterministically(candidates, records, nowTimestamp)
    return new EchoCandidate(selected.id, EchoService.reasonFor(selected.remind))
  }

  private static selectDeterministically(
    candidates: FragmentItem[],
    records: EchoRecord[],
    nowTimestamp: number
  ): FragmentItem {
    let highestWaitScore: number = -1
    let fairest: FragmentItem[] = []
    for (let i: number = 0; i < candidates.length; i++) {
      let score: number = EchoService.waitScore(candidates[i].id, records, nowTimestamp)
      if (score > highestWaitScore) {
        highestWaitScore = score
        fairest = [candidates[i]]
      } else if (score === highestWaitScore) {
        fairest.push(candidates[i])
      }
    }
    fairest.sort((first: FragmentItem, second: FragmentItem) => first.id.localeCompare(second.id))
    let dayKey: string = EchoService.localDayKey(nowTimestamp)
    let identitySet: string = ''
    for (let i: number = 0; i < fairest.length; i++) {
      identitySet += fairest[i].id + '\n'
    }
    let selectedIndex: number = EchoService.hash(dayKey + '\n' + identitySet) % fairest.length
    return fairest[selectedIndex]
  }

  private static waitScore(
    fragmentId: string,
    records: EchoRecord[],
    nowTimestamp: number
  ): number {
    let latestSurfacedAt: number = 0
    for (let i: number = 0; i < records.length; i++) {
      if (records[i].fragmentId === fragmentId &&
        records[i].surfacedAtTimestamp > latestSurfacedAt) {
        latestSurfacedAt = records[i].surfacedAtTimestamp
      }
    }
    if (latestSurfacedAt === 0) {
      return 30
    }
    return Math.min(29, Math.floor((nowTimestamp - latestSurfacedAt) / DateUtils.DAY_MS))
  }

  private static localDayKey(nowTimestamp: number): string {
    let date: Date = new Date(nowTimestamp)
    return date.getFullYear().toString() + '-' +
      (date.getMonth() + 1).toString() + '-' + date.getDate().toString()
  }

  private static hash(value: string): number {
    let hashValue: number = 0
    for (let i: number = 0; i < value.length; i++) {
      hashValue = (hashValue * 31 + value.charCodeAt(i)) >>> 0
    }
    return hashValue
  }

  static isEligible(fragment: FragmentItem, records: EchoRecord[], nowTimestamp: number): boolean {
    if (fragment.archived || fragment.remind === ReminderPreference.NONE) {
      return false
    }
    if (nowTimestamp - fragment.createdAtTimestamp < EchoService.MINIMUM_AGE_MS) {
      return false
    }
    if (!EchoService.matchesWindow(fragment.remind, nowTimestamp)) {
      return false
    }
    for (let i: number = 0; i < records.length; i++) {
      let record: EchoRecord = records[i]
      if (record.fragmentId !== fragment.id) {
        continue
      }
      if (record.dismissedUntilTimestamp > nowTimestamp) {
        return false
      }
      if (record.surfacedAtTimestamp > 0 &&
        nowTimestamp - record.surfacedAtTimestamp < EchoService.FRAGMENT_COOLDOWN_MS) {
        return false
      }
    }
    return true
  }

  static hasSurfacedToday(records: EchoRecord[], nowTimestamp: number): boolean {
    for (let i: number = 0; i < records.length; i++) {
      if (records[i].surfacedAtTimestamp > 0 &&
        DateUtils.isSameLocalDay(records[i].surfacedAtTimestamp, nowTimestamp)) {
        return true
      }
    }
    return false
  }

  static matchesWindow(preference: ReminderPreference, nowTimestamp: number): boolean {
    let now: Date = new Date(nowTimestamp)
    let hour: number = now.getHours()
    let weekday: number = now.getDay()
    if (preference === ReminderPreference.COMMUTE) {
      return weekday >= 1 && weekday <= 5 && ((hour >= 7 && hour <= 10) || (hour >= 17 && hour <= 20))
    }
    if (preference === ReminderPreference.BEDTIME) {
      return hour >= 21 || hour <= 1
    }
    if (preference === ReminderPreference.WEEKEND) {
      return (weekday === 0 || weekday === 6) && hour >= 9 && hour <= 22
    }
    if (preference === ReminderPreference.RANDOM) {
      return hour >= 10 && hour <= 20
    }
    return false
  }

  static reasonFor(preference: ReminderPreference): string {
    if (preference === ReminderPreference.COMMUTE) {
      return '通勤时段，捡回一张旧碎片'
    }
    if (preference === ReminderPreference.BEDTIME) {
      return '睡前安静时刻，看看当时的自己'
    }
    if (preference === ReminderPreference.WEEKEND) {
      return '周末有一点余裕，适合重新看见'
    }
    return '今天随机浮起的一张旧碎片'
  }
}
