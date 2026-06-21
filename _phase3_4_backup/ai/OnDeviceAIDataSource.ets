import { AISummaryResult } from '../../../model/AISummaryResult';
import { Note } from '../../../model/Note';
import { Result, success, failure } from '../../../common/Result';
import { Logger, getLogger } from '../../../common/Logger';
import {
  AI_MAX_SUMMARY_LENGTH,
  ERROR_AI_SERVICE
} from '../../../common/Constants';

const TAG = 'OnDeviceAIDataSource';
const log: Logger = getLogger(TAG);

/**
 * Interface for keyword category matching rules.
 * Declared for ArkTS strict mode (replaces Record<string, string[]>).
 */
interface CategoryRulesData {
  [key: string]: string[];
}

/**
 * Interface for word frequency map used in keyword extraction.
 * Declared for ArkTS strict mode (replaces Record<string, number>).
 */
interface WordFreqData {
  [key: string]: number;
}

/**
 * Interface for categorize result returned by categorizeNote.
 * Declared for ArkTS strict mode (replaces inline object literal).
 */
interface CategorizeResultData {
  category: string;
  confidence: number;
}

/**
 * OnDeviceAIDataSource — 端侧 AI 数据源
 *
 * 使用 @ohos.ai 或 MindSpore Lite 进行端侧推理。
 * 注意：端侧模型需要额外部署，当前实现为规则引擎降级方案。
 * 可在 Phase 4 替换为真实模型推理。
 */
export class OnDeviceAIDataSource {
  private isModelLoaded: boolean = false;

  /**
   * 加载端侧模型
   */
  async loadModel(): Promise<boolean> {
    try {
      // TODO Phase 4: 使用 MindSpore Lite 加载端侧 LLM 模型
      // import mindSporeLite from '@ohos.ai.mindSporeLite';
      // const context = ...;
      // this.model = await mindSporeLite.loadModelFromFile(context, 'model.ms');
      // this.isModelLoaded = true;

      log.info('On-device model loaded (rule-based fallback active)');
      this.isModelLoaded = true;
      return true;
    } catch (err) {
      log.error('Failed to load on-device model', err);
      return false;
    }
  }

  /**
   * 生成笔记摘要 (端侧规则引擎降级方案)
   */
  async summarizeNote(note: Note): Promise<Result<AISummaryResult>> {
    if (!this.isModelLoaded) {
      await this.loadModel();
    }

    try {
      const result: AISummaryResult = new AISummaryResult('', note.id, 'on_device');

      // 规则引擎：提取核心句作为摘要
      const summary: string = this.extractSummary(note.content);
      result.summary = summary;

      // 简单的关键词提取
      result.keyTags = this.extractKeywords(note.content);

      // 基础情感分析
      result.sentiment = this.analyzeSentiment(note.content);
      result.confidence = 0.6;
      result.tokensUsed = note.content.length;
      result.source = 'on_device';

      log.info('On-device summary generated (rule-based): noteId=' + note.id +
        ', summaryLength=' + summary.length + ', tagCount=' + result.keyTags.length);

      return success(result);
    } catch (err) {
      log.error('On-device summarize failed: noteId=' + note.id, err);
      return failure(ERROR_AI_SERVICE, err as number, '端侧摘要生成失败');
    }
  }

