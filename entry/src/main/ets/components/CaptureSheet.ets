import { FragmentRepository } from '../data/FragmentRepository';
import {
  FragmentDraft,
  FragmentKind,
  FragmentVisibility,
  ReminderPreference
} from '../model/FragmentModel';

@Component
export struct CaptureSheet {
  @Link visible: boolean;
  onSaved: () => void = () => {};

  @State private content: string = '';
  @State private tagText: string = '';
  @State private kindIndex: number = 0;
  @State private reminderIndex: number = 0;
  @State private visibilityIndex: number = 0;

  private kinds: FragmentKind[] = [
    FragmentKind.IDEA,
    FragmentKind.OBSERVATION,
    FragmentKind.REFLECTION,
    FragmentKind.EMOTION,
    FragmentKind.IMPULSE
  ];

  private reminders: ReminderPreference[] = [
    ReminderPreference.NONE,
    ReminderPreference.COMMUTE,
    ReminderPreference.BEFORE_SLEEP,
    ReminderPreference.WEEKEND,
    ReminderPreference.RANDOM
  ];

  private visibilities: FragmentVisibility[] = [
    FragmentVisibility.PRIVATE,
    FragmentVisibility.COMMUNITY
  ];

  private parseTags(): string[] {
    const result: string[] = [];
    const values: string[] = this.tagText.split(',');
    values.forEach((value: string) => {
      const tag: string = value.trim();
      if (tag.length > 0) {
        result.push(tag);
      }
    });
    return result;
  }

  private save(): void {
    if (this.content.trim().length === 0) {
      return;
    }
    const draft: FragmentDraft = {
      content: this.content,
      kind: this.kinds[this.kindIndex],
      tags: this.parseTags(),
      reminder: this.reminders[this.reminderIndex],
      visibility: this.visibilities[this.visibilityIndex]
    };
    FragmentRepository.add(draft);
    this.content = '';
    this.tagText = '';
    this.kindIndex = 0;
    this.reminderIndex = 0;
    this.visibilityIndex = 0;
    this.visible = false;
    this.onSaved();
  }

  build() {
    Column() {
      Blank()
        .onClick(() => this.visible = false)

      Column({ space: 16 }) {
        Row() {
          Column({ space: 4 }) {
            Text('接住一条碎片')
              .fontSize(23)
              .fontWeight(FontWeight.Bold)
              .fontColor('#26232D')
            Text('不需要现在就把它想清楚。')
              .fontSize(13)
              .fontColor('#8C8996')
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Button('取消')
            .fontSize(14)
            .fontColor('#777382')
            .backgroundColor('#F1EFF6')
            .onClick(() => this.visible = false)
        }
        .width('100%')

        TextArea({
          text: this.content,
          placeholder: '写下灵感、观察、复盘、情绪或一个还没完成的念头……'
        })
          .height(138)
          .fontSize(17)
          .backgroundColor('#F8F7FC')
          .borderRadius(18)
          .padding(14)
          .onChange((value: string) => this.content = value)

        Row({ space: 10 }) {
          Column({ space: 6 }) {
            Text('类型').fontSize(12).fontColor('#8C8996').width('100%')
            Select(this.kinds.map((item: FragmentKind) => ({ value: item })))
              .selected(this.kindIndex)
              .onSelect((index: number) => this.kindIndex = index)
              .width('100%')
          }
          .layoutWeight(1)

          Column({ space: 6 }) {
            Text('未来回响').fontSize(12).fontColor('#8C8996').width('100%')
            Select(this.reminders.map((item: ReminderPreference) => ({ value: item })))
              .selected(this.reminderIndex)
              .onSelect((index: number) => this.reminderIndex = index)
              .width('100%')
          }
          .layoutWeight(1)
        }
        .width('100%')

        TextInput({
          text: this.tagText,
          placeholder: '添加 tag，用英文逗号分隔，例如：城市,旅行'
        })
          .height(48)
          .fontSize(15)
          .backgroundColor('#F8F7FC')
          .borderRadius(14)
          .onChange((value: string) => this.tagText = value)

        Column({ space: 8 }) {
          Text('可见范围')
            .fontSize(12)
            .fontColor('#8C8996')
            .width('100%')
          Row({ space: 10 }) {
            ForEach(this.visibilities, (visibility: FragmentVisibility, index: number) => {
              Button(visibility)
                .layoutWeight(1)
                .height(44)
                .fontSize(14)
                .fontColor(this.visibilityIndex === index ? '#FFFFFF' : '#6F59D9')
                .backgroundColor(this.visibilityIndex === index ? '#6F59D9' : '#F0ECFF')
                .onClick(() => this.visibilityIndex = index)
            }, (visibility: FragmentVisibility) => visibility)
          }
          .width('100%')
        }

        Button('保存碎片')
          .width('100%')
          .height(52)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor(this.content.trim().length > 0 ? '#6F59D9' : '#C8C2E4')
          .borderRadius(18)
          .enabled(this.content.trim().length > 0)
          .onClick(() => this.save())
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 22, bottom: 24 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 30, topRight: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
  }
}
