import { FragmentItem } from '../model/FragmentModel';
import { ReminderService } from '../service/ReminderService';
import { TimeUtils } from '../utils/TimeUtils';

@Component
export struct EchoCard {
  @Prop item: FragmentItem;

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('来自过去的你')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(TimeUtils.formatDate(this.item.createdAt))
          .fontSize(12)
          .fontColor('#E9E4FF')
      }
      .width('100%')

      Text(`“${this.item.content}”`)
        .fontSize(19)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .lineHeight(28)
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(ReminderService.describe(this.item.reminder).description)
        .fontSize(12)
        .fontColor('#E9E4FF')
        .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#6F59D9')
    .borderRadius(26)
  }
}
