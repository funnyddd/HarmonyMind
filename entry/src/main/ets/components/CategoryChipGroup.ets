import { NoteCategory } from '../model/NoteCategory';

/**
 * CategoryChipGroup — 分类标签组组件
 * 水平可滚动分类筛选栏，选中状态组件内部自管理
 */
@Component
export struct CategoryChipGroup {
  @Prop categories: NoteCategory[] = [];
  @State selectedName: string = '';
  onSelect?: (category: NoteCategory | null) => void;

  build() {
    Scroll() {
      Row() {
        // 「全部分类」Chip
        this.Chip('全部分类', this.selectedName === '', '#007DFF', () => {
          this.selectedName = '';
          this.onSelect?.(null);
        })

        // 各分类 Chip
        ForEach(this.categories, (category: NoteCategory) => {
          this.Chip(
            category.name,
            this.selectedName === category.name,
            category.color,
            () => {
              this.selectedName = category.name;
              this.onSelect?.(category);
            }
          )
        }, (category: NoteCategory) => category.id)
      }
      .padding({ left: 12, right: 12 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .height(44)
  }

  @Builder
  Chip(label: string, isSelected: boolean, accentColor: string, onClick: () => void) {
    Row() {
      if (isSelected && accentColor && accentColor !== '#007DFF') {
        Circle({ width: 6, height: 6 })
          .fill(accentColor)
          .margin({ right: 4 })
      }

      Text(label)
        .fontSize(13)
        .fontWeight(isSelected ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(isSelected ? '#FFFFFF' : $r('app.color.text_primary'))
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(16)
    .backgroundColor(isSelected ? '#007DFF' : $r('app.color.background'))
    .margin({ right: 8 })
    .animation({ duration: 200, curve: Curve.EaseInOut })
    .onClick(onClick)
  }
}
