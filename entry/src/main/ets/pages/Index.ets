enum AppPage {
  BOX = 0,
  COLLECTION = 1,
  COMMUNITY = 2
}

class BoxStyle {
  static readonly PAGE_BG: string = '#F7F3EA'
  static readonly SURFACE: string = '#FFFFFF'
  static readonly CARD_BG: string = 'rgba(255, 255, 255, 0.82)'
  static readonly SOFT_PANEL: string = 'rgba(240, 241, 235, 0.90)'
  static readonly INPUT_BG: string = '#F3F3F0'
  static readonly BUTTON_BG: string = '#222520'
  static readonly TEXT: string = '#222520'
  static readonly TEXT_SOFT: string = '#6F746E'
  static readonly TEXT_MUTED: string = '#A1A49E'
  static readonly TEXT_FAINT: string = '#DADBD6'
  static readonly HAIRLINE: string = 'rgba(55, 57, 55, 0.08)'
  static readonly HAIRLINE_SOFT: string = 'rgba(55, 57, 55, 0.05)'
  static readonly SHADOW: string = 'rgba(44, 47, 45, 0.12)'
  static readonly SHADOW_SOFT: string = 'rgba(44, 47, 45, 0.08)'
  static readonly SELECTED_SOFT: string = '#E4E6E0'
  static readonly SELECTED_TEXT: string = '#465044'
  static readonly GRAPH_ACTIVE: string = 'rgba(64, 73, 67, 0.88)'
  static readonly GRAPH_IDLE: string = 'rgba(139, 143, 137, 0.22)'
  static readonly RADIUS_CARD: number = 28
  static readonly RADIUS_PANEL: number = 30
  static readonly RADIUS_PILL: number = 22
  static readonly ACTION_HEIGHT: number = 58
  static readonly PILL_HEIGHT: number = 44
  static readonly MOTION_FAST: number = 180
  static readonly MOTION_BASE: number = 220
}
class FragmentItem {
  id: string = ''
  tag: string = ''
  text: string = ''
  tone: string = ''
  remind: string = ''
  shared: boolean = false
  createdAt: string = ''

  constructor(id: string, tag: string, text: string, tone: string, remind: string, shared: boolean, createdAt: string) {
    this.id = id
    this.tag = tag
    this.text = text
    this.tone = tone
    this.remind = remind
    this.shared = shared
    this.createdAt = createdAt
  }
}

class GraphNode {
  key: string = ''
  label: string = ''
  name: string = ''
  tone: string = ''
  x: number = 0
  y: number = 0
  fragmentIndex: number = -1

  constructor(key: string, label: string, name: string, tone: string, x: number, y: number, fragmentIndex: number) {
    this.key = key
    this.label = label
    this.name = name
    this.tone = tone
    this.x = x
    this.y = y
    this.fragmentIndex = fragmentIndex
  }
}

class GraphEdge {
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

class CommunityNode {
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
    h: number
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
  }
}

@Entry
@Component
struct Index {
  @State currentPage: AppPage = AppPage.BOX
  @State graphMode: boolean = false
  @State showInputSheet: boolean = false
  @State activeIndex: number = 2
  @State activeCommunityKey: string = 'root'
  @State expandedCommunityKeys: string[] = ['root']
  @State draftContent: string = ''
  @State draftTag: string = ''
  @State draftRemind: string = '通勤'
  @State shareEnabled: boolean = true
  @State shareChoiceMade: boolean = false
  @State inputErrorText: string = ''
  @State toastText: string = ''
  @State showToast: boolean = false
  @State activeGraphNodeKey: string = 'n3'
  @State boxFloatY: number = 0

