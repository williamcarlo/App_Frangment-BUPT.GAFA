import {
  FragmentDraft,
  FragmentItem,
  FragmentKind,
  FragmentVisibility,
  ReminderPreference
} from '../model/FragmentModel';

export class FragmentRepository {
  private static fragments: FragmentItem[] = [
    {
      id: 'seed-1',
      content: '为什么人在陌生城市里更容易感到自由？',
      kind: FragmentKind.OBSERVATION,
      tags: ['城市', '自由', '旅行'],
      reminder: ReminderPreference.WEEKEND,
      visibility: FragmentVisibility.COMMUNITY,
      createdAt: Date.now() - 1000 * 60 * 60 * 24 * 18
    },
    {
      id: 'seed-2',
      content: '产品不一定要替用户做更多，也可以明确告诉用户：今天已经够了。',
      kind: FragmentKind.IDEA,
      tags: ['产品', '反焦虑', '边界'],
      reminder: ReminderPreference.RANDOM,
      visibility: FragmentVisibility.PRIVATE,
      createdAt: Date.now() - 1000 * 60 * 60 * 24 * 7
    },
    {
      id: 'seed-3',
      content: '下次小组讨论前，先各自写下判断，再同时公开，可能会减少从众。',
      kind: FragmentKind.REFLECTION,
      tags: ['协作', '决策', '从众'],
      reminder: ReminderPreference.COMMUTE,
      visibility: FragmentVisibility.PRIVATE,
      createdAt: Date.now() - 1000 * 60 * 60 * 24 * 3
    }
  ];

  static list(): FragmentItem[] {
    return this.fragments.slice();
  }

  static add(draft: FragmentDraft): FragmentItem {
    const item: FragmentItem = {
      id: `fragment-${Date.now()}`,
      content: draft.content.trim(),
      kind: draft.kind,
      tags: draft.tags,
      reminder: draft.reminder,
      visibility: draft.visibility,
      createdAt: Date.now()
    };
    this.fragments.unshift(item);
    return item;
  }

  static findById(id: string): FragmentItem | undefined {
    return this.fragments.find((item: FragmentItem) => item.id === id);
  }
}
