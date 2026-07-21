import {
  ExtensionBundle,
  ExtensionType,
  FragmentExtension,
  FragmentItem,
  FragmentKind
} from '../model/FragmentModel';

export class RelationService {
  static buildBundle(center: FragmentItem, all: FragmentItem[]): ExtensionBundle {
    const related: FragmentItem[] = all
      .filter((item: FragmentItem) => item.id !== center.id && RelationService.sharedTagCount(center, item) > 0)
      .slice(0, 3);

    return {
      selfExtensions: related,
      communityExtensions: RelationService.buildCommunityExtensions(center),
      directionExtensions: RelationService.buildDirectionExtensions(center)
    };
  }

  private static sharedTagCount(left: FragmentItem, right: FragmentItem): number {
    let count: number = 0;
    left.tags.forEach((tag: string) => {
      if (right.tags.includes(tag)) {
        count += 1;
      }
    });
    return count;
  }

  private static buildCommunityExtensions(center: FragmentItem): FragmentExtension[] {
    const mainTag: string = center.tags.length > 0 ? center.tags[0] : '生活';
    return [
      {
        id: `${center.id}-community-1`,
        type: ExtensionType.COMMUNITY,
        title: `另一种关于「${mainTag}」的经验`,
        content: '陌生环境有时不是让人逃离身份，而是暂时放下别人对自己的固定期待。',
        reason: `社区公开碎片与「${mainTag}」主题相近`
      },
      {
        id: `${center.id}-community-2`,
        type: ExtensionType.COMMUNITY,
        title: '一条相反的观察',
        content: '自由感也可能来自短暂性：因为知道很快离开，所以更敢于尝试。',
        reason: '系统保留相似与相反两类连接，避免只看到同一种答案'
      }
    ];
  }

  private static buildDirectionExtensions(center: FragmentItem): FragmentExtension[] {
    const prompts: string[] = RelationService.promptsForKind(center.kind);
    return prompts.map((prompt: string, index: number) => {
      return {
        id: `${center.id}-direction-${index}`,
        type: ExtensionType.DIRECTION,
        title: `延申方向 ${index + 1}`,
        content: prompt,
        reason: '方向延申只生成问题或行动入口，不替用户完成思考'
      };
    });
  }

  private static promptsForKind(kind: FragmentKind): string[] {
    if (kind === FragmentKind.REFLECTION) {
      return ['这条经验在什么条件下可能不成立？', '下一次遇到类似情形，可以先尝试哪个最小行动？'];
    }
    if (kind === FragmentKind.OBSERVATION) {
      return ['这种现象在另一个地点或人群中还会出现吗？', '它背后可能有哪些互相矛盾的解释？'];
    }
    if (kind === FragmentKind.EMOTION) {
      return ['这种感受出现之前，发生了什么具体事件？', '未来的自己需要从这条碎片中得到什么提醒？'];
    }
    return ['这条想法可以和过去哪段经历连接？', '把它变成一个问题、一次实验或一个最小行动，会是什么？'];
  }
}
