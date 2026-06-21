import { NoteCategory } from '../model/NoteCategory';

/**
 * CategoryChipGroup — 分类标签组组件
 * 水平可滚动分类筛选栏，选中状态完全自管理
 */
@Reusable
@Component
export struct CategoryChipGroup {
  @Prop categories: NoteCategory[] = [];
  @State selectedName: string = '';
  onSelect?: (category: NoteCategory | null) => void;

  build() {
    Scroll() {
      Row() {
        // 「全部分类」Chip（内联，不用 @Builder）
        Row() {
          Text('全部分类')
            .fontSize(13)
            .fontWeight(this.selectedName === '' ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.selectedName === '' ? '#FFFFFF' : $r('app.color.text_primary'))
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(16)
        .backgroundColor(this.selectedName === '' ? '#007DFF' : $r('app.color.background'))
        .margin({ right: 8 })
        .onClick(() => {
          this.selectedName = '';
          this.onSelect?.(null);
        })

        // 各分类 Chip（内联）
        ForEach(this.categories, (category: NoteCategory) => {
          Row() {
            if (this.selectedName === category.name && category.color) {
              Circle({ width: 6, height: 6 })
                .fill(category.color)
                .margin({ right: 4 })
            }

            Text(category.name)
              .fontSize(13)
              .fontWeight(this.selectedName === category.name ? FontWeight.Medium : FontWeight.Normal)
              .fontColor(this.selectedName === category.name ? '#FFFFFF' : $r('app.color.text_primary'))
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.selectedName === category.name ? '#007DFF' : $r('app.color.background'))
          .margin({ right: 8 })
          .onClick(() => {
            this.selectedName = category.name;
            this.onSelect?.(category);
          })
        }, (category: NoteCategory) => category.id)
      }
      .padding({ left: 12, right: 12 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .height(44)
  }
}
