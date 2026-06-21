import { Note } from '../model/Note';
import { CATEGORY_COLORS } from '../model/NoteCategory';
import router from '@ohos.router';
import { ROUTE_NOTE_EDITOR } from '../common/Constants';

class NoteRouterParams {
  noteId: string = '';
}

/**
 * NoteCard — 笔记卡片组件
 * 展示笔记标题、预览、分类标签、时间、同步状态
 */
@Component
export struct NoteCard {
  @ObjectLink note: Note;
  @Prop compactMode: boolean = false;
  onDelete?: (noteId: string) => void;

  build() {
    Column() {
      Row() {
        // 标题
        Text(this.note.title || '无标题')
          .fontSize(this.compactMode ? 15 : 17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        // 同步状态标记
        if (this.note.syncStatus === 'pending') {
          Text('⟳')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 6 })
        }
      }
      .width('100%')

      // 内容预览
      if (this.note.preview && !this.compactMode) {
        Text(this.note.preview)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
          .width('100%')
      }

      // 底栏: 分类标签 + 时间
      Row() {
        // AI 摘要标记
        if (this.note.hasAiSummary) {
          Row() {
            Text('🪄')
              .fontSize(10)
              .margin({ right: 2 })
            Text('AI')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
          }
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
          .backgroundColor('#E8F5E9')
          .margin({ right: 8 })
        }

        // 分类标签
        Row() {
          Circle({ width: 6, height: 6 })
            .fill(this.note.category?.color || CATEGORY_COLORS['其他'])
            .margin({ right: 3 })

          Text(this.note.category?.getDisplayLabel() || '#其他')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
        }
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .borderRadius(10)
        .backgroundColor($r('app.color.background'))

        Blank()

        // 时间
        Text(this.formatTime(this.note.updatedAt))
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .margin({ top: 10 })
      .alignItems(VerticalAlign.Center)
    }
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.card_background'))
    .shadow({
      radius: 4,
      color: '#00000010',
      offsetX: 0,
      offsetY: 2
    })
    .margin({ bottom: 10 })
    .onClick(() => {
      const rp: NoteRouterParams = new NoteRouterParams();
      rp.noteId = this.note.id;
      router.pushUrl({
        url: ROUTE_NOTE_EDITOR,
        params: rp
      });
    })
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          if (this.onDelete) {
            this.onDelete(this.note.id);
          }
        })
    )
  }

  /**
   * 格式化时间显示
   */
  private formatTime(isoStr: string): string {
    if (!isoStr) {
      return '';
    }
    try {
      const date = new Date(isoStr);
      const now = new Date();
      const diff = now.getTime() - date.getTime();

      if (diff < 60000) return '刚刚';
      if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前';
      if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前';
      if (diff < 604800000) return Math.floor(diff / 86400000) + '天前';

      const y = date.getFullYear();
      const m = (date.getMonth() + 1).toString().padStart(2, '0');
      const d = date.getDate().toString().padStart(2, '0');
      return y + '-' + m + '-' + d;
    } catch (e) {
      return '';
    }
  }
}
