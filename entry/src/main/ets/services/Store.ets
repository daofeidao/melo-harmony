import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { Track } from '../model/Track';
import { J } from '../common/Json';
import { ArtistName } from '../common/ArtistName';

/**
 * 本地资料库：收藏歌曲 / 最近播放 / 喜欢艺人，全部落在 preferences 里。
 *
 * 用「一次性读进内存 + 写时同步落盘」的方式：界面读的是同步 getter，
 * 不用为每个列表写一遍 async，改动后立刻持久化，冷启动再读回来。
 */
export class Store {
  private static pref: preferences.Preferences | null = null;
  private static favoritesCache: Track[] = [];
  private static recentCache: Track[] = [];
  private static likedCache: string[] = [];
  private static readyDone: boolean = false;
  private static initPromise: Promise<void> | null = null;

  private static readonly KEY_FAVORITES: string = 'favorites';
  private static readonly KEY_RECENT: string = 'recent';
  private static readonly KEY_LIKED: string = 'likedArtists';
  private static readonly RECENT_LIMIT: number = 40;

  /** 首次启动的种子：让首页不是一片空白 */
  private static readonly SEED_FAVORITES: Track[] = [
    {
      id: 'seed:tai-yang-zhi-zi', title: '太阳之子', artist: '周杰伦',
      album: '太阳之子', duration: 0, artwork: '', source: 'netease', sourceId: ''
    },
    {
      id: 'netease:189602', title: '青花', artist: '周传雄', album: '蓝色土耳其',
      duration: 298, artwork: '', source: 'netease', sourceId: '189602'
    },
    {
      id: 'netease:190072', title: '黄昏', artist: '周传雄', album: 'Transfer',
      duration: 344, artwork: '', source: 'netease', sourceId: '190072'
    }
  ];

  private static readonly SEED_ARTISTS: string[] = ['周杰伦', '周传雄', '林俊杰', '张学友'];

  static init(context: common.Context): Promise<void> {
    if (Store.initPromise === null) {
      Store.initPromise = Store.doInit(context);
    }
    return Store.initPromise;
  }

  private static async doInit(context: common.Context): Promise<void> {
    if (Store.readyDone) {
      return;
    }
    Store.pref = await preferences.getPreferences(context, 'melo_store');
    Store.favoritesCache = await Store.readTracks(Store.KEY_FAVORITES);
    Store.recentCache = await Store.readTracks(Store.KEY_RECENT);
    Store.likedCache = await Store.readArtists(Store.KEY_LIKED);

    const seeded: preferences.ValueType = await Store.pref.get('seeded', false);
    if (seeded !== true) {
      if (Store.favoritesCache.length === 0) {
        Store.favoritesCache = Store.SEED_FAVORITES.slice();
        await Store.persistTracks(Store.KEY_FAVORITES, Store.favoritesCache);
      }
      if (Store.likedCache.length === 0) {
        Store.likedCache = Store.SEED_ARTISTS.slice();
        await Store.persistArtists();
      }
      await Store.pref.put('seeded', true);
      await Store.pref.flush();
    }
    Store.readyDone = true;
  }

  static isReady(): boolean {
    return Store.readyDone;
  }

  // ---- 收藏歌曲 ----

  static favorites(): Track[] {
    return Store.favoritesCache;
  }

  static isFavorite(track: Track): boolean {
    for (const item of Store.favoritesCache) {
      if (item.id === track.id) {
        return true;
      }
    }
    return false;
  }

  static async toggleFavorite(track: Track): Promise<void> {
    const next: Track[] = [];
    let removed: boolean = false;
    for (const item of Store.favoritesCache) {
      if (item.id === track.id) {
        removed = true;
      } else {
        next.push(item);
      }
    }
    if (!removed) {
      next.unshift(track);
    }
    Store.favoritesCache = next;
    await Store.persistTracks(Store.KEY_FAVORITES, next);
  }

  // ---- 最近播放 ----

  static recent(): Track[] {
    return Store.recentCache;
  }

  static async addRecent(track: Track): Promise<void> {
    if (track.title.length === 0) {
      return;
    }
    const next: Track[] = [];
    for (const item of Store.recentCache) {
      if (item.id !== track.id) {
        next.push(item);
      }
    }
    next.unshift(track);
    Store.recentCache = next.slice(0, Store.RECENT_LIMIT);
    await Store.persistTracks(Store.KEY_RECENT, Store.recentCache);
  }