  /**
   * 智能分类 (规则引擎降级方案)
   */
  async categorizeNote(note: Note): Promise<Result<CategorizeResultData>> {
    if (!this.isModelLoaded) {
      await this.loadModel();
    }

    try {
      const text: string = (note.title + ' ' + note.content).toLowerCase();

      // 关键词匹配规则 — declared with interface for ArkTS strict mode
      const categoryRules: CategoryRulesData = {
        '工作': ['工作', '项目', '任务', '开会', '周报', '评审', '需求', '上线'],
        '学习': ['学习', '课程', '笔记', '考试', '复习', '编程', '算法', '英语'],
        '生活': ['生活', '购物', '健康', '运动', '美食', '做饭', '家务'],
        '灵感': ['灵感', '创意', '想法', '点子', '设计', '画', '音乐'],
        '会议': ['会议', '纪要', '讨论', '汇报', '演示', 'ppt', '总结'],
        '读书': ['读书', '阅读', '书', '读后感', '摘要', '作者'],
        '旅行': ['旅行', '旅游', '攻略', '酒店', '机票', '景点']
      };

      let bestCategory: string = '其他';
      let bestScore: number = 0;

      // Use Object.keys().forEach() instead of for...in (ArkTS strict mode)
      const categoryKeys: string[] = Object.keys(categoryRules);
      categoryKeys.forEach((key: string) => {
        let score: number = 0;
        const keywords: string[] = categoryRules[key];
        for (const keyword of keywords) {
          if (text.includes(keyword)) {
            score++;
          }
        }
        if (score > bestScore) {
          bestScore = score;
          bestCategory = key;
        }
      });

      const confidence: number = Math.min(0.3 + bestScore * 0.15, 0.9);
      const categorizeResult: CategorizeResultData = {
        category: bestCategory,
        confidence: confidence
      };
      return success(categorizeResult);
    } catch (err) {
      log.error('On-device categorize failed: noteId=' + note.id, err);
      return failure(ERROR_AI_SERVICE, err as number, '端侧分类失败');
    }
  }

  // ========== 规则引擎辅助方法 ==========

  /**
   * 提取摘要 (取前段关键词密集的句子)
   */
  private extractSummary(content: string): string {
    if (!content || content.length === 0) {
      return '（无内容）';
    }

    // 按句子分割
    const sentences: string[] = content
      .replace(/([。！？；\n]+)/g, '$1|')
      .split('|')
      .filter(s => s.trim().length > 5);

    if (sentences.length === 0) {
      return content.substring(0, Math.min(AI_MAX_SUMMARY_LENGTH, content.length));
    }

    // 选择前3句作为摘要候选
    const topSentences: string[] = sentences.slice(0, Math.min(3, sentences.length));
    const summary: string = topSentences.join('。');

    return summary.length > AI_MAX_SUMMARY_LENGTH
      ? summary.substring(0, AI_MAX_SUMMARY_LENGTH) + '...'
      : summary;
  }

  /**
   * 提取关键词 (TF-like 简单实现)
   */
  private extractKeywords(content: string): string[] {
    const stopWords: Set<string> = new Set([
      '的', '了', '在', '是', '我', '你', '他', '她', '它',
      '这', '那', '和', '与', '或者', '但', '也', '都', '就',
      '不', '很', '要', '有', '会', '能', '可以', '一个',
      '这个', '那个', '什么', '怎么', '为什么', '如果'
    ]);

    // 简单分词 (按标点和空格分割)
    const words: string[] = content
      .replace(/[，,。！？、：；""''（）\(\)\[\]【】\s\n]+/g, ' ')
      .split(' ')
      .filter(w => w.length >= 2 && !stopWords.has(w));

    // 统计词频 — declared with interface for ArkTS strict mode
    const freq: WordFreqData = {};
    for (const word of words) {
      freq[word] = (freq[word] || 0) + 1;
    }

    // 按频率排序，取前5个
    // Fix destructuring: map(([word]) => word) → map((entry) => entry[0])
    return Object.entries(freq)
      .sort((a: [string, number], b: [string, number]) => b[1] - a[1])
      .slice(0, 5)
      .map((entry: [string, number]) => entry[0]);
  }

  /**
   * 简单情感分析
   */
  private analyzeSentiment(content: string): 'positive' | 'negative' | 'neutral' {
    const positiveWords: string[] = ['好', '棒', '开心', '喜欢', '成功', '完美', '优秀', '精彩', '美好', '赞'];
    const negativeWords: string[] = ['差', '糟', '失败', '问题', '困难', '错误', '遗憾', '不好', '麻烦'];

    let positiveScore: number = 0;
    let negativeScore: number = 0;

    for (const word of positiveWords) {
      if (content.includes(word)) positiveScore++;
    }
    for (const word of negativeWords) {
      if (content.includes(word)) negativeScore++;
    }

    if (positiveScore > negativeScore) return 'positive';
    if (negativeScore > positiveScore) return 'negative';
    return 'neutral';
  }
}
