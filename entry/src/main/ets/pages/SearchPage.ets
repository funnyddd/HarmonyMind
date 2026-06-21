import { Note } from '../model/Note';
import { ServiceFactory } from '../domain/factory/ServiceFactory';
import { NoteCard } from '../components/NoteCard';
import router from '@ohos.router';
import { ROUTE_NOTE_EDITOR, PARAM_NOTE_ID } from '../common/Constants';

/**
 * SearchPage — 搜索笔记页
 * 支持标题/内容全文搜索，实时搜索建议
 */
@Entry
@Component
struct SearchPage {
  @State searchKeyword: string = '';
  @State searchResults: Note[] = [];
  @State isSearching: boolean = false;
  @State hasSearched: boolean = false;
  @State showHistory: boolean = true;
  @State searchHistory: string[] = [];
  private searchTimeout: number = 0;

  aboutToAppear(): void {
    this.loadSearchHistory();
  }

  build() {
    Column() {
      // 搜索栏
      this.buildSearchBar()

      Divider()
        .strokeWidth(0.5)
        .color($r('app.color.divider'))

      // 内容区域
      if (this.showHistory && !this.hasSearched && this.searchHistory.length > 0) {
        this.buildSearchHistory()
      } else if (this.isSearching) {
        this.buildSearchingState()
      } else if (this.hasSearched && this.searchResults.length === 0) {
        this.buildNoResults()
      } else if (this.searchResults.length > 0) {
        this.buildSearchResults()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildSearchBar() {
    Row() {
      // 返回
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

      // 搜索输入框
      Search({
        placeholder: $r('app.string.search_hint'),
        value: $$this.searchKeyword
      })
        .layoutWeight(1)
        .height(40)
        .borderRadius(20)
        .backgroundColor($r('app.color.card_background'))
        .onChange((value: string) => {
          this.onSearchTextChanged(value);
        })
        .onSubmit((value: string) => {
          this.performSearch(value);
        })

      // 清除按钮
      if (this.searchKeyword.length > 0) {
        Button() {
          SymbolGlyph($r('sys.symbol.xmark_circle'))
            .fontSize(18)
            .fontColor([$r('app.color.text_secondary')])
        }
        .type(ButtonType.Circle)
        .width(32)
        .height(32)
        .backgroundColor($r('app.color.background'))
        .onClick(() => {
          this.searchKeyword = '';
          this.searchResults = [];
          this.hasSearched = false;
          this.showHistory = true;
        })
      }
    }
    .width('100%')
    .padding({ left: 4, right: 12, top: 8, bottom: 8 })
  }

  @Builder
  buildSearchResults() {
    List() {
      ForEach(this.searchResults, (note: Note) => {
        ListItem() {
          NoteCard({
            note: note,
            compactMode: true,
            onDelete: (id: string) => {
              this.deleteNote(id);
            }
          })
        }
        .padding({ left: 16, right: 16, top: 4, bottom: 4 })
      }, (note: Note) => note.id)
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  buildSearchHistory() {
    Column() {
      Row() {
        Text('搜索历史')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Blank()

        Text('清除历史')
          .fontSize(12)
          .fontColor($r('app.color.primary'))
          .onClick(() => {
            this.searchHistory = [];
            this.saveSearchHistory();
          })
      }
      .width('100%')
      .padding(16)

      ForEach(this.searchHistory, (keyword: string, index: number) => {
        Row() {
          SymbolGlyph($r('sys.symbol.clock'))
            .fontSize(14)
            .fontColor([$r('app.color.text_secondary')])
            .margin({ right: 10 })

          Text(keyword)
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .onClick(() => {
          this.searchKeyword = keyword;
          this.performSearch(keyword);
        })
      }, (keyword: string, index: number) => keyword)
    }
    .layoutWeight(1)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildSearchingState() {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .margin({ bottom: 10 })

      Text('搜索中…')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  buildNoResults() {
    Column() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(48)
        .fontColor([$r('app.color.text_secondary')])
        .margin({ bottom: 12 })

      Text('没有找到相关笔记')
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))

      Text('试试其他关键词')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 4 })
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .width('100%')
  }

  /**
   * 搜索文本变化 (防抖)
   */
  private onSearchTextChanged(value: string): void {
    this.showHistory = value.length === 0;

    // 清除之前的定时器
    clearTimeout(this.searchTimeout);

    if (value.trim().length > 0) {
      // 300ms 防抖
      this.searchTimeout = setTimeout(() => {
        this.performSearch(value);
      }, 300);
    }
  }

  /**
   * 执行搜索
   */
  private async performSearch(keyword: string): Promise<void> {
    if (!keyword || keyword.trim().length === 0) {
      return;
    }

    this.isSearching = true;
    this.hasSearched = true;
    this.showHistory = false;

    try {
      const factory = ServiceFactory.getInstance();
      const useCase = factory.getSearchNotesUseCase();
      const result = await useCase.execute(keyword);

      if (result.isSuccess && result.data !== null) {
        this.searchResults = result.data;
      } else {
        this.searchResults = [];
      }

      // 保存搜索历史
      this.addToHistory(keyword.trim());
    } catch (err) {
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  /**
   * 删除笔记
   */
  private async deleteNote(id: string): Promise<void> {
    const factory = ServiceFactory.getInstance();
    const useCase = factory.getDeleteNoteUseCase();
    const result = await useCase.execute(id);

    if (result.isSuccess) {
      this.searchResults = this.searchResults.filter(n => n.id !== id);
    }
  }

  /**
   * 添加到搜索历史
   */
  private addToHistory(keyword: string): void {
    // 去重
    this.searchHistory = this.searchHistory.filter(h => h !== keyword);
    // 加到最前
    this.searchHistory.unshift(keyword);
    // 最多保存10条
    if (this.searchHistory.length > 10) {
      this.searchHistory = this.searchHistory.slice(0, 10);
    }
    this.saveSearchHistory();
  }

  /**
   * 保存搜索历史到本地
   */
  private saveSearchHistory(): void {
    // TODO: 使用 Preferences 持久化
  }

  /**
   * 加载搜索历史
   */
  private loadSearchHistory(): void {
    // TODO: 从 Preferences 读取
    this.searchHistory = [];
  }
}
