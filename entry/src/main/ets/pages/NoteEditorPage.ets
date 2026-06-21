import { NoteCategory } from '../model/NoteCategory';
import { NoteEditorViewModel } from '../viewmodel/NoteEditorViewModel';
import { SelectCategoryDialog } from '../components/SelectCategoryDialog';
import { ServiceFactory } from '../domain/factory/ServiceFactory';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct NoteEditorPage {
  @State viewModel: NoteEditorViewModel = new NoteEditorViewModel();
  @State catName: string = '其他';
  @State catList: NoteCategory[] = [];
  @State title: string = '';
  @State content: string = '';
  private noteId: string = '';
  private catDialog: CustomDialogController = new CustomDialogController({
    builder: SelectCategoryDialog({
      categories: this.catList,
      currentName: this.catName,
      onSelect: (name: string) => {
        this.catName = name;
        this.viewModel.setCategory(name);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  async aboutToAppear(): Promise<void> {
    // 加载分类列表
    try {
      const repo = ServiceFactory.getInstance().getNoteRepository();
      const r = await repo.getAllCategories();
      if (r.isSuccess && r.data) { this.catList = r.data; }
    } catch (e) {}

    // 判断新建还是编辑
    const raw: Object = router.getParams() as Object;
    const noteId: string = raw ? (raw as Record<string, Object>)['noteId'] as string : '';

    if (noteId && noteId.length > 0) {
      // 编辑已有笔记
      this.noteId = noteId;
      await this.viewModel.loadNote(noteId);
      this.title = this.viewModel.note.title;
      this.content = this.viewModel.note.content;
      this.catName = this.viewModel.getCategoryName();
    } else {
      // 新建笔记：默认用第一个非"其他"分类
      for (let i = 0; i < this.catList.length; i++) {
        if (this.catList[i].name !== '其他') {
          this.catName = this.catList[i].name;
          break;
        }
      }
      this.viewModel.setCategory(this.catName);
    }
  }

  private openCategoryPicker(): void {
    // 更新 dialog 数据后打开
    this.catDialog = new CustomDialogController({
      builder: SelectCategoryDialog({
        categories: this.catList,
        currentName: this.catName,
        onSelect: (name: string) => {
          this.catName = name;
          this.viewModel.setCategory(name);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    this.catDialog.open();
  }

  // ==================== 保存 ====================
  private async doSave(): Promise<void> {
    this.viewModel.note.title = this.title;
    this.viewModel.note.content = this.content;
    const ok: boolean = await this.viewModel.save(this.catName);
    promptAction.showToast({
      message: ok ? '已保存' : (this.viewModel.errorMessage || '保存失败'),
      duration: 1500
    });
  }

  // ==================== UI ====================
  build() {
    Column() {
      // 工具栏
      Row() {
        Button() {
          SymbolGlyph($r('sys.symbol.arrow_left')).fontSize(22)
            .fontColor([$r('app.color.text_primary')])
        }
        .type(ButtonType.Circle).width(36).height(36)
        .backgroundColor($r('app.color.card_background'))
        .onClick(async () => {
          if (this.viewModel.isDirty) {
            this.viewModel.note.title = this.title;
            this.viewModel.note.content = this.content;
            await this.viewModel.save(this.catName);
          }
          router.back();
        })

        Blank()

        Text(this.viewModel.isNew ? '新建笔记' : '编辑笔记')
          .fontSize(16).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        if (this.viewModel.isDirty) {
          Circle({ width: 8, height: 8 }).fill('#FF9500').margin({ left: 6 })
        }

        Blank()

        if (!this.viewModel.isNew) {
          Button() {
            SymbolGlyph($r('sys.symbol.trash')).fontSize(18).fontColor(['#FF3B30'])
          }
          .type(ButtonType.Circle).width(36).height(36)
          .backgroundColor($r('app.color.card_background')).margin({ right: 4 })
          .onClick(async () => {
            const ok: boolean = await this.viewModel.deleteNote();
            promptAction.showToast({ message: ok ? '已删除' : '删除失败', duration: 1500 });
            if (ok) { router.back(); }
          })
        }

        Button($r('app.string.save'))
          .fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor(this.viewModel.isDirty ? '#FFFFFF' : $r('app.color.text_secondary'))
          .backgroundColor(this.viewModel.isDirty ? $r('app.color.primary') : $r('app.color.background'))
          .borderRadius(16)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .enabled(this.viewModel.isDirty)
          .onClick(() => { this.doSave(); })
      }
      .width('100%')
      .padding({ left: 4, right: 8, top: 4, bottom: 4 })

      Divider().strokeWidth(0.5).color($r('app.color.divider'))

      // 标题
      TextInput({ placeholder: '笔记标题', text: $$this.title })
        .fontSize(22).fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor(Color.Transparent).borderRadius(0)
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })
        .onChange((value: string) => {
          this.title = value;
          this.viewModel.updateTitle(value);
        })

      // ★ 分类选择行：纯 Text + onClick，点它弹出系统原生菜单
      Row() {
        Text('分类: ' + this.catName)
          .fontSize(13).fontColor($r('app.color.primary'))
          .layoutWeight(1)

        Text('>')
          .fontSize(13).fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 8 })
      .onClick(() => { this.openCategoryPicker(); })

      Divider().strokeWidth(0.5).color($r('app.color.divider'))
        .margin({ left: 16, right: 16 })

      // 正文
      Scroll() {
        TextArea({ placeholder: '开始记录…', text: $$this.content })
          .fontSize(16).fontColor($r('app.color.text_primary'))
          .backgroundColor(Color.Transparent)
          .constraintSize({ minHeight: 300 })
          .padding(16)
          .onChange((value: string) => {
            this.content = value;
            this.viewModel.updateContent(value);
          })
      }
      .layoutWeight(1).scrollBar(BarState.Auto)
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.card_background'))
  }
}
