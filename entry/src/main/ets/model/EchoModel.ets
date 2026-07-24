export class EchoRecord {
  id: string = ''
  fragmentId: string = ''
  surfacedAtTimestamp: number = 0
  openedAtTimestamp: number = 0
  dismissedUntilTimestamp: number = 0
  reason: string = ''

  constructor(
    id: string,
    fragmentId: string,
    surfacedAtTimestamp: number,
    openedAtTimestamp: number,
    dismissedUntilTimestamp: number,
    reason: string
  ) {
    this.id = id
    this.fragmentId = fragmentId
    this.surfacedAtTimestamp = surfacedAtTimestamp
    this.openedAtTimestamp = openedAtTimestamp
    this.dismissedUntilTimestamp = dismissedUntilTimestamp
    this.reason = reason
  }
}

export class EchoCandidate {
  fragmentId: string = ''
  reason: string = ''

  constructor(fragmentId: string, reason: string) {
    this.fragmentId = fragmentId
    this.reason = reason
  }
}
