import { FragmentLifecycleAction } from '../model/FragmentModel'
import { BoxStyle } from '../theme/FragmentTheme'

@Component
export struct LifecycleConfirmDialog {
  @Prop title: string = ''
  @Prop action: FragmentLifecycleAction = FragmentLifecycleAction.NONE
  @Prop disabled: boolean = false
  onCancel: () => void = (): void => {
  }
  onConfirm: () => void = (): void => {
  }

  build() {
    Stack() {
      Rect()
        .width('100%')
        .height('100%')
        .fill('rgba(30, 32, 29, 0.28)')
        .onClick(() => {
          this.onCancel()
        })

      Column({ space: 18 }) {
        Text(this.title)
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(BoxStyle.TEXT)
          .width('100%')
          .textAlign(TextAlign.Center)

        Text(this.action === FragmentLifecycleAction.DELETE ?
          '永久删除后无法恢复，相关关系、回响与授权记录也会一并清理。' :
          '操作会立即写入本地数据库，你之后仍可在归档箱或隐私设置中继续管理。')
          .fontSize(13)
          .lineHeight(21)
          .fontColor(BoxStyle.TEXT_MUTED)
          .width('100%')
          .textAlign(TextAlign.Center)

        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .fontSize(14)
            .fontColor(BoxStyle.TEXT_SOFT)
            .backgroundColor(BoxStyle.INPUT_BG)
            .borderRadius(22)
            .onClick(() => {
              this.onCancel()
            })

          Button('确认')
            .layoutWeight(1)
            .height(44)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor(this.action === FragmentLifecycleAction.DELETE ?
              '#8F6258' : BoxStyle.BUTTON_BG)
            .enabled(!this.disabled)
            .borderRadius(22)
            .onClick(() => {
              this.onConfirm()
            })
        }
        .width('100%')
      }
      .width('82%')
      .padding({ left: 22, right: 22, top: 24, bottom: 22 })
      .backgroundColor('#FBFAF6')
      .borderRadius(26)
      .shadow({ radius: 22, color: BoxStyle.SHADOW, offsetX: 0, offsetY: 10 })
    }
    .width('100%')
    .height('100%')
    .zIndex(210)
  }
}
