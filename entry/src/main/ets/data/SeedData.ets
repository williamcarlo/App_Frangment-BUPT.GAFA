import {
  FragmentItem,
  FragmentModerationStatus,
  FragmentRelation,
  FragmentVisibility,
  ReminderPreference
} from '../model/FragmentModel'
import { DateUtils } from '../utils/DateUtils'

export class SeedData {
  static fragments(nowTimestamp: number = Date.now()): FragmentItem[] {
    return [
      SeedData.fragment('seed-fragment-01', '01', '通勤观察',
        '人在很累的时候，不是不想社交，而是不想解释自己。', 'memory',
        ReminderPreference.COMMUTE, FragmentVisibility.COMMUNITY,
        nowTimestamp - 6 * DateUtils.DAY_MS, '07.18'),
      SeedData.fragment('seed-fragment-02', '02', '复盘经验',
        '临时安排让我焦虑，可能是因为我需要提前准备情绪。', 'self',
        ReminderPreference.BEDTIME, FragmentVisibility.PRIVATE,
        nowTimestamp - 5 * DateUtils.DAY_MS, '07.19'),
      SeedData.fragment('seed-fragment-03', '03', '社交边界',
        '我不是讨厌社交，我是讨厌临时社交。', 'self',
        ReminderPreference.WEEKEND, FragmentVisibility.COMMUNITY,
        nowTimestamp - 3 * DateUtils.DAY_MS, '07.21'),
      SeedData.fragment('seed-fragment-04', '04', '灵感脑洞',
        '可以把人的社交状态想成电量，而不是性格。', 'idea',
        ReminderPreference.BEDTIME, FragmentVisibility.COMMUNITY,
        nowTimestamp - 3 * DateUtils.DAY_MS, '07.21'),
      SeedData.fragment('seed-fragment-05', '05', '行动方向',
        '以后可以提前告诉朋友：我需要一点计划感。', 'idea',
        ReminderPreference.COMMUTE, FragmentVisibility.PRIVATE,
        nowTimestamp - 2 * DateUtils.DAY_MS, '07.22'),
      SeedData.fragment('seed-fragment-06', '06', '情绪瞬间',
        '不回复消息不是冷淡，有时只是系统正在降温。', 'memory',
        ReminderPreference.WEEKEND, FragmentVisibility.COMMUNITY,
        nowTimestamp - 2 * DateUtils.DAY_MS, '07.22')
    ]
  }

  private static fragment(
    id: string,
    displayCode: string,
    tag: string,
    text: string,
    tone: string,
    remind: ReminderPreference,
    visibility: FragmentVisibility,
    createdAtTimestamp: number,
    createdAt: string
  ): FragmentItem {
    return new FragmentItem({
      id: id,
      displayCode: displayCode,
      tag: tag,
      text: text,
      tone: tone,
      remind: remind,
      visibility: visibility,
      createdAt: createdAt,
      createdAtTimestamp: createdAtTimestamp,
      moderationStatus: visibility === FragmentVisibility.COMMUNITY ?
        FragmentModerationStatus.APPROVED : FragmentModerationStatus.LOCAL_ONLY
    })
  }

  static relations(nowTimestamp: number = Date.now()): FragmentRelation[] {
    return [
      new FragmentRelation('seed-relation-01', 'seed-fragment-01', 'seed-fragment-02', 'related', nowTimestamp),
      new FragmentRelation('seed-relation-02', 'seed-fragment-01', 'seed-fragment-03', 'related', nowTimestamp),
      new FragmentRelation('seed-relation-03', 'seed-fragment-02', 'seed-fragment-03', 'related', nowTimestamp),
      new FragmentRelation('seed-relation-04', 'seed-fragment-03', 'seed-fragment-04', 'inspired', nowTimestamp),
      new FragmentRelation('seed-relation-05', 'seed-fragment-03', 'seed-fragment-05', 'action', nowTimestamp),
      new FragmentRelation('seed-relation-06', 'seed-fragment-03', 'seed-fragment-06', 'related', nowTimestamp),
      new FragmentRelation('seed-relation-07', 'seed-fragment-04', 'seed-fragment-05', 'related', nowTimestamp)
    ]
  }

}
