import { Track } from '../model/Track';
import { Palette, Sizes } from '../common/Theme';
import { EmptyHint, SectionTitle, TrackRow } from './Widgets';

/** 资料库：收藏歌曲 + 最近播放，纯本地 */
@Component
export struct LibraryTab {
  @Prop favorites: Track[] = [];
  @Prop recent: Track[] = [];
  onPlay: (list: Track[], index: number) => void = () => {
  };
  onToggleFavorite: (track: Track) => void = () => {
  };

  build() {
    Scroll() {
      Column() {
        SectionTitle({ title: '收藏歌曲' })
        if (this.favorites.length === 0) {
          EmptyHint({ text: '还没有收藏；在搜索结果里点心形即可收藏' })
        } else {
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

        SectionTitle({ title: '最近播放' })
        if (this.recent.length === 0) {
          EmptyHint({ text: '播放过的歌会出现在这里' })
        } else {
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
        Row().height(24)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor(Palette.bg)
  }
}
