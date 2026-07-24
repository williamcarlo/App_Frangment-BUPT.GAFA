import { ReminderPreference } from '../model/FragmentModel'
import { BoxStyle } from '../theme/FragmentTheme'

@Component
export struct FragmentInputSheet {
  @Prop draftContent: string = ''
  @Prop draftTag: string = ''
  @Prop draftRemind: ReminderPreference = ReminderPreference.NONE
  @Prop shareEnabled: boolean = false
  @Prop shareChoiceMade: boolean = false
  @Prop aiProcessingEnabled: boolean = false
  @Prop inputErrorText: string = ''
  @Prop operationInProgress: boolean = false
  onContentChange: (value: string) => void = (value: string): void => {
  }
  onTagChange: (value: string) => void = (value: string): void => {
  }
  onReminderChange: (value: ReminderPreference) => void =
    (value: ReminderPreference): void => {
    }
  onShareChange: (value: boolean) => void = (value: boolean): void => {
  }
  onAiProcessingChange: (value: boolean) => void = (value: boolean): void => {
  }
  onClose: () => void = (): void => {
  }
  onSave: () => void = (): void => {
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Row() {
          Text('记录碎片')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(BoxStyle.TEXT)

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
              this.onClose()
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
            this.onContentChange(value)
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
              this.onTagChange(value)
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
            ForEach([
              ReminderPreference.COMMUTE,
              ReminderPreference.BEDTIME,
              ReminderPreference.WEEKEND,
              ReminderPreference.NONE,
              ReminderPreference.RANDOM
            ], (item: ReminderPreference) => {
              this.ReminderPill(item)
            }, (item: ReminderPreference) => item)
          }
          .width('100%')
        }
        .width('100%')

        Column({ space: 10 }) {
          Row() {
            Text('幕后整理')
              .fontSize(13)
              .fontColor(BoxStyle.TEXT_MUTED)
              .fontWeight(FontWeight.Medium)
            Blank()
            Text('每张单独授权')
              .fontSize(11)
              .fontColor('#7C817A')
          }
          .width('100%')

          Row({ space: 12 }) {
            this.AiChoicePill('允许 AI 整理', true)
            this.AiChoicePill('仅保存在本机', false)
          }
          .width('100%')

          Text(this.aiProcessingEnabled ?
            '将把本张内容、标签和提醒偏好发送到你的加密网关；不会上传其他碎片。' :
            '本张内容不会发送给 AI 服务。')
            .fontSize(11)
            .lineHeight(18)
            .fontColor(BoxStyle.TEXT_MUTED)
            .width('100%')
        }
        .width('100%')

        Column({ space: 12 }) {
          Row() {
            Text('可见范围')
              .fontSize(13)
              .fontColor(BoxStyle.TEXT_MUTED)
              .fontWeight(FontWeight.Medium)
            Blank()
            Text('请选择')
              .fontSize(11)
              .fontColor('#7C817A')
              .height(24)
              .lineHeight(24)
              .padding({ left: 9, right: 9 })
              .backgroundColor('rgba(232, 233, 228, 0.82)')
              .borderRadius(12)
          }
          .width('100%')

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
              .maxLines(1)
          }
        }
        .width('100%')

        Button(this.operationInProgress ?
          '正在保存…' : (this.shareChoiceMade ? '保存碎片' : '先选择可见范围'))
          .width('100%')
          .height(56)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(this.shareChoiceMade ? '#262826' : '#C2C4BE')
          .enabled(!this.operationInProgress)
          .borderRadius(28)
          .onClick(() => {
            this.onSave()
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 24, bottom: 34 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 30, topRight: 30 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  ReminderPill(item: ReminderPreference) {
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
      .onClick(() => {
        this.onReminderChange(item)
      })
  }

  @Builder
  ShareChoicePill(label: string, value: boolean) {
    Text(label)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.shareChoiceMade && this.shareEnabled === value ? '#2F322F' : '#8F928C')
      .textAlign(TextAlign.Center)
      .height(44)
      .lineHeight(44)
      .layoutWeight(1)
      .backgroundColor(this.shareChoiceMade && this.shareEnabled === value ?
        'rgba(226, 228, 222, 0.96)' : '#F1F1EE')
      .borderRadius(22)
      .onClick(() => {
        this.onShareChange(value)
      })
  }

  @Builder
  AiChoicePill(label: string, value: boolean) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.aiProcessingEnabled === value ? '#2F322F' : '#8F928C')
      .textAlign(TextAlign.Center)
      .height(42)
      .lineHeight(42)
      .layoutWeight(1)
      .backgroundColor(this.aiProcessingEnabled === value ?
        'rgba(226, 228, 222, 0.96)' : '#F1F1EE')
      .borderRadius(21)
      .onClick(() => {
        this.onAiProcessingChange(value)
      })
  }
}
