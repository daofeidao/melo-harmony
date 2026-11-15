import { Http } from './Http';
import { J } from '../common/Json';
import { ArtistName } from '../common/ArtistName';
import { Track } from '../model/Track';

/**
 * 网易云音乐（匿名）：
 * - 搜索走 `/api/search/get`，type=1 歌曲 / type=100 艺人；
 * - 播放走外链 `/song/media/outer/url?id=xxx.mp3`，匿名下非 VIP 曲目返回 302 到 128k mp3，
 *   VIP / 无版权会跳到 404，播放器会收到 error，由界面提示换歌。
 *
 * 这里不做签名、不带 Cookie —— 鸿蒙版第一版先用最稳的一条链路，
 * 要 320k / 无损需要登录态，后续版本再补。
 */
export class Netease {
  private static readonly BASE: string = 'https://music.163.com';

  static playUrl(sourceId: string): string {
    return `${Netease.BASE}/song/media/outer/url?id=${sourceId}.mp3`;
  }

  static async searchSongs(keyword: string): Promise<Track[]> {
    const url: string = `${Netease.BASE}/api/search/get?s=${encodeURIComponent(keyword)}&type=1&limit=30`;
    const text: string = await Http.getText(url);
    if (text.length === 0) {
      return [];
    }
    let root: Record<string, Object> | null = null;
    try {
      root = J.obj(JSON.parse(text) as Object);
    } catch (err) {
      return [];
    }
    if (root === null) {
      return [];
    }
    const result: Record<string, Object> | null = J.obj(root['result']);
    if (result === null) {
      return [];
    }
    const songs: Object[] = J.arr(result['songs']);
    const out: Track[] = [];
    for (const raw of songs) {
      const node: Record<string, Object> | null = J.obj(raw);
      if (node === null) {
        continue;
      }
      const id: number = J.num(node['id']);
      if (id <= 0) {
        continue;
      }
      const title: string = J.str(node['name']);
      const artist: string = Netease.joinArtists(J.arr(node['artists']));
      const albumNode: Record<string, Object> | null = J.obj(node['album']);
      let album: string = '';
      let artwork: string = '';
      if (albumNode !== null) {
        album = J.str(albumNode['name']);
        artwork = Netease.cover(J.str(albumNode['picUrl']));
      }
      const duration: number = Math.floor(J.num(node['duration']) / 1000);
      out.push({
        id: `netease:${id}`,
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        artwork: artwork,
        source: 'netease',
        sourceId: `${id}`
      });
    }
    return out;
  }

  /** 艺人名搜索：只取名字，够首页「添加喜欢艺人」和点艺人名用了 */
  static async searchArtists(keyword: string): Promise<string[]> {
    const url: string = `${Netease.BASE}/api/search/get?s=${encodeURIComponent(keyword)}&type=100&limit=20`;
    const text: string = await Http.getText(url);
    if (text.length === 0) {
      return [];
    }
    let root: Record<string, Object> | null = null;
    try {
      root = J.obj(JSON.parse(text) as Object);
    } catch (err) {
      return [];
    }
    if (root === null) {
      return [];
    }
    const result: Record<string, Object> | null = J.obj(root['result']);
    if (result === null) {
      return [];
    }
    const out: string[] = [];
    const seen: string[] = [];
    for (const raw of J.arr(result['artists'])) {
      const node: Record<string, Object> | null = J.obj(raw);
      if (node === null) {
        continue;
      }
      const name: string = ArtistName.sanitize(J.str(node['name']));
      if (!ArtistName.isPlausible(name)) {
        continue;
      }
      const key: string = ArtistName.key(name);
      if (key.length === 0 || seen.includes(key)) {
        continue;
      }
      seen.push(key);
      out.push(name);
    }
    return out;
  }

  /**
   * 按艺人名找歌：搜索结果里筛掉明显不是本人的条目。
   * 不用艺人 id 拉全量专辑 —— 第一版保持接口简单，后续再接 artist/songs。
   */
  static async songsOfArtist(name: string): Promise<Track[]> {
    const list: Track[] = await Netease.searchSongs(name);
    const target: string = ArtistName.key(name);
    const out: Track[] = [];
    for (const track of list) {
      const key: string = ArtistName.key(ArtistName.primary(track.artist));
      if (key === target) {
        out.push(track);
      }
    }
    if (out.length === 0) {
      return list;
    }
    return out;
  }

  private static joinArtists(artists: Object[]): string {
    const names: string[] = [];
    for (const raw of artists) {
      const node: Record<string, Object> | null = J.obj(raw);
      if (node === null) {
        continue;
      }
      const name: string = ArtistName.sanitize(J.str(node['name']));
      if (name.length > 0) {
        names.push(name);
      }
    }
    return names.join(' / ');
  }

  private static cover(url: string): string {
    if (url.length === 0) {
      return '';
    }
    let out: string = url;
    if (out.startsWith('http://')) {
      out = 'https://' + out.substring(7);
    }
    return `${out}?param=200y200`;
  }
}
