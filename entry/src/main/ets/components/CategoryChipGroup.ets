import { NoteCategory } from '../model/NoteCategory';

/** 模块级变量：父组件重渲染导致组件重建时保持选中状态 */
let _sel: string = '';

@Component
export struct CategoryChipGroup {
  @Prop categories: NoteCategory[] = [];
  @State selectedName: string = _sel;
  onSelect?: (category: NoteCategory | null) => void;

  build() {
    Scroll() {
      Row() {
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
          _sel = '';
          this.selectedName = '';
          this.onSelect?.(null);
        })

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
            _sel = category.name;
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
