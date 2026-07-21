import { FragmentItem, FragmentExtension } from '../model/FragmentModel';
import { RelationService } from '../service/RelationService';
import { FragmentCard } from './FragmentCard';

@Component
export struct NetworkView {
  @Prop fragments: FragmentItem[] = [];
  @Prop @Watch('onRequestedIdChanged') requestedId: string = '';
  @State private selectedIndex: number = 0;

  aboutToAppear(): void {
    this.selectRequestedFragment();
  }

  private onRequestedIdChanged(): void {
    this.selectRequestedFragment();
  }

  private selectRequestedFragment(): void {
    if (this.requestedId.length === 0) {
      return;
    }
    const index: number = this.fragments.findIndex((item: FragmentItem) => item.id === this.requestedId);
    if (index >= 0) {
      this.selectedIndex = index;
    }
  }

  private center(): FragmentItem {
    return this.fragments[this.selectedIndex];
  }

  private selfExtensions(): FragmentItem[] {
    return RelationService.buildBundle(this.center(), this.fragments).selfExtensions;
  }

  private communityExtensions(): FragmentExtension[] {
    return RelationService.buildBundle(this.center(), this.fragments).communityExtensions;
  }

  private directionExtensions(): FragmentExtension[] {
    return RelationService.buildBundle(this.center(), this.fragments).directionExtensions;
  }

  @Builder
  extensionCard(title: string, content: string, reason: string, tint: string) {
    Column({ space: 7 }) {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2D2A34')
        .width('100%')
      Text(content)
        .fontSize(14)
        .fontColor('#5F5B68')
        .lineHeight(21)
        .width('100%')
      Text(reason)
        .fontSize(11)
        .fontColor('#8C8996')
        .width('100%')
    }
    .padding(14)
    .width('100%')
    .backgroundColor(tint)
    .borderRadius(18)
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Column({ space: 6 }) {
          Text('延申网络')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222028')
            .width('100%')
          Text('从一条碎片出发，打开不一样的搜索路径。')
            .fontSize(14)
            .fontColor('#777382')
            .width('100%')
        }

        if (this.fragments.length === 0) {
          Text('先记录一条碎片，网络才会开始生长。')
            .fontSize(15)
            .fontColor('#8C8996')
            .padding({ top: 60, bottom: 60 })
        } else {
          Scroll() {
            Row({ space: 8 }) {
              ForEach(this.fragments, (item: FragmentItem, index: number) => {
                Button(`${index + 1}`)
                  .fontSize(13)
                  .fontColor(this.selectedIndex === index ? '#FFFFFF' : '#6F59D9')
                  .backgroundColor(this.selectedIndex === index ? '#6F59D9' : '#F0ECFF')
                  .height(36)
                  .onClick(() => this.selectedIndex = index)
              }, (item: FragmentItem) => item.id)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')

          Column({ space: 10 }) {
            Text('中心碎片')
              .fontSize(13)
              .fontColor('#6F59D9')
              .width('100%')
            FragmentCard({ item: this.center() })
          }
          .width('100%')

          Column({ space: 10 }) {
            Text('内圈｜自我延申')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2D2A34')
              .width('100%')
            Text('我想知道这条想法和过去哪些想法有关。')
              .fontSize(13)
              .fontColor('#777382')
              .width('100%')

            if (this.selfExtensions().length === 0) {
              this.extensionCard('还没有找到个人旧碎片', '继续记录后，相似、相反或延续关系会出现在这里。', '当前规则使用 tag 重合进行匹配', '#F4F2FA')
            } else {
              ForEach(this.selfExtensions(), (item: FragmentItem) => {
                FragmentCard({ item: item })
              }, (item: FragmentItem) => item.id)
            }
          }
          .width('100%')

          Column({ space: 10 }) {
            Text('外圈｜他人延申')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2D2A34')
              .width('100%')
            Text('我想看看别人有没有相似或相反的经验。')
              .fontSize(13)
              .fontColor('#777382')
              .width('100%')

            ForEach(this.communityExtensions(), (item: FragmentExtension) => {
              this.extensionCard(item.title, item.content, item.reason, '#EEF8F4')
            }, (item: FragmentExtension) => item.id)
          }
          .width('100%')

          Column({ space: 10 }) {
            Text('方向延申')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2D2A34')
              .width('100%')
            Text('我想从这条碎片继续长出问题、灵感或行动。')
              .fontSize(13)
              .fontColor('#777382')
              .width('100%')

            ForEach(this.directionExtensions(), (item: FragmentExtension) => {
              this.extensionCard(item.title, item.content, item.reason, '#FFF5EA')
            }, (item: FragmentExtension) => item.id)
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 28, bottom: 120 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F7FC')
  }
}