  static async clearRecent(): Promise<void> {
    Store.recentCache = [];
    await Store.persistTracks(Store.KEY_RECENT, Store.recentCache);
  }

  // ---- 喜欢艺人 ----

  static likedArtists(): string[] {
    return Store.likedCache;
  }

  static isLikedArtist(name: string): boolean {
    const key: string = ArtistName.key(ArtistName.primary(name));
    if (key.length === 0) {
      return false;
    }
    for (const item of Store.likedCache) {
      if (ArtistName.key(item) === key) {
        return true;
      }
    }
    return false;
  }

  static async addLikedArtist(name: string): Promise<boolean> {
    const clean: string = ArtistName.primary(name);
    if (!ArtistName.isPlausible(clean) || Store.isLikedArtist(clean)) {
      return false;
    }
    const next: string[] = [clean];
    for (const item of Store.likedCache) {
      next.push(item);
    }
    Store.likedCache = next;
    await Store.persistArtists();
    return true;
  }

  static async removeLikedArtist(name: string): Promise<void> {
    const key: string = ArtistName.key(ArtistName.primary(name));
    const next: string[] = [];
    for (const item of Store.likedCache) {
      if (ArtistName.key(item) !== key) {
        next.push(item);
      }
    }
    Store.likedCache = next;
    await Store.persistArtists();
  }

  static async clearAll(): Promise<void> {
    Store.favoritesCache = [];
    Store.recentCache = [];
    Store.likedCache = [];
    await Store.persistTracks(Store.KEY_FAVORITES, []);
    await Store.persistTracks(Store.KEY_RECENT, []);
    await Store.persistArtists();
  }

  // ---- 读写 ----

  private static async readTracks(key: string): Promise<Track[]> {
    const pref = Store.pref;
    if (pref === null) {
      return [];
    }
    const raw: preferences.ValueType = await pref.get(key, '');
    if (typeof raw !== 'string' || (raw as string).length === 0) {
      return [];
    }
    let parsed: Object | null = null;
    try {
      parsed = JSON.parse(raw as string) as Object;
    } catch (err) {
      return [];
    }
    const out: Track[] = [];
    for (const item of J.arr(parsed)) {
      const node: Record<string, Object> | null = J.obj(item);
      if (node === null) {
        continue;
      }
      out.push({
        id: J.str(node['id']),
        title: J.str(node['title']),
        artist: J.str(node['artist']),
        album: J.str(node['album']),
        duration: J.num(node['duration']),
        artwork: J.str(node['artwork']),
        source: J.str(node['source']),
        sourceId: J.str(node['sourceId'])
      });
    }
    return out;
  }

  private static async readArtists(key: string): Promise<string[]> {
    const pref = Store.pref;
    if (pref === null) {
      return [];
    }
    const raw: preferences.ValueType = await pref.get(key, '');
    if (typeof raw !== 'string' || (raw as string).length === 0) {
      return [];
    }
    let parsed: Object | null = null;
    try {
      parsed = JSON.parse(raw as string) as Object;
    } catch (err) {
      return [];
    }
    const out: string[] = [];
    const seen: string[] = [];
    for (const item of J.arr(parsed)) {
      if (typeof item !== 'string') {
        continue;
      }
      const clean: string = ArtistName.primary(item as string);
      if (!ArtistName.isPlausible(clean)) {
        continue;
      }
      const key2: string = ArtistName.key(clean);
      if (key2.length === 0 || seen.includes(key2)) {
        continue;
      }
      seen.push(key2);
      out.push(clean);
    }
    return out;
  }

  private static async persistTracks(key: string, list: Track[]): Promise<void> {
    const pref = Store.pref;
    if (pref === null) {
      return;
    }
    await pref.put(key, JSON.stringify(list));
    await pref.flush();
  }

  private static async persistArtists(): Promise<void> {
    const pref = Store.pref;
    if (pref === null) {
      return;
    }
    await pref.put(Store.KEY_LIKED, JSON.stringify(Store.likedCache));
    await pref.flush();
  }
}
