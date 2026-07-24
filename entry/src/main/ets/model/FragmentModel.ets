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

export enum FragmentLifecycleAction {
  NONE = 'NONE',
  ARCHIVE = 'ARCHIVE',
  RESTORE = 'RESTORE',
  REVOKE = 'REVOKE',
  DELETE = 'DELETE'
}

export interface FragmentItemInit {
  id: string
  displayCode: string
  tag: string
  text: string
  tone: string
  remind: ReminderPreference
  visibility: FragmentVisibility
  createdAtTimestamp: number
  createdAt?: string
  updatedAtTimestamp?: number
  archivedAtTimestamp?: number
  sourceCommunityNodeId?: string
  moderationStatus?: FragmentModerationStatus
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

  constructor(init: FragmentItemInit) {
    this.id = init.id
    this.displayCode = init.displayCode
    this.tag = init.tag
    this.text = init.text
    this.tone = init.tone
    this.remind = init.remind
    this.visibility = init.visibility
    this.createdAt = init.createdAt === undefined ? '' : init.createdAt
    this.createdAtTimestamp = init.createdAtTimestamp
    this.updatedAtTimestamp = init.updatedAtTimestamp === undefined ||
      init.updatedAtTimestamp <= 0 ? init.createdAtTimestamp : init.updatedAtTimestamp
    this.archivedAtTimestamp = init.archivedAtTimestamp === undefined ? 0 : init.archivedAtTimestamp
    this.sourceCommunityNodeId =
      init.sourceCommunityNodeId === undefined ? '' : init.sourceCommunityNodeId
    if (this.visibility === FragmentVisibility.COMMUNITY) {
      this.moderationStatus = init.moderationStatus === undefined ?
        FragmentModerationStatus.PENDING : init.moderationStatus
    } else {
      this.moderationStatus = FragmentModerationStatus.LOCAL_ONLY
    }
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
  supersededAtTimestamp: number = 0
  isActive: boolean = true

  constructor(
    id: string,
    fragmentId: string,
    visibility: FragmentVisibility,
    specificPeople: string,
    consentedAtTimestamp: number,
    revokedAtTimestamp: number = 0,
    supersededAtTimestamp: number = 0,
    isActive: boolean = true
  ) {
    this.id = id
    this.fragmentId = fragmentId
    this.visibility = visibility
    this.specificPeople = specificPeople
    this.consentedAtTimestamp = consentedAtTimestamp
    this.revokedAtTimestamp = revokedAtTimestamp
    this.supersededAtTimestamp = supersededAtTimestamp
    this.isActive = isActive
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
