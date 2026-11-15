/**
 * JSON 安全读取工具。
 *
 * ArkTS 下 `JSON.parse` 返回的是 `Object`，直接 `as SomeInterface` 在严格模式下不保险，
 * 官方推荐按 `Record<string, Object>` 逐层取。这里把「取对象 / 取数组 / 取字符串 / 取数字」
 * 收成一组静态方法，调用处不必到处写 typeof 判断。
 */
export class J {
  static obj(value: Object | undefined): Record<string, Object> | null {
    if (value === undefined || value === null) {
      return null;
    }
    if (typeof value !== 'object') {
      return null;
    }
    return value as Record<string, Object>;
  }

  static arr(value: Object | undefined): Object[] {
    if (value === undefined || value === null) {
      return [];
    }
    if (Array.isArray(value)) {
      return value as Object[];
    }
    return [];
  }

  static str(value: Object | undefined): string {
    if (typeof value === 'string') {
      return value as string;
    }
    return '';
  }

  static num(value: Object | undefined): number {
    if (typeof value === 'number') {
      return value as number;
    }
    return 0;
  }
}
