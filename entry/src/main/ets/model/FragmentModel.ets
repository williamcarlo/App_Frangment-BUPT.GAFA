export enum FragmentKind {
  IDEA = '灵感',
  OBSERVATION = '观察',
  REFLECTION = '复盘',
  EMOTION = '情绪',
  IMPULSE = '冲动'
}

export enum ReminderPreference {
  NONE = '先让它沉睡',
  COMMUTE = '通勤时',
  BEFORE_SLEEP = '睡前',
  WEEKEND = '周末',
  RANDOM = '随机回响'
}

export enum FragmentVisibility {
  PRIVATE = '仅自己',
  COMMUNITY = '加入社区图谱'
}

export enum ExtensionType {
  SELF = '自我延申',
  COMMUNITY = '他人延申',
  DIRECTION = '方向延申'
}

export interface FragmentDraft {
  content: string;
  kind: FragmentKind;
  tags: string[];
  reminder: ReminderPreference;
  visibility: FragmentVisibility;
}

export interface FragmentItem {
  id: string;
  content: string;
  kind: FragmentKind;
  tags: string[];
  reminder: ReminderPreference;
  visibility: FragmentVisibility;
  createdAt: number;
}

export interface FragmentExtension {
  id: string;
  type: ExtensionType;
  title: string;
  content: string;
  reason: string;
}

export interface ExtensionBundle {
  selfExtensions: FragmentItem[];
  communityExtensions: FragmentExtension[];
  directionExtensions: FragmentExtension[];
}
