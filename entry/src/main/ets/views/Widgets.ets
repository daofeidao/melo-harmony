import { Track } from '../model/Track';
import { Palette, Sizes } from '../common/Theme';
import { Http } from '../services/Http';
import { J } from '../common/Json';

/** 分区标题 */
@Component
export struct SectionTitle {
  private title: string = '';

  build() {
    Row() {
      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Palette.label)
      Blank()
    }
    .width('100%')
    .padding({ left: Sizes.pagePadding, right: Sizes.pagePadding, top: 18, bottom: 8 })
  }
}

/** 一行灰色提示，空分区用 */
@Component
export struct EmptyHint {
  private text: string = '';

  build() {
    Text(this.text)
      .fontSize(12)
      .fontColor(Palette.tertiary)
      .padding({ left: Sizes.pagePadding, right: Sizes.pagePadding })
  }
}

/** 歌曲行：封面 + 歌名/歌手 + 时长 + 收藏心形 */
@Component
export struct TrackRow {
  private track: Track = {
    id: '', title: '', artist: '', album: '', duration: 0,
    artwork: '', source: '', sourceId: ''
  };
  private index: number = 0;
  @Prop favorite: boolean = false;
  private onTap: (track: Track) => void = () => {
  };
  private onToggleFavorite: (track: Track) => void = () => {
  };

  private durationText(): string {
    if (this.track.duration <= 0) {
      return '--:--';
    }
    const m: number = Math.floor(this.track.duration / 60);
    const s: number = this.track.duration % 60;
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  }

  build() {
    Row({ space: 12 }) {
      if (this.track.artwork.length > 0) {
        Image(this.track.artwork)
          .width(Sizes.artwork)
          .height(Sizes.artwork)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
      } else {
        Stack() {
          Text('♪').fontSize(20).fontColor('#FFFFFF')
        }
        .width(Sizes.artwork)
        .height(Sizes.artwork)
        .borderRadius(6)
        .backgroundColor(Palette.accent)
      }

      Column({ space: 3 }) {
        Text(this.track.title)
          .fontSize(15)
          .fontColor(Palette.label)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.track.artist.length > 0 ? this.track.artist : '未知艺人')
          .fontSize(12)
          .fontColor(Palette.secondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(this.durationText())
        .fontSize(12)
        .fontColor(Palette.tertiary)

      Text(this.favorite ? '♥' : '♡')
        .fontSize(20)
        .fontColor(this.favorite ? Palette.accent : Palette.tertiary)
        .padding({ left: 8 })
        .onClick(() => {
          this.onToggleFavorite(this.track);
        })
    }
    .width('100%')
    .padding({ left: Sizes.pagePadding, right: Sizes.pagePadding, top: 8, bottom: 8 })
    .onClick(() => {
      this.onTap(this.track);
    })
  }
}

/** 圆形艺人头像块：有真实封面就显示，没有就用首字色块 */
@Component
export struct ArtistTile {
  private name: string = '';
  private diameter: number = 76;
  private onTap: (name: string) => void = () => {
  };
  private onLongPress: (name: string) => void = () => {
  };
  @State private cover: string = '';

  private fallbackColor(): string {
    const colors: string[] = ['#E0455E', '#2E7BE0', '#E08A2E', '#2EA98A', '#7B5BD6', '#C24E8F'];
    let hash: number = 0;
    for (let i = 0; i < this.name.length; i++) {
      hash = (hash * 31 + this.name.charCodeAt(i)) % 100000;
    }
    return colors[hash % colors.length];
  }

  build() {
    Column({ space: 7 }) {
      Stack() {
        if (this.cover.length > 0) {
          Image(this.cover)
            .width(this.diameter)
            .height(this.diameter)
            .borderRadius(this.diameter / 2)
            .objectFit(ImageFit.Cover)
        } else {
          Text(this.name.length > 0 ? this.name.charAt(0) : '?')
            .fontSize(this.diameter * 0.36)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
        }
      }
      .width(this.diameter)
      .height(this.diameter)
      .borderRadius(this.diameter / 2)
      .backgroundColor(this.cover.length > 0 ? '#00000000' : this.fallbackColor())
      .clip(true)

      Text(this.name)
        .fontSize(12)
        .fontColor(Palette.secondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width(this.diameter + 8)
        .textAlign(TextAlign.Center)
    }
    .onClick(() => {
      this.onTap(this.name);
    })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          this.onLongPress(this.name);
        })
    )
    .onAppear(() => {
      // 头像延迟加载：艺人页/搜索都能拿到，这里只在需要时补一张图
      ArtistCover.load(this.name).then((url: string) => {
        if (url.length > 0) {
          this.cover = url;
        }
      });
    })
  }
}

/** 艺人头像取图：复用网易云艺人搜索的第一个命中，命中后进程内缓存 */
export class ArtistCover {
  private static cache: Map<string, string> = new Map();

  static async load(name: string): Promise<string> {
    const cached: string | undefined = ArtistCover.cache.get(name);
    if (cached !== undefined) {
      return cached;
    }
    const cover: string = await ArtistCover.searchCover(name);
    ArtistCover.cache.set(name, cover);
    return cover;
  }

  private static async searchCover(name: string): Promise<string> {
    const url: string = `https://music.163.com/api/search/get?s=${encodeURIComponent(name)}&type=100&limit=1`;
    const text: string = await Http.getText(url);
    if (text.length === 0) {
      return '';
    }
    let root: Record<string, Object> | null = null;
    try {
      root = J.obj(JSON.parse(text) as Object);
    } catch (err) {
      return '';
    }
    if (root === null) {
      return '';
    }
    const result: Record<string, Object> | null = J.obj(root['result']);
    if (result === null) {
      return '';
    }
    const artists: Object[] = J.arr(result['artists']);
    if (artists.length === 0) {
      return '';
    }
    const first: Record<string, Object> | null = J.obj(artists[0]);
    if (first === null) {
      return '';
    }
    let pic: string = J.str(first['picUrl']);
    if (pic.length === 0) {
      pic = J.str(first['img1v1Url']);
    }
    if (pic.startsWith('http://')) {
      pic = 'https://' + pic.substring(7);
    }
    if (pic.length === 0) {
      return '';
    }
    return `${pic}?param=200y200`;
  }
}
