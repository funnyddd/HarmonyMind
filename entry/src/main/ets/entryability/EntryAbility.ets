import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import window from '@ohos.window';
import { DatabaseConfig } from '../data/datasource/DatabaseConfig';

export default class EntryAbility extends UIAbility {
  private dbReady: Promise<void> | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.dbReady = DatabaseConfig.initialize(this.context.getApplicationContext());
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    const doLoad = async () => {
      if (this.dbReady !== null) {
        await this.dbReady;
      }
      windowStage.loadContent('pages/NoteListPage', (err) => {
        if (err.code) {
          return;
        }
      });
    };
    doLoad();
  }

  onForeground(): void {}

  onBackground(): void {}

  onDestroy(): void {
    DatabaseConfig.close();
  }
}
