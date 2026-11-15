import { Palette } from '../common/Theme';

function formatTime(seconds: number): string {
  if (seconds <= 0) {
    return '0:00';
  }
  const m: number = Math.floor(seconds / 60);
  const s: number = Math.floor(seconds % 60);
  return `${m}:${s < 10 ? '0' : ''}${s}`;
}

/** 全屏播放界面：封面 + 标题 + 进度 + 上一首/播放/下一首 */
@Component
export struct PlayerSheet {
  @Prop title: string = '';
  @Prop artist: string = '';
  @Prop artwork: string = '';
  @Prop playing: boolean = false;
  @Prop progress: number = 0;
  @Prop duration: number = 0;
  @Prop errorText: string = '';
  onClose: () => void = () => {
  };
  onToggle: () => void = () => {
  };
  onNext: () => void = () => {
  };
  onPrev: () => void = () => {
  };
  onSeek: (seconds: number) => void = () => {
  };

  @State private dragValue: number = 0;
  @State private dragging: boolean = false;

  build() {
    Column() {
      // 顶部：收起
      Row() {
        Text('收起')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .padding(12)
          .onClick(() => {
            this.onClose();
          })
        Blank()
      }
      .width('100%')

      Blank()

      // 封面
      if (this.artwork.length > 0) {
        Image(this.artwork)
          .width(260)
          .height(260)
          .borderRadius(16)
          .objectFit(ImageFit.Cover)
      } else {
        Stack() {
          Text('♪').fontSize(80).fontColor('#FFFFFF')
        }
        .width(260)
        .height(260)
        .borderRadius(16)
        .backgroundColor(Palette.accent)
      }

      Text(this.title.length > 0 ? this.title : '未在播放')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 24 })
        .padding({ left: 24, right: 24 })

      Text(this.artist)
        .fontSize(14)
        .fontColor('#B0B0B6')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
        .padding({ left: 24, right: 24 })

      if (this.errorText.length > 0) {
        Text(this.errorText)
          .fontSize(12)
          .fontColor('#FF7B8A')
          .margin({ top: 10 })
          .padding({ left: 24, right: 24 })
          .textAlign(TextAlign.Center)
      }

      // 进度
      Row() {
        Text(formatTime(this.dragging ? this.dragValue : this.progress))
          .fontSize(11)
          .fontColor('#8A8A8E')
          .width(44)
        Slider({
          value: this.dragging ? this.dragValue : this.progress,
          min: 0,
          max: this.duration > 1 ? this.duration : 1,
          style: SliderStyle.OutSet
        })
          .selectedColor('#FFFFFF')
          .trackColor('#3A3A3C')
          .blockColor('#FFFFFF')
          .layoutWeight(1)
          .onChange((value: number, mode: SliderChangeMode) => {
            if (mode === SliderChangeMode.Begin || mode === SliderChangeMode.Moving) {
              this.dragging = true;
              this.dragValue = value;
            } else if (mode === SliderChangeMode.End) {
              this.dragging = false;
              this.onSeek(value);
            }
          })
        Text(formatTime(this.duration))
          .fontSize(11)
          .fontColor('#8A8A8E')
          .width(44)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .margin({ top: 18 })

      // 控制
      Row({ space: 44 }) {
        Text('⏮')
          .fontSize(30)
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.onPrev();
          })
        Text(this.playing ? '⏸' : '▶')
          .fontSize(44)
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.onToggle();
          })
        Text('⏭')
          .fontSize(30)
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.onNext();
          })
      }
      .margin({ top: 22 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#111113')
  }
}
