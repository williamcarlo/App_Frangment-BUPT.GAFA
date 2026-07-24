import { FragmentItem } from '../model/FragmentModel'
import { BoxStyle } from '../theme/FragmentTheme'

@Component
export struct EchoCard {
  @Prop item: FragmentItem
  @Prop dateLabel: string = ''
  @Prop reason: string = ''
  onOpen: () => void = (): void => {
  }
  onDismiss: () => void = (): void => {
  }

  build() {
    Column() {
      Column({ space: 8 }) {
        Row() {
          Text('旧碎片回响')
            .fontSize(11)
            .fontColor(BoxStyle.TEXT_MUTED)
            .height(24)
            .lineHeight(24)
            .padding({ left: 10, right: 10 })
            .backgroundColor('rgba(239, 240, 235, 0.92)')
            .borderRadius(12)

          Blank()

          Text(this.dateLabel + ' · ' + this.item.remind)
            .fontSize(11)
            .fontColor(BoxStyle.TEXT_MUTED)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(this.item.tag)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(BoxStyle.TEXT)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.item.text)
          .fontSize(12)
          .fontColor(BoxStyle.TEXT_SOFT)
          .lineHeight(18)
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.reason)
          .fontSize(11)
          .fontColor(BoxStyle.TEXT_MUTED)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 13, bottom: 13 })
      .margin({ top: 24 })
      .backgroundColor('rgba(255, 255, 255, 0.76)')
      .border({ width: 1, color: BoxStyle.HAIRLINE })
      .borderRadius(22)
      .shadow({ radius: 18, color: BoxStyle.SHADOW_SOFT, offsetX: 0, offsetY: 8 })
      .onClick(() => {
        this.onOpen()
      })

      Text('今天先不看')
        .fontSize(11)
        .fontColor(BoxStyle.TEXT_MUTED)
        .height(30)
        .lineHeight(30)
        .padding({ left: 12, right: 12 })
        .margin({ top: 6 })
        .backgroundColor('rgba(255, 255, 255, 0.46)')
        .borderRadius(15)
        .onClick(() => {
          this.onDismiss()
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.End)
  }
}
