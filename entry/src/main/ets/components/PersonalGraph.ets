import { FragmentItem } from '../model/FragmentModel'
import { GraphEdge, GraphNode } from '../model/GraphModel'
import { BoxStyle } from '../theme/FragmentTheme'

@Component
export struct PersonalGraph {
  @Prop nodes: GraphNode[] = []
  @Prop edges: GraphEdge[] = []
  @Prop activeNodeKey: string = ''
  @Prop relatedFragments: FragmentItem[] = []
  onSelectFragment: (fragmentId: string) => void = (fragmentId: string): void => {
  }
  onClose: () => void = (): void => {
  }

  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private canvasContext: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(this.canvasSettings)
  private selectedNodeKey: string = ''

  aboutToAppear(): void {
    this.selectedNodeKey = this.activeNodeKey
  }

  build() {
    Column() {
      this.GraphHeader()
      this.GraphCard()
      this.RelationList()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 22, right: 22, top: 34, bottom: 74 })
  }

  @Builder
  GraphHeader() {
    Column() {
      Row() {
        Text('脑洞关系网')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222425')

        Blank()

        Button('返回碎片 +')
          .width(112)
          .height(38)
          .fontSize(13)
          .fontColor('#3d403d')
          .backgroundColor('rgba(255, 255, 255, 0.76)')
          .border({ width: 1, color: 'rgba(56, 58, 57, 0.08)' })
          .borderRadius(19)
          .shadow({ radius: 18, color: 'rgba(44, 46, 45, 0.10)', offsetX: 0, offsetY: 8 })
          .onClick(() => {
            this.onClose()
          })
      }
      .width('100%')

      Text('点击节点查看关系')
        .fontSize(12)
        .fontColor('#747873')
        .height(30)
        .lineHeight(30)
        .padding({ left: 12, right: 12 })
        .margin({ top: 10 })
        .backgroundColor('rgba(255, 255, 255, 0.70)')
        .border({ width: 1, color: 'rgba(56, 58, 57, 0.08)' })
        .borderRadius(15)
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
  }

  @Builder
  GraphCard() {
    Stack() {
      Canvas(this.canvasContext)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.draw()
        })
        .onTouch((event: TouchEvent) => {
          this.handleTouch(event)
        })
    }
    .width('100%')
    .height(420)
    .margin({ top: 18 })
    .backgroundColor(BoxStyle.SOFT_PANEL)
    .border({ width: 1, color: 'rgba(55, 57, 56, 0.05)' })
    .borderRadius(26)
    .clip(true)
  }

  @Builder
  RelationList() {
    Column({ space: 8 }) {
      Text($r('app.string.relation_list_title'))
        .fontSize(12)
        .fontColor(BoxStyle.TEXT_MUTED)
        .width('100%')

      if (this.relatedFragments.length === 0) {
        Text('当前碎片还没有已保存的关系。')
          .fontSize(13)
          .fontColor(BoxStyle.TEXT_SOFT)
          .width('100%')
          .height(42)
          .lineHeight(42)
      } else {
        Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
          ForEach(this.relatedFragments.slice(0, 3), (item: FragmentItem) => {
            Text(item.displayCode + ' · ' + item.tag)
              .fontSize(12)
              .fontColor(BoxStyle.TEXT_SOFT)
              .height(34)
              .lineHeight(34)
              .padding({ left: 12, right: 12 })
              .margin({ right: 8, bottom: 6 })
              .backgroundColor('rgba(255, 255, 255, 0.68)')
              .border({ width: 1, color: BoxStyle.HAIRLINE })
              .borderRadius(17)
              .onClick(() => {
                this.selectFragment(item.id)
              })
          }, (item: FragmentItem) => item.id)
        }
        .width('100%')
      }
    }
    .width('100%')
    .height(88)
    .margin({ top: 12 })
  }

  private selectFragment(fragmentId: string): void {
    for (let i: number = 0; i < this.nodes.length; i++) {
      if (this.nodes[i].fragmentId === fragmentId) {
        this.selectedNodeKey = this.nodes[i].key
        break
      }
    }
    this.draw()
    this.onSelectFragment(fragmentId)
  }

  private draw(): void {
    let width: number = this.canvasContext.width
    let height: number = this.canvasContext.height
    if (width <= 0 || height <= 0) {
      return
    }
    this.canvasContext.clearRect(0, 0, width, height)
    this.drawEdges(width, height)
    this.drawNodes(width, height)
    this.drawLabels(width, height)
  }

  private drawEdges(width: number, height: number): void {
    for (let i: number = 0; i < this.edges.length; i++) {
      let edge: GraphEdge = this.edges[i]
      let from: GraphNode | null = this.nodeByKey(edge.fromKey)
      let to: GraphNode | null = this.nodeByKey(edge.toKey)
      if (from === null || to === null) {
        continue
      }
      let fromX: number = this.canvasX(from, width)
      let fromY: number = this.canvasY(from, height)
      let toX: number = this.canvasX(to, width)
      let toY: number = this.canvasY(to, height)
      let dx: number = toX - fromX
      let dy: number = toY - fromY
      this.canvasContext.beginPath()
      this.canvasContext.moveTo(fromX, fromY)
      this.canvasContext.quadraticCurveTo(
        (fromX + toX) / 2 - dy * 0.18,
        (fromY + toY) / 2 + dx * 0.18,
        toX,
        toY
      )
      let active: boolean =
        edge.fromKey === this.selectedNodeKey || edge.toKey === this.selectedNodeKey
      this.canvasContext.strokeStyle = active ? BoxStyle.GRAPH_ACTIVE : BoxStyle.GRAPH_IDLE
      this.canvasContext.lineWidth = active ? 4 : 1.1
      this.canvasContext.stroke()
    }
  }

  private drawNodes(width: number, height: number): void {
    for (let i: number = 0; i < this.nodes.length; i++) {
      let node: GraphNode = this.nodes[i]
      let related: boolean = this.isRelated(node)
      this.canvasContext.beginPath()
      this.canvasContext.arc(
        this.canvasX(node, width),
        this.canvasY(node, height),
        BoxStyle.GRAPH_NODE_RADIUS,
        0,
        Math.PI * 2
      )
      this.canvasContext.fillStyle =
        node.key === this.selectedNodeKey ? '#3f4440' : this.toneColor(node.tone)
      this.canvasContext.globalAlpha = related ? 0.96 : 0.34
      this.canvasContext.fill()
      this.canvasContext.globalAlpha = 1
    }
  }

  private drawLabels(width: number, height: number): void {
    this.canvasContext.font = '13px sans-serif'
    this.canvasContext.textAlign = 'center'
    this.canvasContext.textBaseline = 'top'
    for (let i: number = 0; i < this.nodes.length; i++) {
      let node: GraphNode = this.nodes[i]
      this.canvasContext.fillStyle =
        this.isRelated(node) ? BoxStyle.TEXT_SOFT : BoxStyle.TEXT_MUTED
      this.canvasContext.fillText(
        node.name.length > 0 ? node.name : '关联点',
        this.canvasX(node, width),
        this.canvasY(node, height) + BoxStyle.GRAPH_NODE_RADIUS + 8,
        76
      )
    }
  }

  private handleTouch(event: TouchEvent): void {
    if (event.type !== TouchType.Down || event.touches.length === 0) {
      return
    }
    for (let i: number = 0; i < this.nodes.length; i++) {
      let node: GraphNode = this.nodes[i]
      let dx: number = event.touches[0].x - this.canvasX(node, this.canvasContext.width)
      let dy: number = event.touches[0].y - this.canvasY(node, this.canvasContext.height)
      if (Math.sqrt(dx * dx + dy * dy) <= BoxStyle.GRAPH_HIT_RADIUS) {
        this.selectedNodeKey = node.key
        this.draw()
        if (node.fragmentId.length > 0) {
          this.onSelectFragment(node.fragmentId)
        }
        return
      }
    }
  }

  private nodeByKey(key: string): GraphNode | null {
    for (let i: number = 0; i < this.nodes.length; i++) {
      if (this.nodes[i].key === key) {
        return this.nodes[i]
      }
    }
    return null
  }

  private isRelated(node: GraphNode): boolean {
    if (node.key === this.selectedNodeKey) {
      return true
    }
    for (let i: number = 0; i < this.edges.length; i++) {
      if ((this.edges[i].fromKey === this.selectedNodeKey &&
        this.edges[i].toKey === node.key) ||
        (this.edges[i].toKey === this.selectedNodeKey &&
          this.edges[i].fromKey === node.key)) {
        return true
      }
    }
    return false
  }

  private canvasX(node: GraphNode, width: number): number {
    return 28 + (node.x - BoxStyle.GRAPH_SOURCE_MIN_X) /
      (BoxStyle.GRAPH_SOURCE_MAX_X - BoxStyle.GRAPH_SOURCE_MIN_X) * (width - 56)
  }

  private canvasY(node: GraphNode, height: number): number {
    return 34 + (node.y - BoxStyle.GRAPH_SOURCE_MIN_Y) /
      (BoxStyle.GRAPH_SOURCE_MAX_Y - BoxStyle.GRAPH_SOURCE_MIN_Y) * (height - 74)
  }

  private toneColor(tone: string): string {
    if (tone === 'idea') {
      return '#b695a5'
    }
    if (tone === 'memory') {
      return '#8aa9ae'
    }
    if (tone === 'green') {
      return '#8fa783'
    }
    if (tone === 'blue') {
      return '#91a4b5'
    }
    if (tone === 'rose') {
      return '#b08a9a'
    }
    return '#91a883'
  }
}
