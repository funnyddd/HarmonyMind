import { NoteCategory } from '../model/NoteCategory';

/**
 * CategoryChipGroup — 分类标签组组件
 * 水平可滚动分类筛选栏
 * 「全部分类」为默认选项
 */
@Component
export struct CategoryChipGroup {
  @ObjectLink categories: NoteCategory[];
  @Prop selectedCategoryName: string = '';
  onSelect?: (category: NoteCategory | null) => void;

  build() {
    Scroll() {
      Row() {
        // 「全部分类」Chip
        this.ChipBuilder('全部分类', this.selectedCategoryName === '', () => {
          this.onSelect?.(null);
        })

        // 各分类 Chip
        ForEach(this.categories, (category: NoteCategory) => {
          this.ChipBuilder(
            category.name,
            this.selectedCategoryName === category.name,
            () => {
              this.onSelect?.(category);
            },
            category.color
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
  ChipBuilder(
    label: string,
    isSelected: boolean,
    onClick: () => void,
    accentColor?: string
  ) {
    Row() {
      // 选中状态的颜色圆点
      if (isSelected && accentColor) {
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
    .backgroundColor(isSelected ? ($r('app.color.primary')) : $r('app.color.background'))
    .margin({ right: 8 })
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
    .onClick(onClick)
  }
}
