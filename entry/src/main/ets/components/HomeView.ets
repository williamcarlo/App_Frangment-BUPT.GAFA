import { FragmentItem } from '../model/FragmentModel';
import { EchoCard } from './EchoCard';
import { FragmentCard } from './FragmentCard';

@Component
export struct HomeView {
  @Prop fragments: FragmentItem[] = [];
  onCapture: () => void = () => {};
  onOpenNetwork: (id: string) => void = () => {};

  private echoItem(): FragmentItem | undefined {
    if (this.fragments.length === 0) {
      return undefined;
    }
    return this.fragments[this.fragments.length - 1];
  }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        Column({ space: 8 }) {
          Text('碎片')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222028')
            .width('100%')

          Text('把差一点消失的想法，留给未来的自己。')
            .fontSize(15)
            .fontColor('#777382')
            .width('100%')
        }
        .width('100%')

        Button() {
          Row({ space: 14 }) {
            Text('+')
              .fontSize(28)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Light)
            Column({ space: 4 }) {
              Text('此刻有什么差一点消失？')
                .fontSize(17)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium)
              Text('灵感、观察、复盘、情绪或冲动')
                .fontSize(12)
                .fontColor('#EDE9FF')
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
        }
        .height(76)
        .width('100%')
        .backgroundColor('#8A73EA')
        .borderRadius(24)
        .onClick(() => this.onCapture())

        if (this.echoItem() !== undefined) {
          Column({ space: 10 }) {
            Text('今日回响')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2D2A34')
              .width('100%')
            EchoCard({ item: this.echoItem() as FragmentItem })
          }
          .width('100%')
        }

        Column({ space: 12 }) {
          Row() {
            Text('最近碎片')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2D2A34')
            Blank()
            Text(`${this.fragments.length} 条`)
              .fontSize(13)
              .fontColor('#8C8996')
          }
          .width('100%')

          if (this.fragments.length === 0) {
            Text('这里还很安静。先接住第一条碎片吧。')
              .fontSize(15)
              .fontColor('#8C8996')
              .padding({ top: 30, bottom: 30 })
          } else {
            ForEach(this.fragments, (item: FragmentItem) => {
              FragmentCard({
                item: item,
                onTap: (id: string) => this.onOpenNetwork(id)
              })
            }, (item: FragmentItem) => item.id)
          }
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 28, bottom: 120 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F7FC')
  }
}
