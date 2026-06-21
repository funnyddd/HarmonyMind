import { Note } from '../../model/Note';
import { NoteCategory, CATEGORY_COLORS, CATEGORY_ICONS } from '../../model/NoteCategory';
import { Result, success, failure } from '../../common/Result';
import { AIService } from '../service/AIService';
import { NoteRepository } from '../../data/repository/NoteRepository';
import { Logger, getLogger } from '../../common/Logger';
import { ERROR_NOTE_NOT_FOUND } from '../../common/Constants';

const TAG = 'CategorizeNoteUseCase';
const log: Logger = getLogger(TAG);

export interface CategoryResult {
  category: string;
  confidence: number;
}

export class CategorizeNoteUseCase {
  private repository: NoteRepository;
  private aiService: AIService | null;

  constructor(repository: NoteRepository, aiService?: AIService) {
    this.repository = repository;
    this.aiService = aiService ?? null;
  }

  async execute(noteId: string, useAI: boolean = false): Promise<Result<NoteCategory>> {
    const noteResult = await this.repository.getNoteById(noteId);

    if (noteResult.isFailure || noteResult.data === null) {
      return failure(ERROR_NOTE_NOT_FOUND, 404, `笔记不存在: ${noteId}`);
    }

    const note: Note = noteResult.data;

    if (useAI && this.aiService !== null) {
      return await this.categorizeWithAI(note);
    }

    return await this.categorizeByRules(note);
  }

  private async categorizeWithAI(note: Note): Promise<Result<NoteCategory>> {
    const aiResult = await this.aiService!.categorize(note);

    if (aiResult.isFailure || aiResult.data === null) {
      log.warn('AI categorization failed, falling back to rules', { error: aiResult.error });
      return await this.categorizeByRules(note);
    }

    const categoryName: string = aiResult.data.category;
    const conf: number = aiResult.data.confidence;
    const category = new NoteCategory(
      categoryName, '', CATEGORY_COLORS[categoryName] || '#8E8E93', CATEGORY_ICONS[categoryName] || 'file'
    );

    log.info('AI categorized note', { noteId: note.id, category: categoryName, confidence: conf });
    return success(category);
  }

  private async categorizeByRules(note: Note): Promise<Result<NoteCategory>> {
    const text: string = (note.title + ' ' + note.content).toLowerCase();

    const rules: Record<string, string[]> = {
      '工作': ['工作', '项目', '任务', '开会', '周报', '评审', '需求', '上线', 'bug'],
      '学习': ['学习', '课程', '笔记', '考试', '复习', '编程', '算法', '英语'],
      '生活': ['生活', '购物', '健康', '运动', '美食', '做饭', '家务'],
      '灵感': ['灵感', '创意', '想法', '点子', '设计', '画', '音乐'],
      '会议': ['会议', '纪要', '讨论', '汇报', '演示', 'ppt', '总结'],
      '读书': ['读书', '阅读', '书', '读后感', '摘要', '作者'],
      '旅行': ['旅行', '旅游', '攻略', '酒店', '机票', '景点']
    };

    let bestCategory: string = '其他';
    let bestScore: number = 0;
    const keys: string[] = Object.keys(rules);

    for (let ki = 0; ki < keys.length; ki++) {
      const key: string = keys[ki];
      let score: number = 0;
      const keywords: string[] = rules[key];
      for (let wi = 0; wi < keywords.length; wi++) {
        if (text.includes(keywords[wi])) {
          score++;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategory = key;
      }
    }

    const category = new NoteCategory(
      bestCategory, '', CATEGORY_COLORS[bestCategory] || '#8E8E93', CATEGORY_ICONS[bestCategory] || 'file'
    );

    return success(category);
  }
}
