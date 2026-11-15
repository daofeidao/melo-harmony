import { Palette } from '../common/Theme';
import { ArtistName } from '../common/ArtistName';
import { Netease } from '../services/Netease';

/**
 * 添加喜欢艺人。
 * 先过本地规则（派生号 / 截断残渣），再查一次网易云艺人库：
 * 命中同名才允许加入；请求失败（返回空）时按本地规则放行，不因为断网就用不了。
 */
@Component
export struct AddArtistSheet {
  onClose: () => void = () => {
  };
  /** 返回 true 表示已加入 */
  onAdd: (name: string) => boolean = () => false;

  @State private input: string = '';
  @State private message: string = '';
  @State private busy: boolean = false;

  private async submit(): Promise<void> {
    const clean: string = ArtistName.primary(this.input);
    this.message = '';
    if (clean.length === 0) {
      return;
    }
    if (!ArtistName.isPlausible(clean)) {
      this.message = '这不像一个艺人名：只填名字本身，别带「电台」「完整版」这类后缀';
      return;
    }
    this.busy = true;
    const found: string[] = await Netease.searchArtists(clean);
    this.busy = false;
    const key: string = ArtistName.key(clean);
    let matched: boolean = false;
    for (const name of found) {
      if (ArtistName.key(name) === key) {
        matched = true;
      }
    }
    if (found.length > 0 && !matched) {
      this.message = `艺人库里没有「${clean}」这位艺人`;
      return;
    }
    if (this.onAdd(clean)) {
      this.onClose();
    } else {
      this.message = `「${clean}」已经在喜欢艺人里了`;
    }
  }

  build() {
    Column() {
      Text('添加喜欢艺人')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Palette.label)
        .margin({ bottom: 14 })

      TextInput({ placeholder: '艺人名字（只要名字本身）', text: this.input })
        .height(42)
        .borderRadius(10)
        .backgroundColor(Palette.bg)
        .onChange((value: string) => {
          this.input = value;
        })
        .onSubmit(() => {
          this.submit();
        })

      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(12)
          .fontColor(Palette.danger)
          .margin({ top: 10 })
      }

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(Palette.bg)
          .fontColor(Palette.label)
          .onClick(() => {
            this.onClose();
          })
        Button(this.busy ? '校验中…' : '添加')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(Palette.accent)
          .enabled(!this.busy)
          .onClick(() => {
            this.submit();
          })
      }
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Palette.card)
    .borderRadius(16)
  }
}
