import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import window from '@ohos.window';
import { DatabaseConfig } from '../data/datasource/DatabaseConfig';
import relationalStore from '@ohos.data.relationalStore';
import { NoteCategory, CATEGORY_COLORS, CATEGORY_ICONS } from '../model/NoteCategory';
import { AI_DEFAULT_CATEGORIES } from '../common/Constants';

export default class EntryAbility extends UIAbility {
  private dbReady: Promise<void> | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.dbReady = DatabaseConfig.initialize(this.context.getApplicationContext())
      .then(() => this.seedDefaultCategories());
  }

  /**
   * 首次启动时写入预设分类
   */
  private async seedDefaultCategories(): Promise<void> {
    try {
      const store = DatabaseConfig.getStore();
      if (!store) return;

      const predicates = new relationalStore.RdbPredicates('categories');
      const rs = await store.query(predicates);
      // 如果分类表为空，写入预设分类
      if (rs.rowCount === 0) {
        rs.close();
        const categories: NoteCategory[] = [];
        for (let i = 0; i < AI_DEFAULT_CATEGORIES.length; i++) {
          const name = AI_DEFAULT_CATEGORIES[i];
          const cat = new NoteCategory(
            name,
            '',  // id 自动生成
            CATEGORY_COLORS[name] || '#8E8E93',
            CATEGORY_ICONS[name] || 'file',
            i
          );
          categories.push(cat);
        }
        for (let i = 0; i < categories.length; i++) {
          const c = categories[i];
          const bucket: relationalStore.ValuesBucket = {
            'id': c.id,
            'name': c.name,
            'color': c.color,
            'icon_name': c.iconName,
            'created_at': c.createdAt,
            'sort_order': c.order
          };
          await store.insert('categories', bucket);
        }
      } else {
        rs.close();
      }
    } catch (e) {
      // 静默处理，不影响正常启动
    }
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
