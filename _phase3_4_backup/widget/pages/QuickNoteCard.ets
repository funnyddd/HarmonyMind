/**
 * QuickNoteCard — 桌面元服务卡片 UI
 *
 * 支持 2×2 和 2×4 两种尺寸的桌面卡片。
 * 显示最近笔记摘要及快捷操作入口。
 *
 * 卡片尺寸适配:
 * - 2×2: 仅显示最近笔记标题 + 新建按钮
 * - 2×4: 显示最近笔记完整预览 + 新建/录音两个按钮
 */
@Entry
@Component
struct QuickNoteCard {
  /**
   * 卡片数据 — 由 FormExtensionAbility 通过 formBindingData 注入
   */
  @LocalStorageProp('recentNoteTitle') recentNoteTitle: string = 'HarmonyMind';
  @LocalStorageProp('recentNotePreview') recentNotePreview: string = '点击快速记录笔记';
  @LocalStorageProp('noteCount') noteCount: number = 0;
  @LocalStorageProp('lastSyncTime') lastSyncTime: string = '—';

  /**
   * 卡片形态: 2×2 或 2×4
   * 由系统在运行时根据实际卡片尺寸传入
   */
  @LocalStorageProp('formDimension') formDimension: number = 2;

  build() {
    Stack() {
      // 渐变背景
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['#007DFF', 0.0],
            ['#5856D6', 1.0]
          ]
        })

      Column() {
        // 顶部栏
        Row() {
          Text('HarmonyMind')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .opacity(0.9)

          Blank()

          Text('共' + this.noteCount + '条')
            .fontSize(10)
            .fontColor('#FFFFFF')
            .opacity(0.6)
        }
        .width('100%')

        // 中间内容区
        Column() {
          Text(this.recentNoteTitle)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })

          // 2×4 卡片显示预览
          if (this.formDimension === 4) {
            Text(this.recentNotePreview)
              .fontSize(11)
              .fontColor('#FFFFFF')
              .opacity(0.7)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 4 })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Blank()

        // 底部操作区
        Row() {
          // 新建笔记
          Button() {
            Row() {
              SymbolGlyph($r('sys.symbol.plus'))
                .fontSize(12)
                .fontColor(['#FFFFFF'])

              Text('新建')
                .fontSize(11)
                .fontColor('#FFFFFF')
                .margin({ left: 2 })
            }
          }
          .type(ButtonType.Capsule)
          .backgroundColor('#FFFFFF20')
          .borderRadius(14)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .onClick(() => {
            postCardAction(this, {
              action: 'message',
              params: { message: 'newNote' }
            });
          })

          // 2×4 卡片增加录音按钮
          if (this.formDimension === 4) {
            Button() {
              Row() {
                SymbolGlyph($r('sys.symbol.mic'))
                  .fontSize(12)
                  .fontColor(['#FFFFFF'])

                Text('录音')
                  .fontSize(11)
                  .fontColor('#FFFFFF')
                  .margin({ left: 2 })
              }
            }
            .type(ButtonType.Capsule)
            .backgroundColor('#FFFFFF20')
            .borderRadius(14)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .margin({ left: 8 })
            .onClick(() => {
              postCardAction(this, {
                action: 'message',
                params: { message: 'voiceNote' }
              });
            })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height('100%')
      .padding(14)
    }
    .width('100%')
    .height('100%')
    .borderRadius(16)
  }
}
