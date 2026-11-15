import { Track } from '../model/Track';
import { Palette, Sizes } from '../common/Theme';
import { SectionTitle, EmptyHint, TrackRow, ArtistTile } from './Widgets';

/** 现在就听：喜欢艺人 / 最近播放 / 收藏歌曲，全部来自本地资料库，冷启动就有内容 */
@Component
export struct HomeTab {
  @Prop favorites: Track[] = [];
  @Prop recent: Track[] = [];
  @Prop liked: string[] = [];
  onPlay: (list: Track[], index: number) => void = () => {
  };
  onToggleFavorite: (track: Track) => void = () => {
  };
  onOpenArtist: (name: string) => void = () => {
  };
  onRemoveArtist: (name: string) => void = () => {
  };
  onRequestAddArtist: () => void = () => {
  };
  onClearRecent: () => void = () => {
  };

  build() {
    Scroll() {
      Column({ space: 4 }) {
        // ---- 喜欢艺人 ----
        Row() {
          Text('喜欢艺人')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Palette.label)
          Blank()
          Text('＋')
            .fontSize(22)
            .fontColor(Palette.accent)
            .padding({ left: 12, right: Sizes.pagePadding })
            .onClick(() => {
              this.onRequestAddArtist();
            })
        }
        .width('100%')
        .padding({ left: Sizes.pagePadding, top: 16, bottom: 8 })

        if (this.liked.length === 0) {
          EmptyHint({ text: '点右上角 ＋ 添加喜欢的艺人' })
        }

        Scroll() {
          Row({ space: 14 }) {
            ForEach(this.liked, (name: string) => {
              ArtistTile({
                name: name,
                diameter: 76,
                onTap: (n: string) => {
                  this.onOpenArtist(n);
                },
                onLongPress: (n: string) => {
                  this.onRemoveArtist(n);
                }
              })
            }, (name: string) => name)
          }
          .padding({ left: Sizes.pagePadding, right: Sizes.pagePadding })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')

        // ---- 最近播放 ----
        Row() {
          Text('最近播放')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Palette.label)
          Blank()
          if (this.recent.length > 0) {
            Text('清空')
              .fontSize(13)
              .fontColor(Palette.danger)
              .padding({ right: Sizes.pagePadding })
              .onClick(() => {
                this.onClearRecent();
              })
          }
        }
        .width('100%')
        .padding({ left: Sizes.pagePadding, top: 18, bottom: 8 })

        if (this.recent.length === 0) {
          EmptyHint({ text: '播放过的歌会出现在这里' })
        } else {
          Column() {
            ForEach(this.recent, (track: Track, index: number) => {
              TrackRow({
                track: track,
                index: index,
                favorite: false,
                onTap: (t: Track) => {
                  this.onPlay(this.recent, index);
                },
                onToggleFavorite: (t: Track) => {
                  this.onToggleFavorite(t);
                }
              })
            }, (track: Track) => track.id)
          }
        }

        // ---- 收藏歌曲 ----
        SectionTitle({ title: '我的收藏' })
        if (this.favorites.length === 0) {
          EmptyHint({ text: '点歌曲右侧的心形，收藏会出现在这里' })
        } else {
          Column() {
            ForEach(this.favorites, (track: Track, index: number) => {
              TrackRow({
                track: track,
                index: index,
                favorite: true,
                onTap: (t: Track) => {
                  this.onPlay(this.favorites, index);
                },
                onToggleFavorite: (t: Track) => {
                  this.onToggleFavorite(t);
                }
              })
            }, (track: Track) => track.id)
          }
        }

      }
      .width('100%')
      .padding({ bottom: 28 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
  }
}
