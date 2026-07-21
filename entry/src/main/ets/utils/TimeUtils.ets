export class TimeUtils {
  static formatDate(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const month: number = date.getMonth() + 1;
    const day: number = date.getDate();
    return `${month}月${day}日`;
  }

  static relativeLabel(timestamp: number): string {
    const diff: number = Date.now() - timestamp;
    const day: number = 1000 * 60 * 60 * 24;
    const days: number = Math.floor(diff / day);
    if (days <= 0) {
      return '今天';
    }
    if (days === 1) {
      return '昨天';
    }
    if (days < 30) {
      return `${days}天前`;
    }
    return this.formatDate(timestamp);
  }
}
