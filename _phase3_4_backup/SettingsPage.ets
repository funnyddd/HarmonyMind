import router from '@ohos.router';
import { ServiceFactory } from '../domain/factory/ServiceFactory';
import { AIProvider } from '../domain/service/AIService';
import promptAction from '@ohos.promptAction';

/**
 * SettingsPage — 设置页
 *
 * 管理:
 * - AI 提供者选择 (端侧/云端/自动)
 * - 云端 API Key 配置
 * - 深色模式
 * - 自动同步开关
 * - 默认分类
 * - 关于信息
 */
@Entry
@Component
struct SettingsPage {
  @State selectedAIProvider: string = 'auto';
  @State apiKey: string = '';
  @State isDarkMode: boolean = false;
  @State autoSync: boolean = true;
  @State defaultCategory: string = '其他';
  @State showApiKey: boolean = false;

  aboutToAppear(): void {
    this.loadSettings();
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
          // AI 设置
          this.SectionTitle('AI 设置')
          this.buildAISettings()

          // 同步设置
          this.SectionTitle('同步设置')
          this.buildSyncSettings()

          // 显示设置
          this.SectionTitle('显示设置')
          this.buildDisplaySettings()

          // 关于
          this.SectionTitle('关于')
          this.buildAbout()
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

      Text($r('app.string.settings'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ left: 4, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_secondary'))
      .textCase(TextCase.UpperCase)
      .margin({ top: 20, bottom: 8 })
  }

  @Builder
  buildAISettings() {
    Column() {
      // AI Provider 选择
      this.SettingRowWithPicker(
        'AI 引擎',
        this.selectedAIProvider === 'auto' ? '自动（端侧优先）' :
        this.selectedAIProvider === 'cloud' ? '云端 API' : '端侧推理',
        () => {
          // 切换 provider
          const options = ['auto', 'cloud', 'on_device'];
          const currentIndex = options.indexOf(this.selectedAIProvider);
          const nextIndex = (currentIndex + 1) % options.length;
          this.selectedAIProvider = options[nextIndex];
          this.applyAIProvider();
        }
      )

      // API Key
      if (this.selectedAIProvider !== 'on_device') {
        this.SettingRowWithInput(
          '云端 API Key',
          this.apiKey,
          (value: string) => {
            this.apiKey = value;
            this.applyApiKey();
          }
        )
      }
    }
  }

  @Builder
  buildSyncSettings() {
    Column() {
      // 自动同步
      this.SettingRowWithToggle(
        '自动同步',
        '跨设备实时同步笔记',
        this.autoSync,
        (value: boolean) => {
          this.autoSync = value;
          this.saveSettings();
        }
      )
    }
  }

  @Builder
  buildDisplaySettings() {
    Column() {
      // 深色模式
      this.SettingRowWithToggle(
        '深色模式',
        '使用深色界面主题',
        this.isDarkMode,
        (value: boolean) => {
          this.isDarkMode = value;
          this.saveSettings();
          promptAction.showToast({
            message: '深色模式将在重启后生效',
            duration: 2000
          });
        }
      )
    }
  }

  @Builder
  buildAbout() {
    Column() {
      Row() {
        Column() {
          Text('HarmonyMind')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))

          Text('版本 1.0.0')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 2 })
        }

        Blank()

        // App 图标占位
        Column()
          .width(48)
          .height(48)
          .borderRadius(12)
          .backgroundColor($r('app.color.primary'))
      }
      .width('100%')

      Divider()
        .margin({ top: 12, bottom: 12 })

      Text('鸿蒙分布式智能笔记应用')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')

      Text('展示: Stage 模型 · 分布式软总线 · 元服务 · AI 集成')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ top: 4 })
    }
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.card_background'))
    .width('100%')
  }

  // ========== 设置项构建器 ==========

  @Builder
  SettingRowWithPicker(label: string, value: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)

      Text(value)
        .fontSize(14)
        .fontColor($r('app.color.primary'))

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(14)
        .fontColor([$r('app.color.text_secondary')])
        .margin({ left: 4 })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 12 })
    .borderRadius(12)
    .backgroundColor($r('app.color.card_background'))
    .margin({ bottom: 8 })
    .onClick(onClick)
  }

  @Builder
  SettingRowWithInput(label: string, value: string, onChange: (value: string) => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)

      TextInput({ placeholder: '输入 API Key', text: $$this.apiKey })
        .fontSize(13)
        .width(160)
        .type(this.showApiKey ? InputType.Normal : InputType.Password)
        .backgroundColor($r('app.color.background'))
        .borderRadius(8)
        .padding({ left: 8, right: 8 })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 12 })
    .borderRadius(12)
    .backgroundColor($r('app.color.card_background'))
    .margin({ bottom: 8 })
  }

  @Builder
  SettingRowWithToggle(
    label: string,
    description: string,
    value: boolean,
    onChange: (value: boolean) => void
  ) {
    Row() {
      Column() {
        Text(label)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))

        Text(description)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 2 })
      }
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: $$this.autoSync })
        .onChange(onChange)
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 10, bottom: 10 })
    .borderRadius(12)
    .backgroundColor($r('app.color.card_background'))
    .margin({ bottom: 8 })
  }

  // ========== 设置持久化 ==========

  private applyAIProvider(): void {
    const factory = ServiceFactory.getInstance();
    const aiService = factory.getAIService();
    aiService.setProvider(this.selectedAIProvider as AIProvider);
    this.saveSettings();
  }

  private applyApiKey(): void {
    const factory = ServiceFactory.getInstance();
    const aiService = factory.getAIService();
    aiService.setCloudApiKey(this.apiKey);
    this.saveSettings();
  }

  private saveSettings(): void {
    // TODO: 使用 Preferences 持久化设置
  }

  private loadSettings(): void {
    // TODO: 从 Preferences 加载设置
  }
}
