export class DateUtils {
  static readonly DAY_MS: number = 24 * 60 * 60 * 1000

  static localCalendarDay(timestamp: number): number {
    let date: Date = new Date(timestamp)
    return Math.floor(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) / DateUtils.DAY_MS)
  }

  static isSameLocalDay(leftTimestamp: number, rightTimestamp: number): boolean {
    return DateUtils.localCalendarDay(leftTimestamp) === DateUtils.localCalendarDay(rightTimestamp)
  }

  static relativeLabel(timestamp: number, nowTimestamp: number = Date.now()): string {
    let now: Date = new Date(nowTimestamp)
    let target: Date = new Date(timestamp)
    let dayDistance: number = DateUtils.localCalendarDay(nowTimestamp) - DateUtils.localCalendarDay(timestamp)
    if (dayDistance === 0 && timestamp <= nowTimestamp) {
      return '今天'
    }
    if (dayDistance === 1) {
      return '昨天'
    }
    if (dayDistance > 1 && dayDistance <= 6) {
      return dayDistance.toString() + ' 天前'
    }

    let monthAndDay: string = DateUtils.twoDigit(target.getMonth() + 1) + '.' + DateUtils.twoDigit(target.getDate())
    if (target.getFullYear() !== now.getFullYear()) {
      return target.getFullYear().toString() + '.' + monthAndDay
    }
    return monthAndDay
  }

  static twoDigit(value: number): string {
    return value < 10 ? '0' + value.toString() : value.toString()
  }
}
