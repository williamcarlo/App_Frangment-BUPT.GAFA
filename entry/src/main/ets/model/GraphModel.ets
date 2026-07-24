export class GraphNode {
  key: string = ''
  label: string = ''
  name: string = ''
  tone: string = ''
  x: number = 0
  y: number = 0
  fragmentId: string = ''

  constructor(key: string, label: string, name: string, tone: string, x: number, y: number, fragmentId: string) {
    this.key = key
    this.label = label
    this.name = name
    this.tone = tone
    this.x = x
    this.y = y
    this.fragmentId = fragmentId
  }
}

export class GraphEdge {
  key: string = ''
  fromKey: string = ''
  toKey: string = ''
  color: string = ''

  constructor(key: string, fromKey: string, toKey: string, color: string) {
    this.key = key
    this.fromKey = fromKey
    this.toKey = toKey
    this.color = color
  }
}
