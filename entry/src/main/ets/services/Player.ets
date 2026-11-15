import media from '@ohos.multimedia.media';
import { BusinessError } from '@ohos.base';
import { Track } from '../model/Track';
import { Netease } from './Netease';

/**
 * 播放引擎（AVPlayer）。
 *
 * 界面不持有 AVPlayer，只读 AppStorage 里的几个字段：
 * npTitle / npArtist / npArtwork / playing / progress / duration / playerError，
 * 播放器状态一变就写进去，UI 用 @StorageLink 自动刷新 —— 省掉一层回调。
 */
export class Player {
  private static instance: Player | null = null;

  private avPlayer: media.AVPlayer | null = null;
  private queue: Track[] = [];
  private index: number = -1;

  static shared(): Player {
    if (Player.instance === null) {
      Player.instance = new Player();
    }
    return Player.instance;
  }

  current(): Track | null {
    if (this.index >= 0 && this.index < this.queue.length) {
      return this.queue[this.index];
    }
    return null;
  }

  queueSize(): number {
    return this.queue.length;
  }

  private async ensurePlayer(): Promise<media.AVPlayer> {
    if (this.avPlayer !== null) {
      return this.avPlayer;
    }
    const p: media.AVPlayer = await media.createAVPlayer();
    p.on('stateChange', (state: string) => {
      this.handleState(state, p);
    });
    p.on('timeUpdate', (time: number) => {
      AppStorage.setOrCreate<number>('progress', Math.floor(time / 1000));
    });
    p.on('durationUpdate', (duration: number) => {
      AppStorage.setOrCreate<number>('duration', Math.floor(duration / 1000));
    });
    p.on('error', (err: BusinessError) => {
      AppStorage.setOrCreate<boolean>('playing', false);
      AppStorage.setOrCreate<string>('playerError', `播放失败（${err.code}）：这首可能没版权或需要会员，换一首试试`);
    });
    this.avPlayer = p;
    return p;
  }

  private handleState(state: string, p: media.AVPlayer): void {
    if (state === 'initialized') {
      p.prepare().catch((err: BusinessError) => {
        AppStorage.setOrCreate<string>('playerError', `加载失败：${err.message}`);
      });
    } else if (state === 'prepared') {
      AppStorage.setOrCreate<number>('duration', Math.floor(p.duration / 1000));
      p.play().catch((err: BusinessError) => {
        AppStorage.setOrCreate<string>('playerError', `播放失败：${err.message}`);
      });
    } else if (state === 'playing') {
      AppStorage.setOrCreate<boolean>('playing', true);
    } else if (state === 'paused') {
      AppStorage.setOrCreate<boolean>('playing', false);
    } else if (state === 'completed') {
      AppStorage.setOrCreate<boolean>('playing', false);
      this.next();
    }
  }

  /** 播放队列里的第 index 首 */
  async playAt(list: Track[], index: number): Promise<void> {
    if (list.length === 0) {
      return;
    }
    if (index < 0 || index >= list.length) {
      index = 0;
    }
    this.queue = list.slice();
    this.index = index;
    const track: Track = this.queue[index];

    AppStorage.setOrCreate<string>('npTitle', track.title);
    AppStorage.setOrCreate<string>('npArtist', track.artist);
    AppStorage.setOrCreate<string>('npArtwork', track.artwork);
    AppStorage.setOrCreate<string>('npId', track.id);
    AppStorage.setOrCreate<number>('progress', 0);
    AppStorage.setOrCreate<number>('duration', track.duration);
    AppStorage.setOrCreate<boolean>('playing', true);
    AppStorage.setOrCreate<string>('playerError', '');

    const p: media.AVPlayer = await this.ensurePlayer();
    const url: string = Netease.playUrl(track.sourceId);
    try {
      if (p.state !== 'idle') {
        await p.reset();
      }
      p.url = url;
    } catch (err) {
      const e = err as BusinessError;
      AppStorage.setOrCreate<boolean>('playing', false);
      AppStorage.setOrCreate<string>('playerError', `无法播放：${e.message}`);
    }
  }

  async toggle(): Promise<void> {
    const p = this.avPlayer;
    if (p === null) {
      return;
    }
    try {
      if (p.state === 'playing') {
        await p.pause();
      } else if (p.state === 'prepared' || p.state === 'paused' || p.state === 'completed') {
        await p.play();
      }
    } catch (err) {
      // 状态切换失败不致命，忽略即可
    }
  }

  async seek(seconds: number): Promise<void> {
    const p = this.avPlayer;
    if (p === null) {
      return;
    }
    try {
      await p.seek(Math.floor(seconds * 1000), media.SeekMode.SEEK_PREV_SYNC);
    } catch (err) {
      // 拖动过程中失败很常见，忽略
    }
  }

  async next(): Promise<void> {
    if (this.queue.length === 0) {
      return;
    }
    const nextIndex: number = (this.index + 1) % this.queue.length;
    await this.playAt(this.queue, nextIndex);
  }

  async previous(): Promise<void> {
    if (this.queue.length === 0) {
      return;
    }
    const prevIndex: number = (this.index - 1 + this.queue.length) % this.queue.length;
    await this.playAt(this.queue, prevIndex);
  }
}
