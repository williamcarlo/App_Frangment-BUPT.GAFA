import { ReminderPreference } from '../model/FragmentModel';

export interface ReminderPlan {
  title: string;
  description: string;
  preferredHour: number;
}

export class ReminderService {
  static describe(preference: ReminderPreference): ReminderPlan {
    if (preference === ReminderPreference.COMMUTE) {
      return {
        title: '通勤时回响',
        description: '在工作日早晚通勤时段低频出现',
        preferredHour: 8
      };
    }
    if (preference === ReminderPreference.BEFORE_SLEEP) {
      return {
        title: '睡前回响',
        description: '在用户允许的晚间时段出现',
        preferredHour: 22
      };
    }
    if (preference === ReminderPreference.WEEKEND) {
      return {
        title: '周末回响',
        description: '在周末相对从容的时间出现',
        preferredHour: 10
      };
    }
    if (preference === ReminderPreference.RANDOM) {
      return {
        title: '随机回响',
        description: '由用户主动开启的低频随机提醒',
        preferredHour: 15
      };
    }
    return {
      title: '继续沉睡',
      description: '不会主动提醒，可随时在碎片盒中找回',
      preferredHour: 12
    };
  }
}
