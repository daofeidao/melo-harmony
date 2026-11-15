import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';
import { Store } from '../services/Store';

export default class EntryAbility extends UIAbility {
  onCreate(): void {
    // 资料库越早读越好：首页第一帧就要有内容
    Store.init(this.context).then(() => {
    }).catch(() => {
    });
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Store.init(this.context).then(() => {
    }).catch(() => {
    });
    windowStage.loadContent('pages/Index', (err: BusinessError) => {
      if (err.code !== 0) {
        console.error(`加载首页失败: ${JSON.stringify(err)}`);
      }
    });
  }

  onWindowStageDestroy(): void {
  }

  onForeground(): void {
  }

  onBackground(): void {
  }
}
