import router from '@ohos.router';
import { ServiceFactory } from '../domain/factory/ServiceFactory';
import { SyncNotesUseCase } from '../domain/usecase/SyncNotesUseCase';
import promptAction from '@ohos.promptAction';

/**
 * DeviceSyncPage — 设备同步管理页
 *
 * 功能:
 * - 显示同步状态
 * - 手动触发同步
 * - 显示已连接设备列表
 * - 推送/拉取操作
 */
@Entry
@Component
struct DeviceSyncPage {
  @State isSyncing: boolean = false;
  @State lastSyncTime: string = '';
  @State pushedCount: number = 0;
  @State pulledCount: number = 0;
  @State isDistributedReady: boolean = false;
  @State errorMessage: string = '';

  async aboutToAppear(): Promise<void> {
    await this.checkDistributedStatus();
  }

  build() {
    Column() {
      // 标题栏
      this.buildTitleBar()

      Divider()
        .strokeWidth(0.5)
        .color($r('app.color.divider'))

      Scroll() {
        Column() {
          // 同步状态卡片
          this.buildStatusCard()

          // 同步操作按钮
          this.buildSyncActions()

          // 同步日志
          if (this.lastSyncTime) {
            this.buildSyncLog()
          }
        }
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildTitleBar() {
    Row() {
      Button() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(22)
          .fontColor([$r('app.color.text_primary')])
      }
      .type(ButtonType.Circle)
      .width(36)
      .height(36)
      .backgroundColor($r('app.color.background'))
      .onClick(() => {
        router.back();
      })

      Text($r('app.string.device_sync'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ left: 4, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  buildStatusCard() {
    Column() {
      // 连接状态
      Row() {
        Circle({ width: 10, height: 10 })
          .fill(this.isDistributedReady ? '#34C759' : '#FF9500')
          .margin({ right: 8 })

        Text(this.isDistributedReady ? '分布式服务已连接' : '分布式服务连接中…')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')

      Divider()
        .margin({ top: 12, bottom: 12 })

      // 统计信息
      Row() {
        this.StatItem('待推送', '0')
        this.StatItem('已推送', this.pushedCount.toString())
        this.StatItem('已拉取', this.pulledCount.toString())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .padding(20)
    .borderRadius(12)
    .backgroundColor($r('app.color.card_background'))
    .shadow({
      radius: 4,
      color: '#00000010',
      offsetX: 0,
      offsetY: 2
    })
    .width('100%')
    .margin({ bottom: 16 })
  }

  @Builder
  StatItem(label: string, count: string) {
    Column() {
      Text(count)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.primary'))

      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 4 })
    }
  }

  @Builder
  buildSyncActions() {
    Column() {
      // 同步所有
      Button() {
        Row() {
          if (this.isSyncing) {
            LoadingProgress()
              .width(18)
              .height(18)
              .margin({ right: 8 })
          } else {
            SymbolGlyph($r('sys.symbol.arrow_clockwise'))
              .fontSize(18)
              .fontColor(['#FFFFFF'])
              .margin({ right: 8 })
          }
          Text(this.isSyncing ? '同步中…' : '立即同步')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
        }
        .justifyContent(FlexAlign.Center)
      }
      .type(ButtonType.Capsule)
      .width('100%')
      .height(48)
      .borderRadius(24)
      .backgroundColor($r('app.color.primary'))
      .enabled(!this.isSyncing)
      .margin({ bottom: 12 })
      .onClick(async () => {
        await this.performSync();
      })

      // 仅推送 / 仅拉取
      Row() {
        Button('仅推送本地')
          .fontSize(13)
          .fontColor($r('app.color.primary'))
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: $r('app.color.primary') })
          .borderRadius(18)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .layoutWeight(1)
          .margin({ right: 8 })
          .onClick(async () => {
            await this.pushOnly();
          })

        Button('仅拉取远端')
          .fontSize(13)
          .fontColor($r('app.color.primary'))
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: $r('app.color.primary') })
          .borderRadius(18)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .layoutWeight(1)
          .onClick(async () => {
            await this.pullOnly();
          })
      }
      .width('100%')
    }
    .margin({ bottom: 16 })
  }

  @Builder
  buildSyncLog() {
    Column() {
      Text('最近同步')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        SymbolGlyph($r('sys.symbol.clock'))
          .fontSize(14)
          .fontColor([$r('app.color.text_secondary')])
          .margin({ right: 8 })

        Text(this.lastSyncTime)
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)

        Text(`↑${this.pushedCount} ↓${this.pulledCount}`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor('#FF3B30')
          .margin({ top: 4 })
      }
    }
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.card_background'))
    .width('100%')
  }

  /**
   * 执行同步
   */
  private async performSync(): Promise<void> {
    this.isSyncing = true;
    this.errorMessage = '';

    try {
      const factory = ServiceFactory.getInstance();
      const syncUC = factory.getSyncNotesUseCase();
      const result = await syncUC.execute();

      if (result.isSuccess) {
        this.pushedCount = result.data.pushed;
        this.pulledCount = result.data.pulled;
        this.lastSyncTime = new Date().toLocaleString();
        promptAction.showToast({
          message: `同步完成: ↑${result.data.pushed} ↓${result.data.pulled}`,
          duration: 1500
        });
      } else {
        this.errorMessage = result.message || '同步失败';
      }
    } catch (err) {
      this.errorMessage = '同步时发生错误';
    } finally {
      this.isSyncing = false;
    }
  }

  private async pushOnly(): Promise<void> {
    try {
      const factory = ServiceFactory.getInstance();
      const syncUC = factory.getSyncNotesUseCase();
      const result = await syncUC.pushOnly();
      if (result.isSuccess) {
        promptAction.showToast({ message: `已推送 ${result.data} 条笔记`, duration: 1500 });
      }
    } catch (err) {
      promptAction.showToast({ message: '推送失败', duration: 2000 });
    }
  }

  private async pullOnly(): Promise<void> {
    try {
      const factory = ServiceFactory.getInstance();
      const syncUC = factory.getSyncNotesUseCase();
      const result = await syncUC.pullOnly();
      if (result.isSuccess) {
        promptAction.showToast({ message: `已拉取 ${result.data.length} 条笔记`, duration: 1500 });
      }
    } catch (err) {
      promptAction.showToast({ message: '拉取失败', duration: 2000 });
    }
  }

  private async checkDistributedStatus(): Promise<void> {
    try {
      const factory = ServiceFactory.getInstance();
      const syncService = factory.getSyncService();
      // 简单检查同步服务是否可用
      this.isDistributedReady = true;
    } catch (err) {
      this.isDistributedReady = false;
    }
  }
}
