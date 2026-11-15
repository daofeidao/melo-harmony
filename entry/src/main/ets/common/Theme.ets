/**
 * 统一的配色，对着 iOS 版 Theme 走：同一套视觉语言，换平台不至于看着像两个 App。
 */
export class Palette {
  static readonly bg: string = '#F2F2F7';
  static readonly card: string = '#FFFFFF';
  static readonly accent: string = '#FA2E4A';
  static readonly label: string = '#000000';
  static readonly secondary: string = '#8A8A8E';
  static readonly tertiary: string = '#B8B8BE';
  static readonly separator: string = '#E5E5EA';
  static readonly danger: string = '#E0455E';
}

export class Sizes {
  static readonly pagePadding: number = 16;
  static readonly rowHeight: number = 64;
  static readonly artwork: number = 48;
  static readonly radius: number = 10;
}
