import { Note } from '../model/Note';
import { NoteEditorViewModel } from '../viewmodel/NoteEditorViewModel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

class RouterParams {
  noteId?: string;
  categoryName?: string;
}

@Entry
@Component
struct NoteEditorPage {
  @State viewModel: NoteEditorViewModel = new NoteEditorViewModel();
  private noteId: string = '';

  async aboutToAppear(): Promise<void> {
    const params: RouterParams = router.getParams() as RouterParams;
    if (params && params.noteId) {
      this.noteId = params.noteId;
      await this.viewModel.loadNote(this.noteId);
    } else if (params && params.categoryName) {
      // 从分类筛选页新建笔记，预设分类
      this.viewModel.setInitialCategory(params.categoryName);
    }
  }

  build() {
    Column() {
      this.buildToolbar()

      Divider()
        .strokeWidth(0.5)
        .color($r('app.color.divider'))

      Scroll() {
        Column() {
          TextInput({ placeholder: '笔记标题', text: $$this.viewModel.note.title })
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor(Color.Transparent)
            .borderRadius(0)
            .padding({ left: 16, right: 16, top: 12, bottom: 8 })
            .onChange((value: string) => {
              this.viewModel.updateTitle(value);
            })

          Text('分类: ' + (this.viewModel.note.category?.name || '其他'))
            .fontSize(13)
            .fontColor($r('app.color.primary'))
            .padding({ left: 16, right: 16, bottom: 8 })

          Divider()
            .strokeWidth(0.5)
            .color($r('app.color.divider'))
            .margin({ left: 16, right: 16 })

          TextArea({ placeholder: '开始记录…', text: $$this.viewModel.note.content })
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor(Color.Transparent)
            .constraintSize({ minHeight: 200 })
            .padding(16)
            .onChange((value: string) => {
              this.viewModel.updateContent(value);
            })
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.card_background'))
  }

  @Builder
  buildToolbar() {
    Row() {
      Button() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(22)
          .fontColor([$r('app.color.text_primary')])
      }
      .type(ButtonType.Circle)
      .width(36)
      .height(36)
      .backgroundColor($r('app.color.card_background'))
      .onClick(async () => {
        if (this.viewModel.isDirty) {
          await this.viewModel.save();
        }
        router.back();
      })

      Blank()

      Text(this.viewModel.isNew ? '新建笔记' : '编辑笔记')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      if (this.viewModel.isDirty) {
        Circle({ width: 8, height: 8 })
          .fill('#FF9500')
          .margin({ left: 6 })
      }

      Blank()

      Button($r('app.string.save'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.viewModel.isDirty ? '#FFFFFF' : $r('app.color.text_secondary'))
        .backgroundColor(this.viewModel.isDirty ? $r('app.color.primary') : $r('app.color.background'))
        .borderRadius(16)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .enabled(this.viewModel.isDirty)
        .onClick(async () => {
          const saved: boolean = await this.viewModel.save();
          if (saved) {
            promptAction.showToast({ message: '已保存', duration: 1500 });
          } else {
            promptAction.showToast({ message: this.viewModel.errorMessage || '保存失败', duration: 2000 });
          }
        })
    }
    .width('100%')
    .padding({ left: 4, right: 8, top: 4, bottom: 4 })
  }
}
