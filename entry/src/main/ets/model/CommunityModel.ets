export class CommunityNode {
  key: string = ''
  parent: string = ''
  title: string = ''
  tag: string = ''
  author: string = ''
  match: string = ''
  text: string = ''
  tone: string = ''
  x: number = 0
  y: number = 0
  w: number = 0
  h: number = 0
  savedFragmentId: string = ''
  savedAtTimestamp: number = 0

  constructor(
    key: string,
    parent: string,
    title: string,
    tag: string,
    author: string,
    match: string,
    text: string,
    tone: string,
    x: number,
    y: number,
    w: number,
    h: number,
    savedFragmentId: string = '',
    savedAtTimestamp: number = 0
  ) {
    this.key = key
    this.parent = parent
    this.title = title
    this.tag = tag
    this.author = author
    this.match = match
    this.text = text
    this.tone = tone
    this.x = x
    this.y = y
    this.w = w
    this.h = h
    this.savedFragmentId = savedFragmentId
    this.savedAtTimestamp = savedAtTimestamp
  }
}

export class CommunitySaveRecord {
  sourceCommunityNodeId: string = ''
  savedFragmentId: string = ''
  savedAtTimestamp: number = 0

  constructor(sourceCommunityNodeId: string, savedFragmentId: string, savedAtTimestamp: number) {
    this.sourceCommunityNodeId = sourceCommunityNodeId
    this.savedFragmentId = savedFragmentId
    this.savedAtTimestamp = savedAtTimestamp
  }
}
