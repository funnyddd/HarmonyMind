/**
 * AISummaryResult — AI 摘要结果模型
 */
@Observed
export class AISummaryResult {
  /** 摘要文本 */
  summary: string;
  /** 原始笔记 ID */
  noteId: string;
  /** 关键标签 (AI 提取) */
  keyTags: string[];
  /** 情感倾向: positive | negative | neutral */
  sentiment: SentimentType;
  /** AI 模型来源 */
  source: 'cloud' | 'on_device';
  /** 生成时间 */
  generatedAt: string;
  /** Token 用量统计 (云端场景) */
  tokensUsed: number;
  /** 置信度 (0-1) */
  confidence: number;
  /** 建议的分类 */
  suggestedCategory: string;
  /** 建议分类的置信度 */
  categoryConfidence: number;

  constructor(
    summary: string = '',
    noteId: string = '',
    source: 'cloud' | 'on_device' = 'on_device'
  ) {
    this.summary = summary;
    this.noteId = noteId;
    this.keyTags = [];
    this.sentiment = 'neutral';
    this.source = source;
    this.generatedAt = new Date().toISOString();
    this.tokensUsed = 0;
    this.confidence = 0;
    this.suggestedCategory = '其他';
    this.categoryConfidence = 0;
  }
}

export type SentimentType = 'positive' | 'negative' | 'neutral';
