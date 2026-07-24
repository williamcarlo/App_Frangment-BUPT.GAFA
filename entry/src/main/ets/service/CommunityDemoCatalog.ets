import { CommunityNode } from '../model/CommunityModel'
import { StableCommunityNodeIdService } from './StableCommunityNodeIdService'

// 本地社区尚未接入服务端；此目录只提供明确标注的交互演示内容，
// 与只用于首次导入 RDB 的 SeedData 分开，避免把运行时图谱事实混在种子数据中。
export class CommunityDemoCatalog {
  static nodes(rootFragmentId: string): CommunityNode[] {
    let root: string = StableCommunityNodeIdService.create(
      rootFragmentId, '', 'root', '当前碎片', 'local-box'
    )
    let similar: string = StableCommunityNodeIdService.create(
      rootFragmentId, root, 'similar',
      '我发现自己不是抗拒见面，而是抗拒没有边界感的临时邀约。', 'anonymous'
    )
    let opposite: string = StableCommunityNodeIdService.create(
      rootFragmentId, root, 'opposite',
      '有时突然被叫出去反而让我重新启动，计划太满才会让我失去弹性。', 'luna'
    )
    let action: string = StableCommunityNodeIdService.create(
      rootFragmentId, root, 'action',
      '我会给朋友一个默认回复模板：今天电量低，但我不是不在乎。', 'anonymous'
    )
    let metaphor: string = StableCommunityNodeIdService.create(
      rootFragmentId, opposite, 'metaphor',
      '社交电量也许不是电池，更像天气：它会变，但不需要被评判。', 'river'
    )
    return [
      new CommunityNode(
        root, '', '当前碎片', '当前碎片', '我的 Box',
        '延申起点', '', 'root', 54, 18, 208, 66
      ),
      new CommunityNode(
        similar, root, '相似经验', '相似经验', '匿名共享',
        '关联依据：语义相近',
        '我发现自己不是抗拒见面，而是抗拒没有边界感的临时邀约。',
        'slate', 0, 128, 98, 66
      ),
      new CommunityNode(
        opposite, root, '相反经验', '相反经验', 'Luna',
        '另一种视角',
        '有时突然被叫出去反而让我重新启动，计划太满才会让我失去弹性。',
        'blue', 109, 128, 98, 66
      ),
      new CommunityNode(
        action, root, '行动方向', '可借鉴做法', '匿名共享',
        '可借鉴线索',
        '我会给朋友一个默认回复模板：今天电量低，但我不是不在乎。',
        'green', 218, 128, 98, 66
      ),
      new CommunityNode(
        metaphor, opposite, '延申比喻', '延申比喻', 'River',
        '来自相反经验的分叉',
        '社交电量也许不是电池，更像天气：它会变，但不需要被评判。',
        'rose', 102, 236, 112, 66
      ),
      new CommunityNode(
        StableCommunityNodeIdService.create(
          rootFragmentId,
          similar,
          'city',
          '早高峰里很多人看起来冷漠，其实只是把情绪调到省电模式。',
          'm'
        ),
        similar, '城市观察', '城市观察', 'M.',
        '来自相似经验的分叉',
        '早高峰里很多人看起来冷漠，其实只是把情绪调到省电模式。',
        'slate', 0, 340, 108, 66
      ),
      new CommunityNode(
        StableCommunityNodeIdService.create(
          rootFragmentId,
          action,
          'reply',
          '边界不是拒绝关系，而是让关系不要总靠临时消耗来证明。',
          'k'
        ),
        action, '关系提醒', '关系提醒', 'K',
        '来自行动做法的分叉',
        '边界不是拒绝关系，而是让关系不要总靠临时消耗来证明。',
        'blue', 208, 340, 108, 66
      ),
      new CommunityNode(
        StableCommunityNodeIdService.create(
          rootFragmentId,
          metaphor,
          'silence',
          '不回复消息的那段空白，可能是大脑在把外界声音慢慢降下来。',
          'anonymous'
        ),
        metaphor, '轻复盘', '轻复盘', '匿名共享',
        '继续延申：情绪恢复',
        '不回复消息的那段空白，可能是大脑在把外界声音慢慢降下来。',
        'rose', 104, 430, 108, 66
      )
    ]
  }
}
