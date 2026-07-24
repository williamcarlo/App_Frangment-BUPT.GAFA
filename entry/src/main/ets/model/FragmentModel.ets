export enum FragmentVisibility {
  PRIVATE = 'PRIVATE',
  COMMUNITY = 'COMMUNITY',
  SPECIFIC_PEOPLE = 'SPECIFIC_PEOPLE',
  REVOKED = 'REVOKED'
}

export enum ReminderPreference {
  COMMUTE = '通勤',
  BEDTIME = '睡前',
  WEEKEND = '周末',
  NONE = '先让它沉睡',
  RANDOM = '随机'
}

export enum FragmentModerationStatus {
  LOCAL_ONLY = 'LOCAL_ONLY',
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED'
}

export class FragmentItem {
  id: string = ''
  displayCode: string = ''
  tag: string = ''
  text: string = ''
  tone: string = ''
  remind: ReminderPreference = ReminderPreference.NONE
  visibility: FragmentVisibility = FragmentVisibility.PRIVATE
  createdAt: string = ''
  createdAtTimestamp: number = 0
  updatedAtTimestamp: number = 0
  archivedAtTimestamp: number = 0
  sourceCommunityNodeId: string = ''
  moderationStatus: FragmentModerationStatus = FragmentModerationStatus.LOCAL_ONLY

  constructor(
    id: string,
    tag: string,
    text: string,
    tone: string,
    remind: ReminderPreference,
    shared: boolean,
    createdAt: string,
    createdAtTimestamp: number = Date.now(),
    displayCode: string = '',
    visibility: FragmentVisibility = FragmentVisibility.PRIVATE,
    updatedAtTimestamp: number = 0,
    archivedAtTimestamp: number = 0,
    sourceCommunityNodeId: string = '',
    moderationStatus: FragmentModerationStatus = FragmentModerationStatus.LOCAL_ONLY
  ) {
    this.id = id
    this.displayCode = displayCode.length > 0 ? displayCode : id
    this.tag = tag
    this.text = text
    this.tone = tone
    this.remind = remind
    this.visibility = shared ? FragmentVisibility.COMMUNITY : visibility
    this.createdAt = createdAt
    this.createdAtTimestamp = createdAtTimestamp
    this.updatedAtTimestamp = updatedAtTimestamp > 0 ? updatedAtTimestamp : createdAtTimestamp
    this.archivedAtTimestamp = archivedAtTimestamp
    this.sourceCommunityNodeId = sourceCommunityNodeId
    this.moderationStatus = moderationStatus
  }

  get shared(): boolean {
    return this.visibility === FragmentVisibility.COMMUNITY
  }

  get archived(): boolean {
    return this.archivedAtTimestamp > 0
  }
}

export class FragmentRelation {
  id: string = ''
  fromFragmentId: string = ''
  toFragmentId: string = ''
  relationType: string = ''
  createdAtTimestamp: number = 0

  constructor(
    id: string,
    fromFragmentId: string,
    toFragmentId: string,
    relationType: string,
    createdAtTimestamp: number = Date.now()
  ) {
    this.id = id
    this.fromFragmentId = fromFragmentId
    this.toFragmentId = toFragmentId
    this.relationType = relationType
    this.createdAtTimestamp = createdAtTimestamp
  }
}

export class SharingConsent {
  id: string = ''
  fragmentId: string = ''
  visibility: FragmentVisibility = FragmentVisibility.PRIVATE
  specificPeople: string = ''
  consentedAtTimestamp: number = 0
  revokedAtTimestamp: number = 0

  constructor(
    id: string,
    fragmentId: string,
    visibility: FragmentVisibility,
    specificPeople: string,
    consentedAtTimestamp: number,
    revokedAtTimestamp: number = 0
  ) {
    this.id = id
    this.fragmentId = fragmentId
    this.visibility = visibility
    this.specificPeople = specificPeople
    this.consentedAtTimestamp = consentedAtTimestamp
    this.revokedAtTimestamp = revokedAtTimestamp
  }
}

export function visibilityLabel(visibility: FragmentVisibility): string {
  if (visibility === FragmentVisibility.COMMUNITY) {
    return '加入社区'
  }
  if (visibility === FragmentVisibility.SPECIFIC_PEOPLE) {
    return '指定的人'
  }
  if (visibility === FragmentVisibility.REVOKED) {
    return '已撤回共享'
  }
  return '仅自己可见'
}