  private graphCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private graphCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.graphCanvasSettings)
  private graphNodeRadius: number = 10
  private graphSourceMinX: number = 60
  private graphSourceMaxX: number = 330
  private graphSourceMinY: number = 80
  private graphSourceMaxY: number = 450

  @State fragments: FragmentItem[] = [
    new FragmentItem('01', '通勤观察', '人在很累的时候，不是不想社交，而是不想解释自己。', 'memory', '通勤', true, '07.18'),
    new FragmentItem('02', '复盘经验', '临时安排让我焦虑，可能是因为我需要提前准备情绪。', 'self', '睡前', false, '07.19'),
    new FragmentItem('03', '社交边界', '我不是讨厌社交，我是讨厌临时社交。', 'self', '周末', true, '07.21'),
    new FragmentItem('04', '灵感脑洞', '可以把人的社交状态想成电量，而不是性格。', 'idea', '睡前', true, '07.21'),
    new FragmentItem('05', '行动方向', '以后可以提前告诉朋友：我需要一点计划感。', 'idea', '通勤', false, '07.22'),
    new FragmentItem('06', '情绪瞬间', '不回复消息不是冷淡，有时只是系统正在降温。', 'memory', '周末', true, '07.22')
  ]

  private graphNodes: GraphNode[] = [
    new GraphNode('n1', '01', '通勤观察', 'memory', 74, 132, 0),
    new GraphNode('n2', '02', '复盘经验', 'self', 178, 92, 1),
    new GraphNode('n3', '03', '社交边界', 'self', 184, 294, 2),
    new GraphNode('n4', '04', '灵感脑洞', 'idea', 284, 152, 3),
    new GraphNode('n5', '05', '行动方向', 'idea', 288, 358, 4),
    new GraphNode('n6', '06', '情绪瞬间', 'memory', 116, 432, 5),
    new GraphNode('m1', '', '', 'micro', 96, 256, -1),
    new GraphNode('m2', '', '', 'micro', 134, 306, -1),
    new GraphNode('m3', '', '', 'micro', 220, 232, -1),
    new GraphNode('m4', '', '', 'micro', 198, 402, -1),
    new GraphNode('m5', '', '', 'micro', 318, 264, -1)
  ]

  private graphEdges: GraphEdge[] = [
    new GraphEdge('e1', 'n1', 'n2', 'rgba(113, 151, 160, 0.30)'),
    new GraphEdge('e2', 'n1', 'n3', 'rgba(113, 151, 160, 0.18)'),
    new GraphEdge('e3', 'n2', 'n3', 'rgba(113, 151, 160, 0.20)'),
    new GraphEdge('e4', 'n3', 'n4', 'rgba(176, 125, 145, 0.20)'),
    new GraphEdge('e5', 'n3', 'n5', 'rgba(176, 125, 145, 0.24)'),
    new GraphEdge('e6', 'n3', 'n6', 'rgba(179, 159, 91, 0.28)'),
    new GraphEdge('e7', 'n4', 'n5', 'rgba(192, 194, 188, 0.30)'),
    new GraphEdge('e8', 'n1', 'm2', 'rgba(192, 194, 188, 0.24)'),
    new GraphEdge('e9', 'm3', 'n4', 'rgba(192, 194, 188, 0.24)')
  ]

  @State communityNodes: CommunityNode[] = [
    new CommunityNode('root', '', '当前碎片', '当前碎片', '我的 Box', '延申起点', '', 'root', 54, 18, 208, 66),
    new CommunityNode('similar', 'root', '相似经验', '相似经验', '匿名共享', '关联依据：语义相近', '我发现自己不是抗拒见面，而是抗拒没有边界感的临时邀约。', 'slate', 0, 128, 98, 66),
    new CommunityNode('opposite', 'root', '相反经验', '相反经验', 'Luna', '另一种视角', '有时突然被叫出去反而让我重新启动，计划太满才会让我失去弹性。', 'blue', 109, 128, 98, 66),
    new CommunityNode('action', 'root', '行动方向', '可借鉴做法', '匿名共享', '可借鉴线索', '我会给朋友一个默认回复模板：今天电量低，但我不是不在乎。', 'green', 218, 128, 98, 66),
    new CommunityNode('metaphor', 'opposite', '延申比喻', '延申比喻', 'River', '来自相反经验的分叉', '社交电量也许不是电池，更像天气：它会变，但不需要被评判。', 'rose', 102, 236, 112, 66),
    new CommunityNode('city', 'similar', '城市观察', '城市观察', 'M.', '来自相似经验的分叉', '早高峰里很多人看起来冷漠，其实只是把情绪调到省电模式。', 'slate', 0, 340, 108, 66),
    new CommunityNode('reply', 'action', '关系提醒', '关系提醒', 'K', '来自行动做法的分叉', '边界不是拒绝关系，而是让关系不要总靠临时消耗来证明。', 'blue', 208, 340, 108, 66),
    new CommunityNode('silence', 'metaphor', '轻复盘', '轻复盘', '匿名共享', '继续延申：情绪恢复', '不回复消息的那段空白，可能是大脑在把外界声音慢慢降下来。', 'rose', 104, 430, 108, 66)
  ]

  aboutToAppear(): void {
    setInterval(() => {
      this.boxFloatY = 0
    }, 3200)
  }

  build() {
    Stack() {
      this.AppBackground()

      if (this.currentPage === AppPage.BOX) {
        this.BoxPage()
      } else if (this.currentPage === AppPage.COLLECTION) {
        this.CollectionPage()
      } else {
        this.CommunityPage()
      }

      this.PageDots()

      if (this.showToast) {
        this.Toast()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BoxStyle.PAGE_BG)
    .blur(this.showInputSheet ? 2 : 0)
    .bindSheet($$this.showInputSheet, this.InputSheet(), {
      height: 610,
      showClose: false,
      dragBar: false,
      backgroundColor: '#FBFAF6'
    })
    .animation({ duration: BoxStyle.MOTION_BASE, curve: Curve.EaseOut })
    .gesture(
      PanGesture({ direction: PanDirection.Horizontal, distance: 18 })
        .onActionEnd((event: GestureEvent) => {
          this.handlePan(event.offsetX, event.offsetY)
        })
    )
  }

  private currentFragment(): FragmentItem {
    if (this.fragments.length === 0) {
      return new FragmentItem('00', '空 Box', '还没有碎片。', 'self', '通勤', false, '')
    }
    return this.fragments[this.normalizedFragmentIndex(this.activeIndex)]
  }

  private normalizedFragmentIndex(index: number): number {
    if (this.fragments.length === 0) {
      return 0
    }
    if (index < 0) {
      return 0
    }
    if (index >= this.fragments.length) {
      return this.fragments.length - 1
    }
    return index
  }

  private fragmentAtOffset(delta: number): FragmentItem {
    if (this.fragments.length === 0) {
      return new FragmentItem('00', '空 Box', '还没有碎片。', 'self', '通勤', false, '')
    }
    return this.fragments[(this.activeIndex + delta + this.fragments.length) % this.fragments.length]
  }

  // 顶层手势：横向切换三页；在个人碎片页纵向切换碎片。
  private handlePan(offsetX: number, offsetY: number): void {
    if (this.showInputSheet) {
      return
    }
    if (Math.abs(offsetX) > Math.abs(offsetY) && Math.abs(offsetX) > 56) {
      if (offsetX < 0) {
        this.goNextPage()
      } else {
        this.goPreviousPage()
      }
      return
    }
  }

  private goNextPage(): void {
    if (this.currentPage === AppPage.BOX) {
      this.currentPage = AppPage.COLLECTION
      return
    }
    if (this.currentPage === AppPage.COLLECTION) {
      this.graphMode = false
      this.currentPage = AppPage.COMMUNITY
    }
  }

  private goPreviousPage(): void {
    if (this.currentPage === AppPage.COMMUNITY) {
      this.currentPage = AppPage.COLLECTION
      return
    }
    if (this.currentPage === AppPage.COLLECTION) {
      this.graphMode = false
      this.currentPage = AppPage.BOX
    }
  }

  private moveFragment(delta: number): void {
    let count: number = this.fragments.length
    if (count === 0) {
      return
    }
    this.activeIndex = (this.activeIndex + delta + count) % count
    this.activeCommunityKey = 'root'
  }

  private fragmentIndexById(id: string): number {
    for (let i: number = 0; i < this.fragments.length; i++) {
      if (this.fragments[i].id === id) {
        return i
      }
    }
    return this.activeIndex
  }

  private openInputSheet(): void {
    this.inputErrorText = ''
    this.showInputSheet = true
  }

  private closeInputSheet(): void {
    this.inputErrorText = ''
    this.showInputSheet = false
  }

  private archiveFragment(): void {
    if (!this.shareChoiceMade) {
      this.inputErrorText = '请选择可见范围'
      this.showNotice('请先选择可见范围')
      return
    }

    let content: string = this.draftContent.trim()
    let tag: string = this.draftTag.trim()
    let archivedShared: boolean = this.shareEnabled
    if (content.length === 0) {
      content = '一个还没确定价值的碎片已放入 Box，等待未来重新出现。'
    }
    if (tag.length === 0) {
      tag = '未命名碎片'
    }
    let nextId: string = this.nextFragmentId()
    let item: FragmentItem = new FragmentItem(nextId, tag, content, 'self', this.draftRemind, this.shareEnabled, '今天')
    this.fragments = this.fragments.concat([item])
    this.activeIndex = this.fragments.length - 1
    this.draftContent = ''
    this.draftTag = ''
    this.inputErrorText = ''
    this.shareEnabled = true
    this.shareChoiceMade = false
    this.showInputSheet = false
    this.showNotice(archivedShared ? '已放入 Box · 匿名共享' : '已放入 Box · 仅自己可见')
  }

  private isShareChoiceSelected(value: boolean): boolean {
    return this.shareChoiceMade && this.shareEnabled === value
  }

  private nextFragmentId(): string {
    let value: number = this.fragments.length + 1
    return value < 10 ? '0' + value.toString() : value.toString()
  }

  private showNotice(message: string): void {
    this.toastText = message
    this.showToast = true
    setTimeout(() => {
      this.showToast = false
    }, 1500)
  }

  private getToneColor(tone: string): string {
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
    if (tone === 'slate') {
      return '#a5a8a5'
    }
    if (tone === 'micro') {
      return '#a9aca8'
    }
    return '#91a883'
  }

  private isExpanded(key: string): boolean {
    return this.expandedCommunityKeys.indexOf(key) >= 0
  }

  private childrenOf(key: string): CommunityNode[] {
    return this.communityNodes.filter((item: CommunityNode) => item.parent === key)
  }

  private getCommunityNode(key: string): CommunityNode {
    for (let i: number = 0; i < this.communityNodes.length; i++) {
      if (this.communityNodes[i].key === key) {
        return this.communityNodes[i]
      }
    }
    return this.communityNodes[0]
  }

  private selectCommunityNode(key: string): void {
    this.activeCommunityKey = key
    if (this.childrenOf(key).length === 0 && key !== 'root') {
      this.communityNodes = this.communityNodes.concat(this.createCommunityBranches(key))
    }
    this.expandedCommunityKeys = this.communityPathKeys(key)
  }

  private communityPathKeys(key: string): string[] {
    let path: string[] = []
    let currentKey: string = key
    while (currentKey.length > 0) {
      path.unshift(currentKey)
      let node: CommunityNode = this.getCommunityNode(currentKey)
      currentKey = node.parent
    }
    if (path.indexOf('root') < 0) {
      path.unshift('root')
    }
    return path
  }

  private createCommunityBranches(parentKey: string): CommunityNode[] {
    let base: number = this.communityNodes.length + 1
    let parent: CommunityNode = this.getCommunityNode(parentKey)
    return [
      new CommunityNode(parentKey + '-a' + base.toString(), parentKey, '相似分支', parent.tag, '匿名共享', '相似经验', '换一个生活场景看，问题也许不是社交本身，而是节奏被打断。', 'slate', 0, 0, 0, 0),
      new CommunityNode(parentKey + '-b' + base.toString(), parentKey, '反向视角', parent.tag, 'BOXer', '相反经验', '它也许不该被马上解决，只是需要被另一种方式看见。', 'rose', 0, 0, 0, 0)
    ]
  }

  private treeNodeWidth(depth: number, count: number): number {
    if (count <= 1) {
      return depth === 0 ? 136 : 108
    }
    let availableWidth: number = 306
    let gapWidth: number = (count - 1) * 8
    let fitWidth: number = (availableWidth - gapWidth) / count
    let depthWidth: number = 108 - depth * 10
    if (depthWidth < 64) {
      depthWidth = 64
    }
    return Math.max(52, Math.min(depthWidth, fitWidth))
  }

  private treeNodeHeight(depth: number): number {
    if (depth <= 0) {
      return 66
    }
    if (depth === 1) {
      return 60
    }
    if (depth === 2) {
      return 54
    }
    return 50
  }

  private treeTitleSize(depth: number): number {
    if (depth <= 0) {
      return 15
    }
    if (depth === 1) {
      return 13
    }
    return 11
  }

  private graphNodeByKey(key: string): GraphNode {
    for (let i: number = 0; i < this.graphNodes.length; i++) {
      if (this.graphNodes[i].key === key) {
        return this.graphNodes[i]
      }
    }
    return this.graphNodes[0]
  }

  private isGraphEdgeActive(edge: GraphEdge): boolean {
    return edge.fromKey === this.activeGraphNodeKey || edge.toKey === this.activeGraphNodeKey
  }

  private isGraphNodeRelated(node: GraphNode): boolean {
    if (node.key === this.activeGraphNodeKey) {
      return true
    }
    for (let i: number = 0; i < this.graphEdges.length; i++) {
      let edge: GraphEdge = this.graphEdges[i]
      if ((edge.fromKey === this.activeGraphNodeKey && edge.toKey === node.key) ||
        (edge.toKey === this.activeGraphNodeKey && edge.fromKey === node.key)) {
        return true
      }
    }
    return false
  }

  private graphNodeKeyword(node: GraphNode): string {
    if (node.name.length > 0) {
      return node.name
    }
    return '关联点'
  }

  private graphCanvasX(node: GraphNode, width: number): number {
    let usableWidth: number = width - 56
    return 28 + (node.x - this.graphSourceMinX) / (this.graphSourceMaxX - this.graphSourceMinX) * usableWidth
  }

  private graphCanvasY(node: GraphNode, height: number): number {
    let usableHeight: number = height - 74
    return 34 + (node.y - this.graphSourceMinY) / (this.graphSourceMaxY - this.graphSourceMinY) * usableHeight
  }

  private waterfallActiveIndex(firstIndex: number, lastIndex: number, centerIndex?: number): number {
    if (this.fragments.length === 0) {
      return 0
    }

    // List item 0 is the top spacer and real fragments start from item 1.
    // Prefer ArkUI's centerIndex so the card at the visual center becomes black,
    // including 02 / 03 / 05. Fallback to visible midpoint for older runtimes.
    let activeListIndex: number = 1
    if (centerIndex !== undefined && centerIndex >= 1 && centerIndex <= this.fragments.length) {
      activeListIndex = centerIndex
    } else {
      activeListIndex = Math.round((firstIndex + lastIndex) / 2)
    }

    if (activeListIndex < 1) {
      activeListIndex = 1
    }
    if (activeListIndex > this.fragments.length) {
      activeListIndex = this.fragments.length
    }
    return this.normalizedFragmentIndex(activeListIndex - 1)
  }

  private drawGraphCanvas(): void {
    let width: number = this.graphCanvasContext.width
    let height: number = this.graphCanvasContext.height
    if (width <= 0 || height <= 0) {
      return
    }

    this.graphCanvasContext.clearRect(0, 0, width, height)
    this.drawGraphCanvasEdges(width, height)
    this.drawGraphCanvasNodes(width, height)
    this.drawGraphCanvasLabels(width, height)
  }

  private drawGraphCanvasEdges(width: number, height: number): void {
    for (let i: number = 0; i < this.graphEdges.length; i++) {
      let edge: GraphEdge = this.graphEdges[i]
      let from: GraphNode = this.graphNodeByKey(edge.fromKey)
      let to: GraphNode = this.graphNodeByKey(edge.toKey)
      let active: boolean = this.isGraphEdgeActive(edge)
      let fromX: number = this.graphCanvasX(from, width)
      let fromY: number = this.graphCanvasY(from, height)
      let toX: number = this.graphCanvasX(to, width)
      let toY: number = this.graphCanvasY(to, height)
      let dx: number = toX - fromX
      let dy: number = toY - fromY
      let controlX: number = (fromX + toX) / 2 - dy * 0.18
      let controlY: number = (fromY + toY) / 2 + dx * 0.18

      // Draw soft graph curves first; selected relations become darker and thicker.
      this.graphCanvasContext.beginPath()
      this.graphCanvasContext.moveTo(fromX, fromY)
      this.graphCanvasContext.quadraticCurveTo(controlX, controlY, toX, toY)
      this.graphCanvasContext.strokeStyle = active ? BoxStyle.GRAPH_ACTIVE : BoxStyle.GRAPH_IDLE
      this.graphCanvasContext.lineWidth = active ? 4 : 1.1
      this.graphCanvasContext.stroke()
    }
  }

  private drawGraphCanvasNodes(width: number, height: number): void {
    for (let i: number = 0; i < this.graphNodes.length; i++) {
      let node: GraphNode = this.graphNodes[i]
      let related: boolean = this.isGraphNodeRelated(node)
      this.graphCanvasContext.beginPath()
      this.graphCanvasContext.arc(this.graphCanvasX(node, width), this.graphCanvasY(node, height), this.graphNodeRadius, 0, Math.PI * 2)
      this.graphCanvasContext.fillStyle = node.key === this.activeGraphNodeKey ? '#3f4440' : this.getToneColor(node.tone)
      this.graphCanvasContext.globalAlpha = related ? 0.96 : 0.34
      this.graphCanvasContext.fill()
      this.graphCanvasContext.globalAlpha = 1
      if (related) {
        this.graphCanvasContext.beginPath()
        this.graphCanvasContext.arc(this.graphCanvasX(node, width), this.graphCanvasY(node, height), this.graphNodeRadius, 0, Math.PI * 2)
        this.graphCanvasContext.strokeStyle = node.key === this.activeGraphNodeKey ? 'rgba(49, 53, 50, 0.72)' : 'rgba(90, 98, 91, 0.42)'
        this.graphCanvasContext.lineWidth = node.key === this.activeGraphNodeKey ? 2.4 : 1.4
        this.graphCanvasContext.stroke()
      }
    }
  }

  private drawGraphCanvasLabels(width: number, height: number): void {
    this.graphCanvasContext.font = '13px sans-serif'
    this.graphCanvasContext.textAlign = 'center'
    this.graphCanvasContext.textBaseline = 'top'
    for (let i: number = 0; i < this.graphNodes.length; i++) {
      let node: GraphNode = this.graphNodes[i]
      this.graphCanvasContext.fillStyle = this.isGraphNodeRelated(node) ? BoxStyle.TEXT_SOFT : BoxStyle.TEXT_MUTED
      this.graphCanvasContext.fillText(this.graphNodeKeyword(node), this.graphCanvasX(node, width), this.graphCanvasY(node, height) + this.graphNodeRadius + 8, 76)
    }
  }

  private handleGraphCanvasTouch(event: TouchEvent): void {
    if (event.type !== TouchType.Down || event.touches.length === 0) {
      return
    }
    let touchX: number = event.touches[0].x
    let touchY: number = event.touches[0].y
    let width: number = this.graphCanvasContext.width
    let height: number = this.graphCanvasContext.height
    for (let i: number = 0; i < this.graphNodes.length; i++) {
      let node: GraphNode = this.graphNodes[i]
      let dx: number = touchX - this.graphCanvasX(node, width)
      let dy: number = touchY - this.graphCanvasY(node, height)
      if (Math.sqrt(dx * dx + dy * dy) <= this.graphNodeRadius + 8) {
        this.selectGraphNode(node)
        return
      }
    }
  }

  private selectGraphNode(node: GraphNode): void {
    this.activeGraphNodeKey = node.key
    if (node.fragmentIndex >= 0 && node.fragmentIndex < this.fragments.length) {
      this.activeIndex = node.fragmentIndex
    }
    this.drawGraphCanvas()
  }

  @Builder
  AppBackground() {
    Stack() {
      // 纸面颗粒与极淡轨道，承担统一视觉质感，不参与交互。
      Circle()
        .width(420)
        .height(420)
        .fill('rgba(255, 255, 255, 0.36)')
        .stroke('rgba(196, 199, 190, 0.38)')
        .strokeWidth(1)
        .position({ x: -238, y: 250 })

      Circle()
        .width(250)
        .height(250)
        .fill('rgba(104, 114, 103, 0.10)')
        .position({ x: 210, y: 382 })

      Circle()
        .width(230)
        .height(230)
        .fill('rgba(255, 255, 255, 0.54)')
        .position({ x: 88, y: 130 })

      Circle().width(4).height(4).fill('rgba(48, 50, 49, 0.12)').position({ x: 70, y: 88 })
      Circle().width(3).height(3).fill('rgba(48, 50, 49, 0.08)').position({ x: 245, y: 118 })
      Circle().width(5).height(5).fill('rgba(48, 50, 49, 0.10)').position({ x: 112, y: 308 })
      Circle().width(3).height(3).fill('rgba(48, 50, 49, 0.08)').position({ x: 306, y: 510 })
      Circle().width(5).height(5).fill('rgba(48, 50, 49, 0.09)').position({ x: 52, y: 648 })
      Circle().width(3).height(3).fill('rgba(48, 50, 49, 0.07)').position({ x: 268, y: 692 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  BrandBadge() {
    Text('BOX')
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor('#F8F7F1')
      .letterSpacing(3)
      .height(38)
      .lineHeight(38)
      .padding({ left: 15, right: 15 })
      .backgroundColor('#232620')
      .border({ width: 1, color: 'rgba(35, 38, 32, 0.18)' })
      .borderRadius(19)
      .shadow({ radius: 16, color: 'rgba(35, 38, 32, 0.14)', offsetX: 0, offsetY: 7 })
  }

  @Builder
  BoxPage() {
    Stack() {
      Column() {
        Row() {
          Blank()
        }
        .width('100%')
        .height(38)

        Blank()

        Column() {
          this.BoxArt()

          Text('记录碎片')
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
            .fontColor(BoxStyle.TEXT)
            .letterSpacing(2)
            .margin({ top: 34 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('A quiet place for stray thoughts')
            .fontSize(12)
            .fontColor('#7D837B')
            .letterSpacing(0.2)
            .margin({ top: 9 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.openInputSheet()
        })

        Blank()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 26, right: 26, top: 42, bottom: 88 })
  }

  @Builder
  BoxArt() {
    Stack({ alignContent: Alignment.Center }) {
      Ellipse()
        .width(258)
        .height(38)
        .fill('rgba(34, 37, 32, 0.18)')
        .blur(13)
        .translate({ y: 108 })

      Stack({ alignContent: Alignment.Center }) {
        // A single paper puzzle piece: direct fragment metaphor, no box or note props.
        Path({ width: 286, height: 286, commands: 'M82 54 L124 54 C124 34 140 20 158 20 C176 20 192 34 192 54 L236 54 C248 54 258 64 258 76 L258 124 C236 124 222 140 222 158 C222 176 236 192 258 192 L258 236 C258 248 248 258 236 258 L190 258 C190 236 174 222 156 222 C138 222 122 236 122 258 L82 258 C70 258 60 248 60 236 L60 190 C38 190 24 174 24 156 C24 138 38 122 60 122 L60 76 C60 64 70 54 82 54 Z' })
          .fill('#EFE4BC')
          .stroke('rgba(35, 38, 32, 0.24)')
          .strokeWidth(1.5)
          .shadow({ radius: 30, color: 'rgba(35, 38, 32, 0.18)', offsetX: 0, offsetY: 15 })

        Path({ width: 286, height: 286, commands: 'M82 54 L124 54 C124 34 140 20 158 20 C176 20 192 34 192 54 L236 54 C248 54 258 64 258 76 L258 124 C236 124 222 140 222 158 C222 176 236 192 258 192 L258 236 C258 248 248 258 236 258 L190 258 C190 236 174 222 156 222 C138 222 122 236 122 258 L82 258 C70 258 60 248 60 236 L60 190 C38 190 24 174 24 156 C24 138 38 122 60 122 L60 76 C60 64 70 54 82 54 Z' })
          .fill('rgba(255, 255, 255, 0.16)')
          .stroke('rgba(255, 255, 255, 0.12)')
          .strokeWidth(1)
          .translate({ x: -4, y: -5 })

        Rect()
          .width(100)
          .height(2)
          .radius(1)
          .fill('rgba(62, 68, 58, 0.24)')
          .translate({ x: -6, y: -22 })

        Rect()
          .width(132)
          .height(2)
          .radius(1)
          .fill('rgba(62, 68, 58, 0.18)')
          .translate({ x: 7, y: 0 })

        Rect()
          .width(86)
          .height(2)
          .radius(1)
          .fill('rgba(62, 68, 58, 0.15)')
          .translate({ x: -16, y: 22 })

        Circle()
          .width(9)
          .height(9)
          .fill('rgba(62, 72, 58, 0.24)')
          .translate({ x: 62, y: -58 })

        Circle()
          .width(6)
          .height(6)
          .fill('rgba(62, 72, 58, 0.20)')
          .translate({ x: -78, y: 58 })
      }
      .width(286)
      .height(286)
    }
    .width(336)
    .height(300)
  }

  @Builder
  CollectionPage() {
    Stack() {
      Stack() {
        this.WaterfallBackground()
      }
      .width('100%')
      .height('100%')
        .zIndex(0)

      if (!this.graphMode) {
        Stack() {
          this.WaterfallOrbitLines()
        }
        .width('100%')
        .height('100%')
          .zIndex(1)
      }

      if (this.graphMode) {
        Stack() {
          this.PersonalGraph()
        }
        .width('100%')
        .height('100%')
          .zIndex(2)
      } else {
        Stack() {
          this.FragmentWaterfallPage()
        }
        .width('100%')
        .height('100%')
          .zIndex(2)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  WaterfallBackground() {
    Stack() {
      Circle()
        .width(430)
        .height(430)
        .fill('rgba(255, 255, 255, 0.18)')
        .stroke('rgba(204, 206, 200, 0.42)')
        .strokeWidth(1)
        .position({ x: -282, y: 176 })

      Circle()
        .width(226)
        .height(226)
        .fill('rgba(255, 255, 255, 0.42)')
        .position({ x: 136, y: 166 })

      Circle()
        .width(220)
        .height(220)
        .fill('rgba(151, 161, 156, 0.07)')
        .position({ x: 238, y: 520 })

      Circle().width(5).height(5).fill('rgba(46, 48, 47, 0.12)').position({ x: 92, y: 152 })
      Circle().width(4).height(4).fill('rgba(46, 48, 47, 0.10)').position({ x: 248, y: 210 })
      Circle().width(6).height(6).fill('rgba(46, 48, 47, 0.12)').position({ x: 146, y: 386 })
      Circle().width(4).height(4).fill('rgba(46, 48, 47, 0.08)').position({ x: 306, y: 634 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  WaterfallOrbitLines() {
    Stack() {
      Circle()
        .width(470)
        .height(470)
        .fill('rgba(255, 255, 255, 0.00)')
        .stroke('rgba(199, 201, 194, 0.46)')
        .strokeWidth(1)
        .position({ x: -312, y: 276 })

      Circle()
        .width(560)
        .height(560)
        .fill('rgba(255, 255, 255, 0.00)')
        .stroke('rgba(199, 201, 194, 0.24)')
        .strokeWidth(1)
        .position({ x: -360, y: 196 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  FragmentWaterfallPage() {
    Column() {
      this.WaterfallHeader()

      List({ space: 8 }) {
        ListItem() {
          Column() {
            Blank()
              .height(188)
          }
          .width('100%')
        }

        ForEach(this.fragments, (item: FragmentItem) => {
          ListItem() {
            this.FragmentWaterfallItem(item)
          }
        }, (item: FragmentItem) => item.id)

        ListItem() {
          Column() {
            Blank()
              .height(230)
          }
          .width('100%')
        }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .onScrollIndex((firstIndex: number, lastIndex: number, centerIndex?: number) => {
        this.activeIndex = this.waterfallActiveIndex(firstIndex, lastIndex, centerIndex)
      })

      Row() {
        Blank()
        this.WaterfallHintCard()
        Blank()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 8, bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 22, right: 22, top: 50, bottom: 72 })
  }

  @Builder
  WaterfallHeader() {
    Row() {
      Column() {
        Text('我的碎片')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#252729')
          .letterSpacing(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('回看最近留下的记录')
          .fontSize(12)
          .fontColor('#9a9d97')
          .margin({ top: 7 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)

      Button('关系图')
        .width(96)
        .height(40)
        .fontSize(13)
        .fontColor('#343635')
        .padding({ left: 0, right: 0 })
        .backgroundColor('rgba(255, 255, 255, 0.72)')
        .border({ width: 1, color: 'rgba(56, 58, 57, 0.08)' })
        .borderRadius(20)
        .shadow({ radius: 14, color: 'rgba(44, 46, 45, 0.08)', offsetX: 0, offsetY: 7 })
        .onClick(() => {
          this.graphMode = true
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 24 })
  }

  @Builder
  FragmentWaterfallItem(item: FragmentItem) {
    Column() {
      Row() {
        Text(item.id)
          .fontSize(item.id === this.currentFragment().id ? 68 : 56)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.id === this.currentFragment().id ? BoxStyle.TEXT : '#D4D6CF')
          .width(112)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Column() {
          Text(item.tag)
            .fontSize(item.id === this.currentFragment().id ? 19 : 16)
            .fontWeight(FontWeight.Bold)
            .fontColor(item.id === this.currentFragment().id ? BoxStyle.TEXT : '#969A94')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(item.text)
            .fontSize(15)
            .fontColor(item.id === this.currentFragment().id ? BoxStyle.TEXT_SOFT : '#A7AAA4')
            .lineHeight(24)
            .margin({ top: 8 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row() {
            Text(item.shared ? '加入社区' : '仅自己可见')
              .fontSize(11)
              .fontColor(BoxStyle.TEXT_MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(item.remind)
              .fontSize(11)
              .fontColor(BoxStyle.TEXT_MUTED)
              .margin({ left: 16 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .margin({ top: 12 })
        }
        .layoutWeight(1)
        .padding({ left: 8, right: 4 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .height(132)
      .padding({ top: 16, bottom: 16 })
    }
    .width('100%')
    .padding({ left: 10, right: 8 })
    .backgroundColor(item.id === this.currentFragment().id ? 'rgba(255, 255, 255, 0.68)' : 'rgba(255, 255, 255, 0.10)')
    .borderRadius(26)
    .border({ width: 1, color: item.id === this.currentFragment().id ? 'rgba(58, 60, 58, 0.10)' : 'rgba(255, 255, 255, 0.00)' })
    .margin({ bottom: 4 })
    .shadow({ radius: item.id === this.currentFragment().id ? 16 : 0, color: 'rgba(44, 46, 45, 0.07)', offsetX: 0, offsetY: 7 })
    .animation({ duration: BoxStyle.MOTION_FAST, curve: Curve.EaseOut })
    .onClick(() => {
      this.activeIndex = this.fragmentIndexById(item.id)
    })
  }

  @Builder
  WaterfallHintCard() {
    Text('停在中间的碎片会被选中')
      .fontSize(14)
      .fontColor('#767974')
      .textAlign(TextAlign.Center)
      .width('100%')
      .height(48)
      .lineHeight(48)
      .padding({ left: 18, right: 18 })
      .backgroundColor('rgba(255, 255, 255, 0.72)')
      .border({ width: 1, color: 'rgba(56, 58, 57, 0.08)' })
      .borderRadius(26)
      .shadow({ radius: 14, color: 'rgba(44, 46, 45, 0.06)', offsetX: 0, offsetY: 7 })
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }

  @Builder
  PersonalGraph() {
    Column() {
      this.GraphHeader()
      this.GraphCard()

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
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()

        Button('返回碎片 +')
          .width(112)
          .height(38)
          .fontSize(13)
          .fontColor('#3d403d')
          .padding({ left: 0, right: 0 })
          .backgroundColor('rgba(255, 255, 255, 0.76)')
          .border({ width: 1, color: 'rgba(56, 58, 57, 0.08)' })
          .borderRadius(19)
          .shadow({ radius: 18, color: 'rgba(44, 46, 45, 0.10)', offsetX: 0, offsetY: 8 })
          .onClick(() => {
            this.graphMode = false
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Row() {
        Text('点击节点查看关系')
          .fontSize(12)
          .fontColor('#747873')
          .height(30)
          .lineHeight(30)
          .padding({ left: 12, right: 12 })
          .backgroundColor('rgba(255, 255, 255, 0.70)')
          .border({ width: 1, color: 'rgba(56, 58, 57, 0.08)' })
          .borderRadius(15)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
  }

  @Builder
  GraphCard() {
    Stack() {
      Canvas(this.graphCanvasContext)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.drawGraphCanvas()
      })
      .onTouch((event: TouchEvent) => {
        this.handleGraphCanvasTouch(event)
      })
    }
    .width('100%')
    .height(520)
    .margin({ top: 18 })
    .backgroundColor(BoxStyle.SOFT_PANEL)
    .border({ width: 1, color: 'rgba(55, 57, 56, 0.05)' })
    .borderRadius(26)
    .clip(true)
  }

  @Builder
  CommunityPage() {
    Stack() {
      Circle()
        .width(420)
        .height(420)
        .fill('rgba(255, 255, 255, 0.24)')
        .stroke('rgba(204, 206, 200, 0.32)')
        .strokeWidth(1)
        .position({ x: -250, y: 118 })
        .zIndex(0)

      Circle()
        .width(230)
        .height(230)
        .fill('rgba(151, 161, 156, 0.07)')
        .position({ x: 224, y: 520 })
        .zIndex(0)

      Column() {
        this.TopBar('碎片社区发散', 'Community branches', false)

        Text('选择一个自己的碎片，从它开始查看别人共享出的相似、相反或行动经验。')
          .fontSize(13)
          .fontColor(BoxStyle.TEXT_MUTED)
          .lineHeight(20)
          .margin({ top: 6, bottom: 12 })
          .alignSelf(ItemAlign.Start)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        this.StartFragmentSelector()

        this.CommunityTreePanel()
      }
      .width('100%')
      .height('100%')
      .padding({ left: 24, right: 24, top: 34, bottom: 58 })
      .zIndex(2)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CommunityTreePanel() {
    Scroll() {
      Column({ space: 0 }) {
        ForEach(this.getNodesByLevel(), (levelNodes: CommunityNode[], levelIndex: number) => {
          if (levelIndex > 0) {
            this.TreeConnector(levelNodes.length)
          }
          Row({ space: 6 }) {
            ForEach(levelNodes, (node: CommunityNode) => {
              this.TreeNodeCard(node, levelIndex, this.getTreeMaxDepth(), levelNodes.length)
            }, (node: CommunityNode) => node.key)
          }
          .width('100%')
          .height(levelIndex === 0 ? 78 : this.treeNodeHeight(levelIndex) + 12)
          .justifyContent(levelNodes.length <= 1 ? FlexAlign.Center : FlexAlign.SpaceEvenly)
          .alignItems(VerticalAlign.Center)
        }, (levelNodes: CommunityNode[], levelIndex: number) => levelIndex.toString())

        Text('点击末端节点，继续展开新的共享碎片')
          .fontSize(12)
          .fontColor(BoxStyle.TEXT_MUTED)
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(42)
          .lineHeight(42)
          .margin({ top: 12 })
          .backgroundColor('rgba(255, 255, 255, 0.56)')
          .border({ width: 1, color: 'rgba(55, 57, 55, 0.05)' })
          .borderRadius(21)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: 0, right: 0, top: 26, bottom: 28 })
    }
    .width('100%')
    .layoutWeight(1)
    .margin({ top: 12 })
    .backgroundColor('rgba(241, 242, 237, 0.90)')
    .border({ width: 1, color: 'rgba(55, 57, 55, 0.07)' })
    .borderRadius(28)
    .scrollBar(BarState.Off)
    .clip(true)
  }

  @Builder
  CommunityOrbitPanel() {
    Column({ space: 14 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Path({ width: 312, height: 300, commands: 'M156 142 C112 104 84 72 56 70 M156 142 C178 74 214 38 260 62 M156 142 C218 134 254 104 286 122 M156 142 C204 188 224 218 262 238 M156 142 C112 184 76 210 46 242 M156 142 C146 194 152 224 176 256' })
          .fill('rgba(255, 255, 255, 0.00)')
          .stroke('rgba(118, 124, 116, 0.24)')
          .strokeWidth(1.2)
          .position({ x: 0, y: 0 })

        Ellipse()
          .width(292)
          .height(278)
          .fill('rgba(255, 255, 255, 0.00)')
          .stroke('rgba(158, 163, 154, 0.32)')
          .strokeWidth(1)
          .position({ x: 10, y: 10 })

        Ellipse()
          .width(236)
          .height(218)
          .fill('rgba(255, 255, 255, 0.00)')
          .stroke('rgba(184, 188, 180, 0.34)')
          .strokeWidth(1)
          .position({ x: 38, y: 42 })

        Ellipse()
          .width(168)
          .height(154)
          .fill('rgba(255, 255, 255, 0.00)')
          .stroke('rgba(202, 205, 198, 0.42)')
          .strokeWidth(1)
          .position({ x: 72, y: 72 })

        this.CommunityOrbitNode(this.getCommunityNode('similar'), 10, 54, 102, 60)
        this.CommunityOrbitNode(this.getCommunityNode('opposite'), 112, 20, 104, 60)
        this.CommunityOrbitNode(this.getCommunityNode('action'), 218, 84, 86, 56)
        this.CommunityOrbitNode(this.getCommunityNode('city'), 22, 210, 98, 56)
        this.CommunityOrbitNode(this.getCommunityNode('metaphor'), 136, 224, 104, 56)
        this.CommunityOrbitNode(this.getCommunityNode('reply'), 216, 178, 88, 56)

        this.CommunityRootNode()
      }
      .width('100%')
      .height(300)

      this.CommunityDetailCard()
    }
    .width('100%')
    .layoutWeight(1)
    .margin({ top: 12 })
    .padding({ left: 14, right: 14, top: 18, bottom: 16 })
    .backgroundColor(BoxStyle.SOFT_PANEL)
    .border({ width: 1, color: BoxStyle.HAIRLINE })
    .borderRadius(28)
    .clip(true)
  }

  @Builder
  CommunityRootNode() {
    Column() {
      Text(this.currentFragment().tag)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(BoxStyle.TEXT)
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text('当前碎片')
        .fontSize(10)
        .fontColor(BoxStyle.TEXT_MUTED)
        .margin({ top: 6 })
    }
    .width(142)
    .height(66)
    .padding({ left: 12, right: 12, top: 12, bottom: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(22)
    .border({ width: 1, color: 'rgba(58, 62, 58, 0.16)' })
    .shadow({ radius: 24, color: 'rgba(43, 45, 44, 0.14)', offsetX: 0, offsetY: 10 })
    .position({ x: 85, y: 112 })
    .onClick(() => {
      this.selectCommunityNode('root')
    })
  }

  @Builder
  CommunityOrbitNode(node: CommunityNode, x: number, y: number, w: number, h: number) {
    Column() {
      Text(node.title)
        .fontSize(this.activeCommunityKey === node.key ? 12 : 11)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.activeCommunityKey === node.key ? BoxStyle.TEXT : '#626760')
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(node.author)
        .fontSize(9)
        .fontColor(BoxStyle.TEXT_MUTED)
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 5 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(w)
    .height(h)
    .padding({ left: 8, right: 8, top: 10, bottom: 8 })
    .backgroundColor(this.activeCommunityKey === node.key ? '#FFFFFF' : 'rgba(250, 250, 246, 0.74)')
    .borderRadius(18)
    .border({ width: 1, color: this.activeCommunityKey === node.key ? 'rgba(62, 66, 61, 0.22)' : 'rgba(62, 66, 61, 0.08)' })
    .shadow({ radius: this.activeCommunityKey === node.key ? 20 : 8, color: this.activeCommunityKey === node.key ? 'rgba(43, 45, 44, 0.13)' : 'rgba(43, 45, 44, 0.05)', offsetX: 0, offsetY: 7 })
    .position({ x: x, y: y })
    .animation({ duration: BoxStyle.MOTION_FAST, curve: Curve.EaseOut })
    .onClick(() => {
      this.selectCommunityNode(node.key)
    })
  }

  @Builder
  CommunityDetailCard() {
    Column({ space: 7 }) {
      Row() {
        Text(this.activeCommunityKey === 'root' ? '我的 Box' : this.getCommunityNode(this.activeCommunityKey).author)
          .fontSize(11)
          .fontColor(BoxStyle.TEXT_MUTED)
          .height(24)
          .lineHeight(24)
          .padding({ left: 10, right: 10 })
          .backgroundColor('rgba(238, 239, 235, 0.92)')
          .borderRadius(12)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()

        Text(this.activeCommunityKey === 'root' ? '延伸起点' : this.getCommunityNode(this.activeCommunityKey).match)
          .fontSize(11)
          .fontColor('#787D75')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.activeCommunityKey === 'root' ? this.currentFragment().tag : this.getCommunityNode(this.activeCommunityKey).title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(BoxStyle.TEXT)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(this.activeCommunityKey === 'root' ? this.currentFragment().text : this.getCommunityNode(this.activeCommunityKey).text)
        .fontSize(13)
        .fontColor(BoxStyle.TEXT_SOFT)
        .lineHeight(20)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Row({ space: 10 }) {
        Button('收进 Box')
          .layoutWeight(1)
          .height(34)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .padding({ left: 0, right: 0 })
          .backgroundColor('#383B38')
          .borderRadius(18)
          .onClick(() => {
            this.showNotice('已收进 Box')
          })

        Button('继续延伸')
          .layoutWeight(1)
          .height(34)
          .fontSize(12)
          .fontColor('#454A43')
          .padding({ left: 0, right: 0 })
          .backgroundColor('rgba(255, 255, 255, 0.74)')
          .border({ width: 1, color: BoxStyle.HAIRLINE })
          .borderRadius(18)
          .onClick(() => {
            this.selectCommunityNode(this.activeCommunityKey)
            this.showNotice('已展开新的延伸分支')
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('rgba(255, 255, 255, 0.86)')
    .border({ width: 1, color: 'rgba(55, 57, 55, 0.06)' })
    .borderRadius(24)
    .shadow({ radius: 20, color: 'rgba(44, 46, 45, 0.08)', offsetX: 0, offsetY: 9 })
  }

  @Builder
  StartFragmentSelector() {
    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
      ForEach(this.fragments, (item: FragmentItem) => {
        this.StartFragmentPill(item)
      }, (item: FragmentItem) => item.id)
    }
    .width('100%')
    .height(82)
    .padding({ left: 1, right: 1, top: 1, bottom: 1 })
  }

  @Builder
  StartFragmentPill(item: FragmentItem) {
    Text(item.id + ' / ' + item.tag)
      .fontSize(12)
      .fontColor(item.id === this.currentFragment().id ? BoxStyle.TEXT : BoxStyle.TEXT_MUTED)
      .textAlign(TextAlign.Center)
      .height(34)
      .lineHeight(34)
      .padding({ left: 12, right: 12 })
      .backgroundColor(item.id === this.currentFragment().id ? '#FFFFFF' : 'rgba(255, 255, 255, 0.46)')
      .border({ width: 1, color: item.id === this.currentFragment().id ? 'rgba(64, 68, 64, 0.18)' : BoxStyle.HAIRLINE })
      .borderRadius(18)
      .margin({ right: 8, bottom: 8 })
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .onClick(() => {
        this.activeIndex = this.fragmentIndexById(item.id)
        this.activeCommunityKey = 'root'
        this.expandedCommunityKeys = ['root']
      })
  }

  // Returns the max depth (0-indexed) of the visible tree
  private getTreeMaxDepth(): number {
    let levels: CommunityNode[][] = this.getNodesByLevel()
    return levels.length - 1
  }

  @Builder
  TreeConnector(count: number) {
    Column() {
      Rect()
        .width(1.2)
        .height(24)
        .radius(1)
        .fill('rgba(118, 123, 116, 0.22)')

      Row() {
        Blank()
        Rect()
          .width(count <= 1 ? 1.2 : '58%')
          .height(1.2)
          .radius(1)
          .fill('rgba(118, 123, 116, 0.18)')
        Blank()
      }
      .width('100%')

      Rect()
        .width(1.2)
        .height(22)
        .radius(1)
        .fill('rgba(118, 123, 116, 0.18)')
    }
    .width('100%')
    .height(52)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  TreeNodeCard(node: CommunityNode, depth: number, maxDepth: number, count: number) {
    Column() {
      Text(node.key === 'root' ? this.currentFragment().tag : node.title)
        .fontSize(this.treeTitleSize(depth))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.activeCommunityKey === node.key ? BoxStyle.TEXT : '#686D66')
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(node.key === 'root' ? '当前碎片' : (this.childrenOf(node.key).length > 0 ? '已展开' : '继续展开'))
        .fontSize(depth >= 3 ? 8 : 9)
        .fontColor(BoxStyle.TEXT_MUTED)
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
    }
    .width(this.treeNodeWidth(depth, count))
    .height(this.treeNodeHeight(depth))
    .padding({ left: depth >= 2 ? 6 : 10, right: depth >= 2 ? 6 : 10, top: depth >= 2 ? 8 : 11, bottom: depth >= 2 ? 8 : 10 })
    .backgroundColor(this.activeCommunityKey === node.key ? '#FFFFFF' : 'rgba(250, 250, 246, 0.74)')
    .borderRadius(18)
    .border({ width: 1, color: this.activeCommunityKey === node.key ? 'rgba(64, 68, 64, 0.20)' : 'rgba(55, 57, 55, 0.06)' })
    .shadow({ radius: this.activeCommunityKey === node.key ? 18 : 4, color: this.activeCommunityKey === node.key ? 'rgba(43, 45, 44, 0.11)' : 'rgba(43, 45, 44, 0.035)', offsetX: 0, offsetY: 6 })
    .animation({ duration: BoxStyle.MOTION_FAST, curve: Curve.EaseOut })
    .onClick(() => {
      this.selectCommunityNode(node.key)
    })
  }

  private communityNodeBg(tone: string): string {
    if (tone === 'blue') {
      return 'rgba(141, 159, 178, 0.18)'
    }
    if (tone === 'green') {
      return 'rgba(150, 164, 143, 0.18)'
    }
    if (tone === 'rose') {
      return 'rgba(170, 150, 153, 0.18)'
    }
    if (tone === 'slate') {
      return 'rgba(152, 155, 155, 0.18)'
    }
    return 'rgba(255, 255, 255, 0.82)'
  }

  private getNodesByLevel(): CommunityNode[][] {
    let levels: CommunityNode[][] = []
    let root: CommunityNode = this.communityNodes[0]
    let currentLevel: CommunityNode[] = [root]
    while (currentLevel.length > 0) {
      levels.push(currentLevel)
      let nextLevel: CommunityNode[] = []
      for (let node of currentLevel) {
        if (this.isExpanded(node.key)) {
          let children: CommunityNode[] = this.childrenOf(node.key)
          for (let child of children) {
            nextLevel.push(child)
          }
        }
      }
      currentLevel = nextLevel
    }
    return levels
  }

  @Builder
  TopBar(title: string, subtitle: string, showGraphButton: boolean) {
    Column() {
      Row() {
        if (showGraphButton) {
          this.BrandBadge()
        } else {
          Text(title)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#353637')
        }

        Blank()

        if (showGraphButton) {
          Button(this.graphMode ? '◎' : '↘')
            .width(46)
            .height(46)
            .fontSize(21)
            .fontColor('#3f4140')
            .backgroundColor('rgba(255, 255, 255, 0.74)')
            .borderRadius(23)
            .shadow({ radius: 22, color: 'rgba(39, 40, 41, 0.10)', offsetX: 0, offsetY: 10 })
            .onClick(() => {
              this.graphMode = !this.graphMode
            })
        }
      }
      .width('100%')

      if (showGraphButton) {
        Text(title)
          .fontSize(this.graphMode ? 28 : 12)
          .fontWeight(this.graphMode ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.graphMode ? '#333536' : '#babbb6')
          .letterSpacing(this.graphMode ? 0 : 1)
          .margin({ top: this.graphMode ? 24 : 12 })
      }

      Text(subtitle)
        .fontSize(showGraphButton ? 13 : 14)
        .fontColor('#8e918b')
        .lineHeight(22)
        .margin({ top: showGraphButton ? 6 : 8 })
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
  }

  @Builder
  InputSheet() {
    Column({ space: 20 }) {
      // 原生半模态内容：只承载输入、Tag、提醒偏好和完成动作。
      Row() {
        Text('记录碎片')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(BoxStyle.TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('×')
          .width(42)
          .height(42)
          .fontSize(25)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6C706A')
          .textAlign(TextAlign.Center)
          .backgroundColor('rgba(241, 241, 238, 0.86)')
          .border({ width: 1, color: BoxStyle.HAIRLINE })
          .borderRadius(21)
          .onClick(() => {
            this.closeInputSheet()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      TextArea({ placeholder: '写下刚刚想到的内容...', text: this.draftContent })
        .width('100%')
        .height(138)
        .fontSize(16)
        .fontColor(BoxStyle.TEXT)
        .placeholderColor('#A4A7A1')
        .backgroundColor('rgba(243, 243, 240, 0.92)')
        .border({ width: 1, color: 'rgba(55, 57, 55, 0.05)' })
        .borderRadius(18)
        .padding({ left: 18, right: 18, top: 16, bottom: 16 })
        .onChange((value: string) => {
          this.draftContent = value
        })

      Column({ space: 8 }) {
        Text('标签')
          .fontSize(13)
          .fontColor(BoxStyle.TEXT_MUTED)
          .fontWeight(FontWeight.Medium)
          .width('100%')

        TextInput({ placeholder: '例如：通勤观察、情绪或灵感', text: this.draftTag })
          .width('100%')
          .height(50)
          .fontSize(15)
          .fontColor(BoxStyle.TEXT)
          .placeholderColor('#A4A7A1')
          .backgroundColor('rgba(243, 243, 240, 0.92)')
          .border({ width: 1, color: 'rgba(55, 57, 55, 0.05)' })
          .borderRadius(18)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.draftTag = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 12 }) {
        Text('何时提醒')
          .fontSize(13)
          .fontColor(BoxStyle.TEXT_MUTED)
          .fontWeight(FontWeight.Medium)
          .width('100%')

        Row({ space: 12 }) {
          ForEach(['通勤', '睡前', '周末'], (item: string) => {
            this.RemindPill(item)
          }, (item: string) => item)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 12 }) {
        Row() {
          Text('可见范围')
            .fontSize(13)
            .fontColor(BoxStyle.TEXT_MUTED)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('请选择')
            .fontSize(11)
            .fontColor('#7C817A')
            .textAlign(TextAlign.Center)
            .height(24)
            .lineHeight(24)
            .padding({ left: 9, right: 9 })
            .backgroundColor('rgba(232, 233, 228, 0.82)')
            .borderRadius(12)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)

        Row({ space: 12 }) {
          this.ShareChoicePill('匿名加入社区', true)
          this.ShareChoicePill('仅自己可见', false)
        }
        .width('100%')

        if (this.inputErrorText.length > 0) {
          Text(this.inputErrorText)
            .fontSize(12)
            .fontColor('#8F6258')
            .height(24)
            .lineHeight(24)
            .padding({ left: 12, right: 12 })
            .backgroundColor('rgba(143, 98, 88, 0.08)')
            .borderRadius(12)
            .margin({ top: 2 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Button(this.shareChoiceMade ? '保存碎片' : '先选择可见范围')
        .width('100%')
        .height(56)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .padding({ left: 0, right: 0 })
        .backgroundColor(this.shareChoiceMade ? '#262826' : '#C2C4BE')
        .borderRadius(28)
        .shadow({ radius: this.shareChoiceMade ? 14 : 0, color: 'rgba(38, 40, 38, 0.12)', offsetX: 0, offsetY: 7 })
        .onClick(() => {
          this.archiveFragment()
        })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24, bottom: 34 })
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 30, topRight: 30 })
  }
  @Builder
  RemindPill(item: string) {
    Text(item)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.draftRemind === item ? BoxStyle.SELECTED_TEXT : '#8F928C')
      .textAlign(TextAlign.Center)
      .height(44)
      .lineHeight(44)
      .layoutWeight(1)
      .backgroundColor(this.draftRemind === item ? BoxStyle.SELECTED_SOFT : '#F1F1EE')
      .borderRadius(22)
      .border({ width: 0, color: '#00000000' })
      .onClick(() => {
        this.draftRemind = item
      })
  }

  @Builder
  ShareChoicePill(label: string, value: boolean) {
    Text(label)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.isShareChoiceSelected(value) ? '#2F322F' : '#8F928C')
      .textAlign(TextAlign.Center)
      .height(44)
      .lineHeight(44)
      .layoutWeight(1)
      .backgroundColor(this.isShareChoiceSelected(value) ? 'rgba(226, 228, 222, 0.96)' : '#F1F1EE')
      .border({ width: 1, color: this.isShareChoiceSelected(value) ? 'rgba(68, 72, 67, 0.16)' : 'rgba(55, 57, 55, 0.04)' })
      .borderRadius(22)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .onClick(() => {
        this.shareEnabled = value
        this.shareChoiceMade = true
        this.inputErrorText = ''
      })
  }

  @Builder
  ShareSwitch() {
    Stack() {
      Rect()
        .width(48)
        .height(28)
        .radius(14)
        .fill(this.shareEnabled ? '#393b3a' : '#d9dad4')

      Circle()
        .width(22)
        .height(22)
        .fill('#ffffff')
        .shadow({ radius: 8, color: 'rgba(35, 36, 35, 0.12)', offsetX: 0, offsetY: 3 })
        .position({ x: this.shareEnabled ? 23 : 3, y: 3 })
    }
    .width(48)
    .height(28)
    .onClick(() => {
      this.shareEnabled = !this.shareEnabled
    })
  }

  @Builder
  PageDots() {
    Column() {
      Blank()
      Row() {
        Blank()
        Row() {
          this.PageDot(AppPage.BOX)
          this.PageDot(AppPage.COLLECTION)
          this.PageDot(AppPage.COMMUNITY)
        }
        .height(18)
        .padding({ left: 10, right: 3, top: 6, bottom: 6 })
        .backgroundColor('rgba(255, 255, 255, 0.50)')
        .border({ width: 1, color: 'rgba(55, 57, 55, 0.07)' })
        .borderRadius(15)
        Blank()
      }
      .width('100%')
      .margin({ bottom: 22 })
    }
    .width('100%')
    .height('100%')
    .zIndex(20)
    .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  PageDot(page: AppPage) {
    Rect()
      .width(this.currentPage === page ? 18 : 6)
      .height(6)
      .radius(3)
      .fill(this.currentPage === page ? 'rgba(35, 38, 32, 0.74)' : 'rgba(45, 47, 46, 0.15)')
      .margin({ right: 7 })
  }

  @Builder
  Toast() {
    Column() {
      Blank()
      Row() {
        Blank()
        Text(this.toastText)
          .fontSize(13)
          .fontColor('#F8F8F4')
          .textAlign(TextAlign.Center)
          .padding({ left: 16, right: 16, top: 9, bottom: 9 })
          .backgroundColor('rgba(45, 48, 43, 0.82)')
          .borderRadius(18)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
      }
      .width('100%')
      .padding({ left: 26, right: 26 })
      .margin({ bottom: 92 })
    }
    .width('100%')
    .height('100%')
    .zIndex(120)
    .hitTestBehavior(HitTestMode.Transparent)
  }
}
