# Melo 鸿蒙版（HarmonyOS / ArkTS）

Melo 的鸿蒙版本，用 ArkTS + ArkUI 重写，界面与 iOS / 安卓版保持同一套视觉。
目标设备：华为 Pura X（鸿蒙 7.0 / HarmonyOS 7.0.0 及以上）。

> 这是第一版（0.1.0），只做「能听歌」这条主线：
> 搜索 → 播放 → 收藏 / 最近播放 / 喜欢艺人 → 本地持久化。
> 多音源、登录、无损、歌曲宝人机验证等都还没接，见文末「后续计划」。

## 目录结构

```
melo-harmony/
├── AppScope/                     应用级配置（bundleName / 版本 / 图标）
├── build-profile.json5           构建配置：SDK 版本、产物
├── hvigorfile.ts                 构建脚本入口
├── hvigor/hvigor-config.json5    hvigor 版本（6.0.0 模型）
├── oh-package.json5
└── entry/                        主模块
    └── src/main/
        ├── module.json5          权限、Ability、页面入口
        ├── ets/
        │   ├── entryability/     UIAbility 入口
        │   ├── pages/Index.ets   四个 Tab + 迷你播放条 + 全屏播放页
        │   ├── views/            首页 / 搜索 / 资料库 / 设置 / 播放页 / 添加艺人
        │   ├── services/         Http、Netease、Store（本地库）、Player（AVPlayer）
        │   ├── model/Track.ets
        │   └── common/           配色、JSON 取值、艺人名规则
        └── resources/            字符串、颜色、图标、网络配置、页面表
```

## 关键实现

- **播放**：`@ohos.multimedia.media` 的 AVPlayer，播放网易云外链
  `https://music.163.com/song/media/outer/url?id=<id>.mp3`（匿名 128k）。
  状态写进 AppStorage（npTitle / playing / progress …），界面用 `@StorageLink` 自动刷新。
- **搜索**：`/api/search/get`，type=1 歌曲、type=100 艺人。
- **本地库**：`@ohos.data.preferences`，收藏歌曲 / 最近播放 / 喜欢艺人。
  首次启动种三首歌 + 四位喜欢艺人，首页不至于空白。
- **艺人名规则**：与 iOS / 安卓同一套（`common/ArtistName.ets`）——
  拆合唱、去首尾符号、挡派生账号（结尾是 电台 / 微博台 / 评书 …）、
  去标点后不足两字的截断残渣直接拒绝。

## 构建

### 前置

1. Node.js 18+（本机用 22）
2. HarmonyOS / OpenHarmony SDK（`DEVECO_SDK_HOME` 指向 SDK 根目录）
3. 项目根目录执行一次 `npm i`（hvigor 依赖已在 oh-package.json5 里声明）

### 命令行

```bash
# 生成 debug HAP（未签名）
node ./node_modules/@ohos/hvigor/bin/hvigor.js --mode module -p product=default assembleHap

# 产物
entry/build/default/outputs/default/entry-default-unsigned.hap
```

### 用 DevEco Studio（推荐，能直接装到手机）

1. DevEco Studio 打开本目录（`File → Open`）；
2. `File → Project Structure → Signing Configs` 勾选 **Automatically generate signature**，
   登录华为开发者账号 —— 这一步会用你的账号生成调试证书，并把证书绑定到设备；
3. 手机开启「开发者模式 + USB 调试」，连接后点 Run；
4. 也可以 `Build → Build Hap(s)`，产物在 `entry/build/default/outputs/default/`。

> **重要**：未签名的 HAP 无法安装到任何鸿蒙手机。签名证书必须绑定你自己的
> 华为开发者账号（调试证书还会绑定设备 UDID），这一步只能在你的机器上做，
> 我没法代签，也不会去碰你的账号。

## 已知限制（0.1.0）

- 只有网易云匿名链路：VIP / 无版权曲目会 404，播放器会提示「这首可能没版权或需要会员」。
- 没有后台播放 / 通知栏控制（需要 AVSession，下一版补）。
- 没有登录、没有 320k / 无损、没有多音源与歌曲宝验证。
- 艺人页只按人名搜歌，没有拉艺人全部专辑。

## 后续计划

1. AVSession + 后台播放、锁屏与通知栏控制；
2. 网易云登录（Cookie 存本机）→ 320k / 无损；
3. 多音源（酷狗 / 酷我 / 歌曲宝）与角标显示实际出声源；
4. 艺人页：按艺人 id 拉全量专辑与曲目。
