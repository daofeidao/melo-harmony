import { Palette, Sizes } from '../common/Theme';

/** 设置：只有最基本的内容 —— 版本、说明、清理入口。第一版不做登录/音质那些。 */
@Component
export struct SettingsTab {
  onClearRecent: () => void = () => {
  };
  onClearAll: () => void = () => {
  };

  @State private showDisclaimer: boolean = false;

  build() {
    Scroll() {
      Column({ space: 10 }) {
        // 关于
        Column({ space: 4 }) {
          Text('Melo')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Palette.label)
          Text('鸿蒙版 0.1.0')
            .fontSize(13)
            .fontColor(Palette.secondary)
          Text('作者：daofeidao')
            .fontSize(13)
            .fontColor(Palette.secondary)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(Sizes.pagePadding)
        .backgroundColor(Palette.card)
        .borderRadius(12)
        .margin({ top: 12 })

        // 清理
        Column() {
          Row() {
            Text('清空最近播放').fontSize(15).fontColor(Palette.label)
            Blank()
            Text('清空').fontSize(13).fontColor(Palette.danger)
          }
          .width('100%')
          .padding(14)
          .onClick(() => {
            this.onClearRecent();
          })

          Divider().color(Palette.separator).margin({ left: 14 })

          Row() {
            Text('清空全部本地数据').fontSize(15).fontColor(Palette.label)
            Blank()
            Text('清空').fontSize(13).fontColor(Palette.danger)
          }
          .width('100%')
          .padding(14)
          .onClick(() => {
            this.onClearAll();
          })
        }
        .width('100%')
        .backgroundColor(Palette.card)
        .borderRadius(12)

        // 免责声明
        Column() {
          Row() {
            Text('免责声明').fontSize(15).fontColor(Palette.label)
            Blank()
            Text(this.showDisclaimer ? '收起' : '展开')
              .fontSize(13)
              .fontColor(Palette.accent)
          }
          .width('100%')
          .padding(14)
          .onClick(() => {
            this.showDisclaimer = !this.showDisclaimer;
          })

          if (this.showDisclaimer) {
            Text('本软件仅用于个人学习，请下载后在 24 小时内自动删除；如涉及到版权问题，请联系开发者删除。')
              .fontSize(12)
              .fontColor(Palette.secondary)
              .padding({ left: 14, right: 14, bottom: 14 })
          }
        }
        .width('100%')
        .backgroundColor(Palette.card)
        .borderRadius(12)

        Text('第一版说明：目前只接了网易云匿名直链（128k）。登录、无损、歌曲宝人机验证、多音源切换会在后续版本补。')
          .fontSize(12)
          .fontColor(Palette.tertiary)
          .padding({ left: 4, right: 4, top: 6 })

      }
      .width('100%')
      .padding({ left: Sizes.pagePadding, right: Sizes.pagePadding, bottom: 28 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor(Palette.bg)
  }
}
