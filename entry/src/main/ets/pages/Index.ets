import common from '@ohos.app.ability.common';
import { Store } from '../services/Store';
import { Player } from '../services/Player';
import { Track } from '../model/Track';
import { Palette } from '../common/Theme';
import { HomeTab } from '../views/HomeTab';
import { SearchTab } from '../views/SearchTab';
import { LibraryTab } from '../views/LibraryTab';
import { SettingsTab } from '../views/SettingsTab';
import { PlayerSheet } from '../views/PlayerSheet';
import { AddArtistSheet } from '../views/AddArtistSheet';

@Entry
@Component
struct Index {
  @State private tab: number = 0;
  @State private favorites: Track[] = [];
  @State private recent: Track[] = [];
  @State private liked: string[] = [];
  @State private showPlayer: boolean = false;
  @State private showAddArtist: boolean = false;
  @State private pendingArtist: string = '';

  @StorageLink('npTitle') private npTitle: string = '';
  @StorageLink('npArtist') private npArtist: string = '';
  @StorageLink('npArtwork') private npArtwork: string = '';
  @StorageLink('playing') private playing: boolean = false;
  @StorageLink('progress') private progress: number = 0;
  @StorageLink('duration') private duration: number = 0;
  @StorageLink('playerError') private playerError: string = '';

  aboutToAppear(): void {
    const context = getContext(this) as common.Context;
    Store.init(context).then(() => {
      this.refresh();
    }).catch(() => {
      this.refresh();
    });
  }

  private refresh(): void {
    this.favorites = Store.favorites().slice();
    this.recent = Store.recent().slice();
    this.liked = Store.likedArtists().slice();
  }

  private play(list: Track[], index: number): void {
    if (list.length === 0) {
      return;
    }
    const track: Track = list[index];
    Store.addRecent(track).then(() => {
      this.recent = Store.recent().slice();
    });
    Player.shared().playAt(list, index).then(() => {
      this.showPlayer = true;
    });
  }

  private toggleFavorite(track: Track): void {
    Store.toggleFavorite(track).then(() => {
      this.favorites = Store.favorites().slice();
    });
  }

  private removeArtist(name: string): void {
    Store.removeLikedArtist(name).then(() => {
      this.liked = Store.likedArtists().slice();
    });
  }

  private addArtist(name: string): boolean {
    if (Store.isLikedArtist(name)) {
      return false;
    }
    Store.addLikedArtist(name).then(() => {
      this.liked = Store.likedArtists().slice();
    });
    return true;
  }

  @Builder
  private TabItem(title: string, symbol: string, index: number) {
    Column({ space: 1 }) {
      Text(symbol)
        .fontSize(19)
        .fontColor(this.tab === index ? Palette.accent : Palette.secondary)
      Text(title)
        .fontSize(10)
        .fontColor(this.tab === index ? Palette.accent : Palette.secondary)
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Tabs({ barPosition: BarPosition.End, index: this.tab }) {
          TabContent() {
            HomeTab({
              favorites: this.favorites,
              recent: this.recent,
              liked: this.liked,
              onPlay: (list: Track[], index: number) => {
                this.play(list, index);
              },
              onToggleFavorite: (track: Track) => {
                this.toggleFavorite(track);
              },
              onOpenArtist: (name: string) => {
                this.pendingArtist = name;
                this.tab = 1;
              },
              onRemoveArtist: (name: string) => {
                this.removeArtist(name);
              },
              onRequestAddArtist: () => {
                this.showAddArtist = true;
              },
              onClearRecent: () => {
                Store.clearRecent().then(() => {
                  this.recent = Store.recent().slice();
                });
              }
            })
          }.tabBar(this.TabItem('现在就听', '♪', 0))

          TabContent() {
            SearchTab({
              liked: this.liked,
              pendingArtist: this.pendingArtist,
              onPlay: (list: Track[], index: number) => {
                this.play(list, index);
              },
              onToggleFavorite: (track: Track) => {
                this.toggleFavorite(track);
              },
              onAddLikedArtist: (name: string) => {
                this.addArtist(name);
              }
            })
          }.tabBar(this.TabItem('搜索', '⌕', 1))

          TabContent() {
            LibraryTab({
              favorites: this.favorites,
              recent: this.recent,
              onPlay: (list: Track[], index: number) => {
                this.play(list, index);
              },
              onToggleFavorite: (track: Track) => {
                this.toggleFavorite(track);
              }
            })
          }.tabBar(this.TabItem('资料库', '♫', 2))

          TabContent() {
            SettingsTab({
              onClearRecent: () => {
                Store.clearRecent().then(() => {
                  this.recent = Store.recent().slice();
                });
              },
              onClearAll: () => {
                Store.clearAll().then(() => {
                  this.refresh();
                });
              }
            })
          }.tabBar(this.TabItem('设置', '⚙', 3))
        }
        .barHeight(52)
        .barMode(BarMode.Fixed)
        .scrollable(false)
        .onChange((index: number) => {
          this.tab = index;
        })
        .layoutWeight(1)

        // 迷你播放条
        if (this.npTitle.length > 0) {
          Row({ space: 10 }) {
            if (this.npArtwork.length > 0) {
              Image(this.npArtwork)
                .width(38)
                .height(38)
                .borderRadius(6)
                .objectFit(ImageFit.Cover)
            } else {
              Stack() {
                Text('♪').fontSize(16).fontColor('#FFFFFF')
              }
              .width(38)
              .height(38)
              .borderRadius(6)
              .backgroundColor(Palette.accent)
            }

            Column({ space: 2 }) {
              Text(this.npTitle)
                .fontSize(14)
                .fontColor(Palette.label)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.npArtist)
                .fontSize(11)
                .fontColor(Palette.secondary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(this.playing ? '⏸' : '▶')
              .fontSize(22)
              .fontColor(Palette.label)
              .padding({ left: 8, right: 8 })
              .onClick(() => {
                Player.shared().toggle();
              })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(Palette.card)
          .onClick(() => {
            this.showPlayer = true;
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Palette.bg)

      // 全屏播放页
      if (this.showPlayer) {
        PlayerSheet({
          title: this.npTitle,
          artist: this.npArtist,
          artwork: this.npArtwork,
          playing: this.playing,
          progress: this.progress,
          duration: this.duration,
          errorText: this.playerError,
          onClose: () => {
            this.showPlayer = false;
          },
          onToggle: () => {
            Player.shared().toggle();
          },
          onNext: () => {
            Player.shared().next();
          },
          onPrev: () => {
            Player.shared().previous();
          },
          onSeek: (seconds: number) => {
            Player.shared().seek(seconds);
          }
        })
      }

      // 添加艺人
      if (this.showAddArtist) {
        Column() {
          Row().height('30%')
          AddArtistSheet({
            onClose: () => {
              this.showAddArtist = false;
            },
            onAdd: (name: string) => this.addArtist(name)
          })
          Row().layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20 })
        .backgroundColor('#99000000')
        .onClick(() => {
          this.showAddArtist = false;
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
