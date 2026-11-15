import { Track } from '../model/Track';
import { Netease } from '../services/Netease';
import { Palette, Sizes } from '../common/Theme';
import { EmptyHint, TrackRow } from './Widgets';

/** 搜索：艺人 + 歌曲。艺人用胶囊，点一下转成「按人名找歌」 */
@Component
export struct SearchTab {
  @Prop liked: string[] = [];
  /** 首页点了艺人名 → 切到搜索页时自动查这个人的歌 */
  @Prop @Watch('handlePending') pendingArtist: string = '';
  onPlay: (list: Track[], index: number) => void = () => {
  };
  onToggleFavorite: (track: Track) => void = () => {
  };
  onAddLikedArtist: (name: string) => void = () => {
  };

  @State private keyword: string = '';
  @State private artists: string[] = [];
  @State private songs: Track[] = [];
  @State private loading: boolean = false;
  @State private message: string = '';
  @State private activeArtist: string = '';

  private handlePending(): void {
    if (this.pendingArtist.length === 0) {
      return;
    }
    this.keyword = this.pendingArtist;
    this.openArtist(this.pendingArtist);
  }

  private async runSearch(): Promise<void> {
    const word: string = this.keyword.trim();
    if (word.length === 0) {
      return;
    }
    this.loading = true;
    this.message = '';
    this.activeArtist = '';
    const artists: string[] = await Netease.searchArtists(word);
    const songs: Track[] = await Netease.searchSongs(word);
    this.artists = artists;
    this.songs = songs;
    this.loading = false;
    if (artists.length === 0 && songs.length === 0) {
      this.message = '没搜到内容：检查网络，或换个关键词';
    }
  }

  private async openArtist(name: string): Promise<void> {
    this.loading = true;
    this.message = '';
    this.activeArtist = name;
    const songs: Track[] = await Netease.songsOfArtist(name);
    this.songs = songs;
    this.artists = [];
    this.loading = false;
    if (songs.length === 0) {
      this.message = `「${name}」的歌暂时没取到`;
    }
  }

  private isLiked(name: string): boolean {
    return this.liked.includes(name);
  }

  build() {
    Column() {
      // 搜索框
      Row({ space: 10 }) {
        TextInput({ placeholder: '搜歌名、艺人', text: this.keyword })
          .layoutWeight(1)
          .height(38)
          .borderRadius(10)
          .backgroundColor(Palette.card)
          .onChange((value: string) => {
            this.keyword = value;
          })
          .onSubmit(() => {
            this.runSearch();
          })
        Button('搜索')
          .height(38)
          .fontSize(14)
          .backgroundColor(Palette.accent)
          .onClick(() => {
            this.runSearch();
          })
      }
      .width('100%')
      .padding({ left: Sizes.pagePadding, right: Sizes.pagePadding, top: 8, bottom: 8 })

      if (this.loading) {
        Row({ space: 8 }) {
          LoadingProgress().width(18).height(18).color(Palette.secondary)
          Text('搜索中…').fontSize(12).fontColor(Palette.secondary)
        }
        .padding({ left: Sizes.pagePadding, top: 6 })
      }

      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(12)
          .fontColor(Palette.danger)
          .padding({ left: Sizes.pagePadding, right: Sizes.pagePadding, top: 6 })
      }

      Scroll() {
        Column({ space: 6 }) {
          // 艺人
          if (this.artists.length > 0) {
            Text('艺人')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Palette.label)
              .width('100%')
              .padding({ left: Sizes.pagePadding, top: 10, bottom: 6 })

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.artists, (name: string) => {
                Text(this.isLiked(name) ? `${name} ♥` : name)
                  .fontSize(13)
                  .fontColor(this.isLiked(name) ? Palette.accent : Palette.label)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .margin({ right: 8, bottom: 8 })
                  .backgroundColor(Palette.card)
                  .borderRadius(14)
                  .onClick(() => {
                    this.openArtist(name);
                  })
                  .gesture(
                    LongPressGesture({ repeat: false })
                      .onAction(() => {
                        this.onAddLikedArtist(name);
                      })
                  )
              }, (name: string) => name)
            }
            .padding({ left: Sizes.pagePadding, right: Sizes.pagePadding })
          }

          // 歌曲
          if (this.activeArtist.length > 0) {
            Row() {
              Text(`「${this.activeArtist}」的歌`)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(Palette.label)
              Blank()
              Text('返回')
                .fontSize(13)
                .fontColor(Palette.accent)
                .onClick(() => {
                  this.activeArtist = '';
                  this.runSearch();
                })
            }
            .width('100%')
            .padding({ left: Sizes.pagePadding, right: Sizes.pagePadding, top: 8, bottom: 4 })
          } else if (this.songs.length > 0) {
            Text('歌曲')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Palette.label)
              .width('100%')
              .padding({ left: Sizes.pagePadding, top: 10, bottom: 4 })
          }

          if (this.songs.length === 0 && this.artists.length === 0 && !this.loading && this.message.length === 0) {
            EmptyHint({ text: '输入关键词开始搜索；长按艺人名可以加进喜欢艺人' })
          }

          ForEach(this.songs, (track: Track, index: number) => {
            TrackRow({
              track: track,
              index: index,
              favorite: false,
              onTap: (t: Track) => {
                this.onPlay(this.songs, index);
              },
              onToggleFavorite: (t: Track) => {
                this.onToggleFavorite(t);
              }
            })
          }, (track: Track) => track.id)

          Row().height(24)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}
