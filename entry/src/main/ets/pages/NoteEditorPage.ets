import { NoteCategory } from '../model/NoteCategory';
import { NoteEditorViewModel } from '../viewmodel/NoteEditorViewModel';
import { ServiceFactory } from '../domain/factory/ServiceFactory';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

class RouterParams {
  noteId?: string;
}

@Entry
@Component
struct NoteEditorPage {
  @State viewModel: NoteEditorViewModel = new NoteEditorViewModel();
  @State catName: string = '其他';
  @State catList: NoteCategory[] = [];
  private noteId: string = '';

  async aboutToAppear(): Promise<void> {
    // 加载分类列表到页面 @State
    try {
      const repo = ServiceFactory.getInstance().getNoteRepository();
      const r = await repo.getAllCategories();
      if (r.isSuccess && r.data) {
        this.catList = r.data;
      }
    } catch (e) {}

    // 同步初始分类名（新建时 ViewModel 已通过 NoteDraft 预设）
    this.catName = this.viewModel.getCategoryName();

    // 编辑已有笔记
    const params: RouterParams = router.getParams() as RouterParams;
    if (params && params.noteId) {
      this.noteId = params.noteId;
      await this.viewModel.loadNote(this.noteId);
      this.catName = this.viewModel.getCategoryName();
    }
  }

  build() {
    Column() {
      this.buildToolbar()

      Divider().strokeWidth(0.5).color($r('app.color.divider'))

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

          // 当前分类
          Text('分类: ' + this.catName)
            .fontSize(13)
            .fontColor($r('app.color.primary'))
            .padding({ left: 16, right: 16, bottom: 4 })

          // 分类切换行（水平滚动，平铺所有分类标签，直接点）
          Scroll() {
            Row() {
              ForEach(this.catList, (cat: NoteCategory, idx: number) => {
                Text(cat.name)
                  .fontSize(12)
                  .fontWeight(this.catName === cat.name ? FontWeight.Medium : FontWeight.Normal)
                  .fontColor(this.catName === cat.name ? '#FFFFFF' : $r('app.color.text_primary'))
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .borderRadius(12)
                  .backgroundColor(this.catName === cat.name ? '#007DFF' : $r('app.color.background'))
                  .margin({ right: 6 })
                  .onClick(() => {
                    this.catName = cat.name;
                    this.viewModel.setCategory(cat.name);
                  })
              }, (cat: NoteCategory, idx: number) => cat.id)
            }
            .padding({ left: 16, right: 16 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .height(32)
          .margin({ bottom: 8 })

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
          await this.viewModel.save(this.catName);
        }
        router.back();
      })

      Blank()

      Text(this.viewModel.isNew ? '新建笔记' : '编辑笔记')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      if (this.viewModel.isDirty) {
        Circle({ width: 8, height: 8 }).fill('#FF9500').margin({ left: 6 })
      }

      Blank()

      // 删除（仅编辑已有笔记）
      if (!this.viewModel.isNew) {
        Button() {
          SymbolGlyph($r('sys.symbol.trash'))
            .fontSize(18)
            .fontColor(['#FF3B30'])
        }
        .type(ButtonType.Circle)
        .width(36)
        .height(36)
        .backgroundColor($r('app.color.card_background'))
        .margin({ right: 4 })
        .onClick(async () => {
          const ok = await this.viewModel.deleteNote();
          promptAction.showToast({ message: ok ? '已删除' : (this.viewModel.errorMessage || '删除失败'), duration: 1500 });
          if (ok) { router.back(); }
        })
      }

      Button($r('app.string.save'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.viewModel.isDirty ? '#FFFFFF' : $r('app.color.text_secondary'))
        .backgroundColor(this.viewModel.isDirty ? $r('app.color.primary') : $r('app.color.background'))
        .borderRadius(16)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .enabled(this.viewModel.isDirty)
        .onClick(async () => {
          const ok = await this.viewModel.save(this.catName);
          promptAction.showToast({ message: ok ? '已保存' : (this.viewModel.errorMessage || '保存失败'), duration: 1500 });
        })
    }
    .width('100%')
    .padding({ left: 4, right: 8, top: 4, bottom: 4 })
  }
}
