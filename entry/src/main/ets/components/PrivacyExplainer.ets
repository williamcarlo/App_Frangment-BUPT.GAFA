import { BoxStyle } from '../theme/FragmentTheme'

@Component
export struct PrivacyExplainer {
  onAcknowledge: () => void = (): void => {
  }

  build() {
    Stack() {
      Rect()
        .width('100%')
        .height('100%')
        .fill('rgba(30, 32, 29, 0.34)')

      Column({ space: 16 }) {
        Text($r('app.string.privacy_explainer_title'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(BoxStyle.TEXT)
          .width('100%')

        Text('碎片默认仅保存在本机并仅自己可见。只有你明确选择“匿名加入社区”时，才会写入共享授权；撤回后它会立即退出社区入口。')
          .fontSize(15)
          .lineHeight(24)
          .fontColor(BoxStyle.TEXT_SOFT)
          .width('100%')

        Text('“幕后整理”也按每张碎片单独授权：仅发送当前内容、标签和提醒偏好到你配置的加密网关。其他碎片仍留在本机，社区内容仍为本地演示数据。')
          .fontSize(13)
          .lineHeight(21)
          .fontColor(BoxStyle.TEXT_MUTED)
          .width('100%')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .backgroundColor(BoxStyle.SOFT_PANEL)
          .borderRadius(16)

        Button('知道了，继续')
          .width('100%')
          .height(52)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(BoxStyle.BUTTON_BG)
          .borderRadius(26)
          .onClick(() => {
            this.onAcknowledge()
          })
      }
      .width('86%')
      .padding({ left: 24, right: 24, top: 26, bottom: 24 })
      .backgroundColor('#FBFAF6')
      .borderRadius(28)
      .shadow({ radius: 24, color: BoxStyle.SHADOW, offsetX: 0, offsetY: 12 })
    }
    .width('100%')
    .height('100%')
    .zIndex(200)
  }
}
