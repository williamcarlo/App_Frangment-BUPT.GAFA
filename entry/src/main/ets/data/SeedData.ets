import { CommunityNode } from '../model/CommunityModel'
import { FragmentItem, FragmentRelation, ReminderPreference } from '../model/FragmentModel'
import { GraphEdge, GraphNode } from '../model/GraphModel'
import { DateUtils } from '../utils/DateUtils'

export class SeedData {
  static fragments(nowTimestamp: number = Date.now()): FragmentItem[] {
    return [
      new FragmentItem('seed-fragment-01', '通勤观察', '人在很累的时候，不是不想社交，而是不想解释自己。', 'memory', ReminderPreference.COMMUTE, true, '07.18', nowTimestamp - 6 * DateUtils.DAY_MS, '01'),
      new FragmentItem('seed-fragment-02', '复盘经验', '临时安排让我焦虑，可能是因为我需要提前准备情绪。', 'self', ReminderPreference.BEDTIME, false, '07.19', nowTimestamp - 5 * DateUtils.DAY_MS, '02'),
      new FragmentItem('seed-fragment-03', '社交边界', '我不是讨厌社交，我是讨厌临时社交。', 'self', ReminderPreference.WEEKEND, true, '07.21', nowTimestamp - 3 * DateUtils.DAY_MS, '03'),
      new FragmentItem('seed-fragment-04', '灵感脑洞', '可以把人的社交状态想成电量，而不是性格。', 'idea', ReminderPreference.BEDTIME, true, '07.21', nowTimestamp - 3 * DateUtils.DAY_MS, '04'),
      new FragmentItem('seed-fragment-05', '行动方向', '以后可以提前告诉朋友：我需要一点计划感。', 'idea', ReminderPreference.COMMUTE, false, '07.22', nowTimestamp - 2 * DateUtils.DAY_MS, '05'),
      new FragmentItem('seed-fragment-06', '情绪瞬间', '不回复消息不是冷淡，有时只是系统正在降温。', 'memory', ReminderPreference.WEEKEND, true, '07.22', nowTimestamp - 2 * DateUtils.DAY_MS, '06')
    ]
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

  static graphNodes(): GraphNode[] {
    return [
      new GraphNode('n1', '01', '通勤观察', 'memory', 74, 132, 'seed-fragment-01'),
      new GraphNode('n2', '02', '复盘经验', 'self', 178, 92, 'seed-fragment-02'),
      new GraphNode('n3', '03', '社交边界', 'self', 184, 294, 'seed-fragment-03'),
      new GraphNode('n4', '04', '灵感脑洞', 'idea', 284, 152, 'seed-fragment-04'),
      new GraphNode('n5', '05', '行动方向', 'idea', 288, 358, 'seed-fragment-05'),
      new GraphNode('n6', '06', '情绪瞬间', 'memory', 116, 432, 'seed-fragment-06'),
      new GraphNode('m1', '', '', 'micro', 96, 256, ''),
      new GraphNode('m2', '', '', 'micro', 134, 306, ''),
      new GraphNode('m3', '', '', 'micro', 220, 232, ''),
      new GraphNode('m4', '', '', 'micro', 198, 402, ''),
      new GraphNode('m5', '', '', 'micro', 318, 264, '')
    ]
  }

  static graphEdges(): GraphEdge[] {
    return [
      new GraphEdge('e1', 'n1', 'n2', 'rgba(113, 151, 160, 0.30)'),
      new GraphEdge('e2', 'n1', 'n3', 'rgba(113, 151, 160, 0.18)'),
      new GraphEdge('e3', 'n2', 'n3', 'rgba(113, 151, 160, 0.20)'),
      new GraphEdge('e4', 'n3', 'n4', 'rgba(176, 125, 145, 0.20)'),
      new GraphEdge('e5', 'n3', 'n5', 'rgba(176, 125, 145, 0.24)'),
      new GraphEdge('e6', 'n3', 'n6', 'rgba(179, 159, 91, 0.28)'),
      new GraphEdge('e7', 'n4', 'n5', 'rgba(192, 194, 188, 0.30)'),
      new GraphEdge('e8', 'n1', 'm2', 'rgba(192, 194, 188, 0.24)'),
      new GraphEdge('e9', 'm3', 'n4', 'rgba(192, 194, 188, 0.24)')
    ]
  }

  static communityNodes(): CommunityNode[] {
    return [
      new CommunityNode('root', '', '当前碎片', '当前碎片', '我的 Box', '延申起点', '', 'root', 54, 18, 208, 66),
      new CommunityNode('similar', 'root', '相似经验', '相似经验', '匿名共享', '关联依据：语义相近', '我发现自己不是抗拒见面，而是抗拒没有边界感的临时邀约。', 'slate', 0, 128, 98, 66),
      new CommunityNode('opposite', 'root', '相反经验', '相反经验', 'Luna', '另一种视角', '有时突然被叫出去反而让我重新启动，计划太满才会让我失去弹性。', 'blue', 109, 128, 98, 66),
      new CommunityNode('action', 'root', '行动方向', '可借鉴做法', '匿名共享', '可借鉴线索', '我会给朋友一个默认回复模板：今天电量低，但我不是不在乎。', 'green', 218, 128, 98, 66),
      new CommunityNode('metaphor', 'opposite', '延申比喻', '延申比喻', 'River', '来自相反经验的分叉', '社交电量也许不是电池，更像天气：它会变，但不需要被评判。', 'rose', 102, 236, 112, 66),
      new CommunityNode('city', 'similar', '城市观察', '城市观察', 'M.', '来自相似经验的分叉', '早高峰里很多人看起来冷漠，其实只是把情绪调到省电模式。', 'slate', 0, 340, 108, 66),
      new CommunityNode('reply', 'action', '关系提醒', '关系提醒', 'K', '来自行动做法的分叉', '边界不是拒绝关系，而是让关系不要总靠临时消耗来证明。', 'blue', 208, 340, 108, 66),
      new CommunityNode('silence', 'metaphor', '轻复盘', '轻复盘', '匿名共享', '继续延申：情绪恢复', '不回复消息的那段空白，可能是大脑在把外界声音慢慢降下来。', 'rose', 104, 430, 108, 66)
    ]
  }
}
