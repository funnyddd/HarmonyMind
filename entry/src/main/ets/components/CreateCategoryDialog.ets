import { CATEGORY_COLORS } from '../model/NoteCategory';

/**
 * CreateCategoryDialog — 新建分类弹窗
 * 输入分类名称 + 选择颜色
 */
@CustomDialog
export struct CreateCategoryDialog {
  controller: CustomDialogController;
  onConfirm?: (name: string, color: string) => void;

  @State name: string = '';
  @State selectedColor: string = '#4ECDC4';

  private colorKeys: string[] = Object.keys(CATEGORY_COLORS);
  private colorValues: string[] = Object.values<string>(CATEGORY_COLORS);

  build() {
    Column() {
      Text('新建分类')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 20, bottom: 16 })

      // 名称输入
      TextInput({ placeholder: '分类名称', text: $$this.name })
        .fontSize(15)
        .height(44)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .padding({ left: 12, right: 12 })
        .margin({ left: 16, right: 16, bottom: 4 })

      Divider()
        .margin({ top: 16, left: 16, right: 16 })

      // 颜色选择
      Text('选择颜色')
        .fontSize(13)
        .fontColor('#888888')
        .margin({ left: 16, top: 16, bottom: 10 })

      Grid() {
        ForEach(this.colorValues, (color: string, index: number) => {
          GridItem() {
            Stack() {
              Circle({ width: 36, height: 36 })
                .fill(color)

              if (this.selectedColor === color) {
                SymbolGlyph($r('sys.symbol.checkmark'))
                  .fontSize(16)
                  .fontColor([Color.White])
              }
            }
          }
          .onClick(() => {
            this.selectedColor = color;
          })
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(8)
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 4 })

      Divider()
        .margin({ top: 16, left: 16, right: 16 })

      // 按钮
      Row() {
        Button('取消')
          .fontSize(15)
          .fontColor('#333333')
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.controller.close();
          })

        Blank()
          .width(12)

        Button('确定')
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor(this.canConfirm() ? this.selectedColor : '#CCCCCC')
          .borderRadius(8)
          .layoutWeight(1)
          .height(44)
          .enabled(this.canConfirm())
          .onClick(() => {
            if (this.onConfirm && this.canConfirm()) {
              this.onConfirm(this.name.trim(), this.selectedColor);
            }
            this.controller.close();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 20 })
    }
    .width('100%')
    .borderRadius(16)
    .backgroundColor(Color.White)
  }

  private canConfirm(): boolean {
    return this.name.trim().length > 0;
  }
}
