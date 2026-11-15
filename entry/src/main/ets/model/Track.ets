/** 一首歌的最小信息集合，字段和 iOS / 安卓版的 Track 对齐 */
export interface Track {
  id: string;
  title: string;
  artist: string;
  album: string;
  /** 秒；0 表示未知 */
  duration: number;
  artwork: string;
  /** 音源标识：目前只有 netease */
  source: string;
  /** 该音源内的 id，播放时用它取直链 */
  sourceId: string;
}

export class TrackFactory {
  static create(id: string, title: string, artist: string, album: string,
    duration: number, artwork: string, source: string, sourceId: string): Track {
    return {
      id: id,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      artwork: artwork,
      source: source,
      sourceId: sourceId
    };
  }

  static empty(): Track {
    return TrackFactory.create('', '', '', '', 0, '', '', '');
  }
}
