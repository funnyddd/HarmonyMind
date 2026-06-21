import { Note } from '../model/Note';
import { NoteCategory } from '../model/NoteCategory';
import { NoteListViewModel } from '../viewmodel/NoteListViewModel';
import { NoteCard } from '../components/NoteCard';
import { CategoryChipGroup } from '../components/CategoryChipGroup';
import { CreateCategoryDialog } from '../components/CreateCategoryDialog';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import {
  ROUTE_NOTE_EDITOR,
  ROUTE_SEARCH
} from '../common/Constants';

/**
 * NoteListPage — 笔记列表主页
 *
 * 功能:
 * - 展示笔记卡片列表
 * - 分类筛选 (CategoryChipGroup)
 * - 下拉刷新 + 同步
 * - FAB 新建笔记
 * - 搜索/同步/设置入口
 * - 长按删除
 */
@Entry
@Component
struct NoteListPage {
  @State viewModel: NoteListViewModel = new NoteListViewModel();
  @State showDeleteDialog: boolean = false;
  @State deleteTargetId: string = '';

  private createDialogController: CustomDialogController = new CustomDialogController({
    builder: CreateCategoryDialog({
      onConfirm: (name: string, color: string) => {
        this.onCreateCategory(name, color);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  async aboutToAppear(): Promise<void> {
    await this.viewModel.loadCategories();
    await this.viewModel.loadNotes();
  }

  onPageShow(): void {
    this.viewModel.loadNotes();
  }

  aboutToDisappear(): void {
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 标题栏
        this.buildTitleBar()

        // 分类筛选 + 新建分类按钮
        Row() {
          CategoryChipGroup({
            categories: this.viewModel.categories,
            onSelect: (category: NoteCategory | null) => {
              this.viewModel.filterByCategory(category);
            },
            onDeleteCategory: (category: NoteCategory) => {
              promptAction.showDialog({
                title: '删除分类',
                message: '确定删除分类「' + category.name + '」？笔记不会删除',
                buttons: [
                  { text: '取消', color: '#8E8E93' },
                  { text: '删除', color: '#FF3B30' }
                ]
              }).then((data: Object) => {
                const idx: number = (data as Record<string, Object>)['index'] as number;
                if (idx === 1) {
                  this.viewModel.deleteCategory(category.name);
                }
              });
            }
          })
            .layoutWeight(1)

          Button() {
            SymbolGlyph($r('sys.symbol.plus_circle'))
              .fontSize(22)
              .fontColor([$r('app.color.primary')])
          }
          .type(ButtonType.Circle)
          .width(32)
          .height(32)
          .backgroundColor(Color.Transparent)
          .margin({ right: 12 })
          .onClick(() => {
            this.createDialogController.open();
          })
        }
        .width('100%')

        Divider()
          .strokeWidth(0.5)
          .color($r('app.color.divider'))

        // 内容区
        if (this.viewModel.isLoading) {
          this.buildLoadingState()
        } else if (this.viewModel.notes.length === 0) {
          this.buildEmptyState()
        } else {
          this.buildNoteList()
        }
      }

      // FAB 新建按钮
      Button() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(28)
          .fontColor(['#FFFFFF'])
      }
      .type(ButtonType.Circle)
      .width(56)
      .height(56)
      .backgroundColor($r('app.color.primary'))
      .shadow({
        radius: 12,
        color: '#00000020',
        offsetX: 0,
        offsetY: 4
      })
      .margin({ right: 20, bottom: 20 })
      .onClick(() => {
        const cat = this.viewModel.selectedCategory?.name || '';
        AppStorage.setOrCreate('draftCat', cat);
        router.pushUrl({ url: ROUTE_NOTE_EDITOR, params: { __cat: cat } });
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildTitleBar() {
    Row() {
      Text($r('app.string.note_list_title'))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Blank()

      Button() {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(20)
          .fontColor([$r('app.color.text_primary')])
      }
      .type(ButtonType.Circle)
      .width(36)
      .height(36)
      .backgroundColor($r('app.color.background'))
      .margin({ right: 6 })
      .onClick(() => {
        router.pushUrl({ url: ROUTE_SEARCH });
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  buildNoteList() {
    Column() {
      Refresh({ refreshing: $$this.viewModel.isRefreshing }) {
        List() {
          ForEach(this.viewModel.notes, (note: Note) => {
            ListItem() {
              NoteCard({
                note: note,
                onDelete: (id: string) => {
                  this.deleteTargetId = id;
                  this.showDeleteDialog = true;
                }
              })
            }
            .padding({ left: 16, right: 16 })
          }, (note: Note) => note.id)
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .onReachEnd(async () => {
          await this.viewModel.loadNotes(
            this.viewModel.selectedCategory || undefined
          );
        })
      }
      .onRefreshing(async () => {
        await this.viewModel.refresh();
      })
    }
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  buildEmptyState() {
    Column() {
      SymbolGlyph($r('sys.symbol.doc_text'))
        .fontSize(64)
        .fontColor([$r('app.color.text_secondary')])
        .margin({ bottom: 16 })

      Text($r('app.string.no_notes'))
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .padding({ left: 40, right: 40 })
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .margin({ bottom: 12 })

      Text('加载中…')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .width('100%')
  }

  private async onCreateCategory(name: string, color: string): Promise<void> {
    const success = await this.viewModel.createCategory(name, color);
    if (success) {
      promptAction.showToast({ message: '分类已创建', duration: 1500 });
    } else {
      promptAction.showToast({ message: this.viewModel.errorMessage || '创建失败', duration: 2000 });
    }
  }
}
