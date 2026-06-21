import { NoteCategory } from '../model/NoteCategory';

/**
 * SelectCategoryDialog — 选择分类弹窗
 */
@CustomDialog
export struct SelectCategoryDialog {
  controller: CustomDialogController;
  categories: NoteCategory[] = [];
  currentName: string = '';
  onSelect?: (name: string) => void;

  build() {
    Column() {
      Text('选择分类')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 12 })

      List() {
        ForEach(this.categories, (cat: NoteCategory) => {
          ListItem() {
            Row() {
              Circle({ width: 10, height: 10 })
                .fill(cat.color)
                .margin({ right: 10 })

              Text(cat.name)
                .fontSize(15)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)

              if (cat.name === this.currentName) {
                SymbolGlyph($r('sys.symbol.checkmark'))
                  .fontSize(16)
                  .fontColor([$r('app.color.primary')])
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 14, bottom: 14 })
          }
          .onClick(() => {
            this.onSelect?.(cat.name);
            this.controller.close();
          })
        }, (cat: NoteCategory) => cat.id)
      }
      .width('100%')
      .height(320)

      Button('取消')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor($r('app.color.background'))
        .borderRadius(8)
        .width('60%')
        .height(40)
        .margin({ top: 8, bottom: 16 })
        .onClick(() => { this.controller.close(); })
    }
    .width('100%')
    .borderRadius(16)
    .backgroundColor(Color.White)
  }
}
