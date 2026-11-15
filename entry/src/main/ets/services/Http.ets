import http from '@ohos.net.http';

const UA: string = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

/** 一层薄薄的 GET 封装：统一 UA / Referer、超时、连接释放 */
export class Http {
  static async getText(url: string): Promise<string> {
    const request = http.createHttp();
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'User-Agent': UA,
          'Referer': 'https://music.163.com/'
        },
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 20000,
        usingCache: false
      });
      if (typeof response.result === 'string') {
        return response.result as string;
      }
      return '';
    } catch (err) {
      return '';
    } finally {
      request.destroy();
    }
  }
}
