/**
 * 艺人名的准入与清洗，规则与 iOS / 安卓版一致：
 *   1. 去转义残留、去零宽字符、去首尾符号；
 *   2. 拆合唱（`孙楠&那英` → 孙楠 / 那英）；
 *   3. 挡掉派生账号（结尾是 电台 / 微博台 / 评书 …）与截断残渣（去标点后不足两字）。
 *
 * 鸿蒙版只做本地规则这一层；联网白名单校验（网易云艺人库）放在调用处按需做，
 * 首页这种「本地已有数据」的场景不需要每次都发请求。
 */
export class ArtistName {
  private static readonly ZERO_WIDTH: string[] = ['\u200B', '\u200C', '\u200D', '\uFEFF', '\u00AD'];

  private static readonly EDGE_JUNK: string = '"\'“”‘’《》-—–－_·・.．…,，、;；:：|｜/／+*#~ 　';

  private static readonly BLOCKED: string[] = [
    '原唱', '翻唱', '翻自', '原曲', 'cover', 'remix', '伴奏', '纯音乐', 'inst',
    'karaoke', 'ktv', 'dj', 'live', '现场', '演唱会', '串烧', '合唱版', '对唱版',
    '铃声', '片段', '试听', '钢琴版', '吉他版', '小提琴版', '古筝版', '女声版',
    '男声版', '抖音', '快手', '车载', '慢摇', '的士高', 'disco', '网络歌手',
    '群星', '华语群星', 'various', 'unknown', '未知艺人', '佚名', 'bgm',
    '八音盒', '合集', '歌单', '无损', 'flac', '320k', '128k', '高清',
    '完整版', '重制', '重置', '改编', 'remake', 'piano', 'ver.', 'version',
    '混音', '纯享', '纯人声', 'acoustic', 'instrumental'
  ];

  /** 只在结尾命中才算，否则会误杀「电台司令」这类合法名字 */
  private static readonly DERIVED_SUFFIX: string[] = [
    '电台', '广播', '频道', '音乐台', '微博', '微博台', '贴吧', '粉丝团',
    '后援会', '歌迷会', '工作室', '官方', '专辑', '评书', '相声', '播客',
    '有声书', '听书', '朗读', '解说'
  ];

  private static readonly SEPARATORS: string[] = ['&', '＆', '、', ',', '，', ';', '；', '/', '／', '|', '｜'];

  static sanitize(raw: string): string {
    let text: string = raw;
    for (const junk of ArtistName.ZERO_WIDTH) {
      text = text.replaceAll(junk, '');
    }
    text = text.replaceAll('\u00A0', ' ');
    text = text.trim();
    text = text.replaceAll('\\', '');
    // 首尾符号抹掉：`孙-` → `孙`，`周杰伦·` → `周杰伦`
    let start: number = 0;
    let end: number = text.length;
    while (start < end && ArtistName.EDGE_JUNK.includes(text.charAt(start))) {
      start++;
    }
    while (end > start && ArtistName.EDGE_JUNK.includes(text.charAt(end - 1))) {
      end--;
    }
    return text.substring(start, end);
  }

  /** 拆合唱，返回主艺人列表 */
  static split(raw: string): string[] {
    let text: string = ArtistName.sanitize(raw);
    for (const token of [' feat. ', ' feat ', ' ft. ', ' ft ', ' vs. ', ' vs ']) {
      text = text.split(token).join(' & ');
    }
    const parts: string[] = [];
    let current: string = '';
    for (let i = 0; i < text.length; i++) {
      const ch: string = text.charAt(i);
      if (ArtistName.SEPARATORS.includes(ch)) {
        parts.push(current);
        current = '';
      } else {
        current += ch;
      }
    }
    parts.push(current);
    const out: string[] = [];
    for (const part of parts) {
      const clean: string = ArtistName.sanitize(part);
      if (clean.length > 0) {
        out.push(clean);
      }
    }
    return out;
  }

  static primary(raw: string): string {
    const list: string[] = ArtistName.split(raw);
    if (list.length > 0) {
      return list[0];
    }
    return ArtistName.sanitize(raw);
  }

  /** 归一化 key：小写 + 去标点，用来判断「是不是同一个人」 */
  static key(raw: string): string {
    const base: string = ArtistName.sanitize(raw).toLowerCase();
    let out: string = '';
    for (let i = 0; i < base.length; i++) {
      const ch: string = base.charAt(i);
      if (' ·・.．,，、-_()（）[]【】'.includes(ch)) {
        continue;
      }
      out += ch;
    }
    return out;
  }

  static isPlausible(raw: string): boolean {
    const clean: string = ArtistName.sanitize(raw);
    if (clean.length < 2 || clean.length > 24) {
      return false;
    }
    if (ArtistName.key(clean).length < 2) {
      return false;
    }
    const lower: string = clean.toLowerCase();
    for (const word of ArtistName.BLOCKED) {
      if (lower.includes(word)) {
        return false;
      }
    }
    for (const suffix of ArtistName.DERIVED_SUFFIX) {
      if (lower.endsWith(suffix)) {
        return false;
      }
    }
    return true;
  }
}
