import { CommunityNode } from '../model/CommunityModel'
import { BoxStyle } from '../theme/FragmentTheme'

@Component
export struct CommunityTree {
  @Prop nodes: CommunityNode[] = []
  @Prop activeKey: string = ''
  @Prop expandedKeys: string[] = []
  @Prop rootTitle: string = ''
  @Prop operationInProgress: boolean = false
  onSelect: (nodeId: string) => void = (nodeId: string): void => {
  }
  onSave: () => void = (): void => {
  }
  onContinue: () => void = (): void => {
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        ForEach(this.nodesByLevel(), (levelNodes: CommunityNode[], levelIndex: number) => {
          if (levelIndex > 0) {
            this.TreeConnector(levelNodes.length)
          }
          Row({ space: 6 }) {
            ForEach(levelNodes, (node: CommunityNode) => {
              this.TreeNodeCard(node, levelIndex, levelNodes.length)
            }, (node: CommunityNode) => node.key)
          }
          .width('100%')
          .height(levelIndex === 0 ? 78 : this.nodeHeight(levelIndex) + 12)
          .justifyContent(levelNodes.length <= 1 ? FlexAlign.Center : FlexAlign.SpaceEvenly)
          .alignItems(VerticalAlign.Center)
        }, (levelNodes: CommunityNode[], levelIndex: number) => levelIndex.toString())

        if (this.activeNode().key.length > 0 && this.activeKey !== this.rootKey()) {
          this.ActiveNodeDetail(this.activeNode())
        } else {
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
        }
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
  ActiveNodeDetail(node: CommunityNode) {
    Column({ space: 10 }) {
      Text(node.text)
        .fontSize(13)
        .lineHeight(20)
        .fontColor(BoxStyle.TEXT_SOFT)
        .width('100%')
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: 10 }) {
        Button(node.savedFragmentId.length > 0 ? '已收存' : '收进 Box')
          .layoutWeight(1)
          .height(40)
          .fontSize(13)
          .fontColor(node.savedFragmentId.length > 0 ? BoxStyle.TEXT_MUTED : '#FFFFFF')
          .backgroundColor(node.savedFragmentId.length > 0 ?
            BoxStyle.INPUT_BG : BoxStyle.BUTTON_BG)
          .enabled(node.savedFragmentId.length === 0 && !this.operationInProgress)
          .borderRadius(20)
          .onClick(() => {
            this.onSave()
          })

        Button('从这里继续')
          .layoutWeight(1)
          .height(40)
          .fontSize(13)
          .fontColor(BoxStyle.TEXT_SOFT)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: BoxStyle.HAIRLINE })
          .borderRadius(20)
          .onClick(() => {
            this.onContinue()
          })
      }
      .width('100%')
    }
    .width('94%')
    .padding({ left: 15, right: 15, top: 14, bottom: 14 })
    .margin({ top: 14 })
    .backgroundColor('rgba(255, 255, 255, 0.74)')
    .border({ width: 1, color: BoxStyle.HAIRLINE })
    .borderRadius(20)
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
  TreeNodeCard(node: CommunityNode, depth: number, count: number) {
    Column() {
      Text(node.key === this.rootKey() ? this.rootTitle : node.title)
        .fontSize(depth === 0 ? 14 : Math.max(9, 13 - depth))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.activeKey === node.key ? BoxStyle.TEXT : '#686D66')
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(node.key === this.rootKey() ?
        '当前碎片' : (this.childrenOf(node.key).length > 0 ? '已展开' : '继续展开'))
        .fontSize(depth >= 3 ? 8 : 9)
        .fontColor(BoxStyle.TEXT_MUTED)
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .margin({ top: 6 })
    }
    .width(this.nodeWidth(depth, count))
    .height(this.nodeHeight(depth))
    .padding({ left: depth >= 2 ? 6 : 10, right: depth >= 2 ? 6 : 10,
      top: depth >= 2 ? 8 : 11, bottom: depth >= 2 ? 8 : 10 })
    .backgroundColor(this.activeKey === node.key ? '#FFFFFF' : 'rgba(250, 250, 246, 0.74)')
    .borderRadius(18)
    .border({ width: 1, color: this.activeKey === node.key ?
      'rgba(64, 68, 64, 0.20)' : 'rgba(55, 57, 55, 0.06)' })
    .shadow({ radius: this.activeKey === node.key ? 18 : 4,
      color: this.activeKey === node.key ?
        'rgba(43, 45, 44, 0.11)' : 'rgba(43, 45, 44, 0.035)',
      offsetX: 0, offsetY: 6 })
    .onClick(() => {
      this.onSelect(node.key)
    })
  }

  private rootKey(): string {
    return this.nodes.length > 0 ? this.nodes[0].key : ''
  }

  private activeNode(): CommunityNode {
    for (let i: number = 0; i < this.nodes.length; i++) {
      if (this.nodes[i].key === this.activeKey) {
        return this.nodes[i]
      }
    }
    return new CommunityNode('', '', '', '', '', '', '', '', 0, 0, 0, 0)
  }

  private childrenOf(key: string): CommunityNode[] {
    return this.nodes.filter((item: CommunityNode) => item.parent === key)
  }

  private isExpanded(key: string): boolean {
    return this.expandedKeys.indexOf(key) >= 0
  }

  private nodesByLevel(): CommunityNode[][] {
    let levels: CommunityNode[][] = []
    if (this.nodes.length === 0) {
      return levels
    }
    let currentLevel: CommunityNode[] = [this.nodes[0]]
    while (currentLevel.length > 0) {
      levels.push(currentLevel)
      let nextLevel: CommunityNode[] = []
      for (let i: number = 0; i < currentLevel.length; i++) {
        if (this.isExpanded(currentLevel[i].key)) {
          let children: CommunityNode[] = this.childrenOf(currentLevel[i].key)
          for (let childIndex: number = 0; childIndex < children.length; childIndex++) {
            nextLevel.push(children[childIndex])
          }
        }
      }
      currentLevel = nextLevel
    }
    return levels
  }

  private nodeWidth(depth: number, count: number): number {
    if (count <= 1) {
      return depth === 0 ? 136 : 108
    }
    let fitWidth: number = (306 - (count - 1) * 8) / count
    return Math.max(52, Math.min(Math.max(64, 108 - depth * 10), fitWidth))
  }

  private nodeHeight(depth: number): number {
    return depth === 0 ? 66 : Math.max(52, 66 - depth * 3)
  }
}
