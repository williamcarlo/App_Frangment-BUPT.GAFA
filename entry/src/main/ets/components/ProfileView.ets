import { FragmentItem, FragmentVisibility, ReminderPreference } from '../model/FragmentModel';

@Component
export struct ProfileView {
  @Prop fragments: FragmentItem[] = [];

  private publicCount(): number {
    return this.fragments.filter((item: FragmentItem) => item.visibility === FragmentVisibility.COMMUNITY).length;
  }

  private sleepingCount(): number {
    return this.fragments.filter((item: FragmentItem) => item.reminder === ReminderPreference.NONE).length;
  }

  @Builder
  metric(value: string, label: string) {
    Column({ space: 5 }) {
      Text(value)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#6F59D9')
      Text(label)
        .fontSize(12)
        .fontColor('#777382')
    }
    .layoutWeight(1)
    .padding({ top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
  }

  @Builder
  infoLine(content: string) {
    Row({ space: 8 }) {
      Text('·')
        .fontSize(18)
        .fontColor('#6F59D9')
      Text(content)
        .fontSize(15)
        .fontColor('#5F5B68')
        .lineHeight(22)
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        Column({ space: 6 }) {
          Text('我的碎片盒')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222028')
            .width('100%')
          Text('这里没有连续签到，也不会催你整理全部想法。')
            .fontSize(14)
            .fontColor('#777382')
            .width('100%')
        }

        Row({ space: 10 }) {
          this.metric(`${this.fragments.length}`, '全部碎片')
          this.metric(`${this.sleepingCount()}`, '继续沉睡')
          this.metric(`${this.publicCount()}`, '允许接枝')
        }
        .width('100%')

        Column({ space: 12 }) {
          Text('设计边界')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2D2A34')
            .width('100%')

          this.infoLine('默认仅自己可见，公开必须逐条选择。')
          this.infoLine('没有粉丝排行、公开点赞数和无限推荐流。')
          this.infoLine('AI 只建议连接和问题，不替用户完成思考。')
          this.infoLine('未来回响低频、可解释，也可以随时关闭。')
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)

        Column({ space: 12 }) {
          Text('下一阶段')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2D2A34')
            .width('100%')

          this.infoLine('ArkData 本地持久化')
          this.infoLine('Form Kit 桌面回响卡片')
          this.infoLine('Notification Kit 低打扰提醒')
          this.infoLine('端侧语义关联与向量检索')
          this.infoLine('手机记录、平板连接、PC 生长')
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#F0ECFF')
        .borderRadius(22)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 28, bottom: 120 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F7FC')
  }
}
