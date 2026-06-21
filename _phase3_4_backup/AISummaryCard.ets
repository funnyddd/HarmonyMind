import { AISummaryResult } from '../model/AISummaryResult';

/**
 * AISummaryCard — AI 摘要展示卡片
 * 展示 AI 生成的摘要、标签、情感分析、置信度等信息
 */
@Component
export struct AISummaryCard {
  @Prop summaryResult: AISummaryResult | null = null;
  @Prop isGenerating: boolean = false;

  build() {
    if (this.isGenerating) {
      this.buildLoadingState();
    } else if (this.summaryResult) {
      this.buildSummaryContent();
    }
  }

  @Builder
  buildLoadingState() {
    Column() {
      Row() {
        LoadingProgress()
          .width(18)
          .height(18)
          .margin({ right: 8 })

        Text('正在生成 AI 摘要…')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }

      // 骨架屏动画
      Column() {
        Row().width('100%').height(12).borderRadius(6)
          .backgroundColor('#E5E5EA')
          .margin({ top: 12 })
        Row().width('80%').height(12).borderRadius(6)
          .backgroundColor('#E5E5EA')
          .margin({ top: 8 })
        Row().width('60%').height(12).borderRadius(6)
          .backgroundColor('#E5E5EA')
          .margin({ top: 8 })
      }
    }
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.card_background'))
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  buildSummaryContent() {
    Column() {
      // 标题栏
      Row() {
        Text('✨')
          .fontSize(16)
          .margin({ right: 6 })

        Text('AI 摘要')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Blank()

        // AI 来源标记
        Text(this.summaryResult!.source === 'cloud' ? '☁️ 云端' : '📱 端侧')
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
          .backgroundColor(this.summaryResult!.source === 'cloud' ? '#E3F2FD' : '#F3E5F5')
      }
      .width('100%')

      Divider()
        .margin({ top: 10, bottom: 10 })

      // 摘要内容
      Text(this.summaryResult!.summary)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .lineHeight(22)
        .width('100%')

      // 关键标签
      if (this.summaryResult!.keyTags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.summaryResult!.keyTags, (tag: string) => {
            Text('#' + tag)
              .fontSize(11)
              .fontColor('#1E88E5')
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .borderRadius(10)
              .backgroundColor('#E3F2FD')
              .margin({ right: 6, top: 4 })
          })
        }
        .width('100%')
        .margin({ top: 10 })
      }

      // 建议分类
      if (this.summaryResult!.suggestedCategory && this.summaryResult!.suggestedCategory !== '其他') {
        Row() {
          Text('AI 建议分类: ')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))

          Text('#' + this.summaryResult!.suggestedCategory)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.primary'))
        }
        .margin({ top: 10 })
      }

      // 底部元信息
      Row() {
        // 情感
        Text(this.getSentimentLabel(this.summaryResult!.sentiment))
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
          .backgroundColor('#F5F5F5')

        Text(' · ')
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))

        // 置信度
        Text('置信度: ' + Math.round(this.summaryResult!.confidence * 100) + '%')
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))

        if (this.summaryResult!.tokensUsed > 0) {
          Text(' · ')
            .fontSize(10)
            .fontColor($r('app.color.text_secondary'))
          Text(this.summaryResult!.tokensUsed + ' tokens')
            .fontSize(10)
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .width('100%')
      .margin({ top: 12 })
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
    .width('100%')
    .margin({ bottom: 12 })
  }

  private getSentimentLabel(sentiment: string): string {
    switch (sentiment) {
      case 'positive': return '😊 正面';
      case 'negative': return '😟 负面';
      default: return '😐 中性';
    }
  }
}
