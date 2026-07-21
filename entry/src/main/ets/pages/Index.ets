import { FragmentRepository } from '../data/FragmentRepository';
import { FragmentItem } from '../model/FragmentModel';
import { CaptureSheet } from '../components/CaptureSheet';
import { HomeView } from '../components/HomeView';
import { NetworkView } from '../components/NetworkView';
import { ProfileView } from '../components/ProfileView';

@Entry
@Component
struct Index {
  @State private fragments: FragmentItem[] = FragmentRepository.list();
  @State private showCapture: boolean = false;
  @State private tabIndex: number = 0;
  @State private requestedNetworkId: string = '';

  private reload(): void {
    this.fragments = FragmentRepository.list();
  }

  private openNetwork(id: string): void {
    this.requestedNetworkId = id;
    this.tabIndex = 1;
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Tabs({
        barPosition: BarPosition.End,
        index: this.tabIndex
      }) {
        TabContent() {
          HomeView({
            fragments: this.fragments,
            onCapture: () => this.showCapture = true,
            onOpenNetwork: (id: string) => this.openNetwork(id)
          })
        }
        .tabBar('碎片')

        TabContent() {
          NetworkView({
            fragments: this.fragments,
            requestedId: this.requestedNetworkId
          })
        }
        .tabBar('延申')

        TabContent() {
          ProfileView({ fragments: this.fragments })
        }
        .tabBar('我的')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F7FC')
      .onChange((index: number) => this.tabIndex = index)

      if (!this.showCapture) {
        Button('+', { type: ButtonType.Circle })
          .width(58)
          .height(58)
          .fontSize(30)
          .fontWeight(FontWeight.Light)
          .fontColor('#FFFFFF')
          .backgroundColor('#6F59D9')
          .margin({ right: 22, bottom: 82 })
          .onClick(() => this.showCapture = true)
      }

      if (this.showCapture) {
        CaptureSheet({
          visible: $showCapture,
          onSaved: () => this.reload()
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
