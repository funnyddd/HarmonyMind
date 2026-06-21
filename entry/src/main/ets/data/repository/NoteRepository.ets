import { Note } from '../../model/Note';
import { NoteCategory } from '../../model/NoteCategory';
import { Result, success, failure } from '../../common/Result';
import { Logger, getLogger } from '../../common/Logger';
import { LocalNoteDataSource } from '../datasource/local/LocalNoteDataSource';
import {
  ERROR_NOTE_NOT_FOUND
} from '../../common/Constants';

const TAG = 'NoteRepository';
const log: Logger = getLogger(TAG);

/**
 * NoteRepository — 笔记数据仓库
 *
 * 数据源抽象层：当前以 LocalNoteDataSource 为主要数据源。
 * Phase 3 升级为 本地 + 分布式 双数据源 (透明切换)。
 * Phase 4 增加 AI 数据源写入能力。
 */
export class NoteRepository {
  private localDataSource: LocalNoteDataSource;

  constructor() {
    this.localDataSource = new LocalNoteDataSource();
  }

  /**
   * 生成唯一 ID
   */
  generateId(): string {
    return Date.now() + '_' + Math.random().toString(36).substring(2, 9);
  }

  /**
   * 创建新笔记
   */
  async createNote(
    title: string,
    content: string,
    categoryName: string
  ): Promise<Result<Note>> {
    const note = new Note(
      this.generateId(),
      title,
      content,
      new NoteCategory(categoryName || '其他'),
      new Date().toISOString(),
      new Date().toISOString()
    );
    note.updatePreview();
    note.syncStatus = 'local_only';

    const result = await this.localDataSource.insertNote(note);

    if (result.isSuccess) {
      log.info('Note created: id=' + note.id + ', title=' + note.title);
      return success(note);
    } else {
      return failure(result.error, result.code, result.message);
    }
  }

  /**
   * 获取单条笔记
   */
  async getNoteById(id: string): Promise<Result<Note | null>> {
    return await this.localDataSource.getNoteById(id);
  }

  /**
   * 获取所有笔记列表
   */
  async getAllNotes(
    limit: number = 100,
    offset: number = 0
  ): Promise<Result<Note[]>> {
    return await this.localDataSource.getAllNotes(limit, offset);
  }

  /**
   * 按分类获取笔记
   */
  async getNotesByCategory(categoryName: string): Promise<Result<Note[]>> {
    return await this.localDataSource.getNotesByCategory(categoryName);
  }

  /**
   * 搜索笔记
   */
  async searchNotes(keyword: string): Promise<Result<Note[]>> {
    if (!keyword || keyword.trim().length === 0) {
      return success([]);
    }
    return await this.localDataSource.searchNotes(keyword.trim());
  }

  /**
   * 更新笔记
   */
  async updateNote(note: Note): Promise<Result<Note>> {
    note.updatedAt = new Date().toISOString();
    note.updatePreview();
    note.version += 1;
    note.syncStatus = 'pending';

    const result = await this.localDataSource.updateNote(note);

    if (result.isSuccess) {
      log.info('Note updated: id=' + note.id + ', version=' + note.version);
      return success(note);
    } else {
      return failure(result.error, result.code, result.message);
    }
  }

  /**
   * 更新笔记 AI 摘要
   */
  async updateAISummary(
    noteId: string,
    summary: string,
    suggestedCategory?: string
  ): Promise<Result<Note>> {
    const noteResult = await this.getNoteById(noteId);

    if (noteResult.isFailure || !noteResult.data) {
      return failure(ERROR_NOTE_NOT_FOUND, 0, '笔记不存在: ' + noteId);
    }

    const note = noteResult.data;
    note.aiSummary = summary;
    note.hasAiSummary = true;

    if (suggestedCategory) {
      note.category = new NoteCategory(suggestedCategory);
    }

    return await this.updateNote(note);
  }

  /**
   * 更新笔记同步状态
   */
  async updateSyncStatus(
    noteId: string,
    status: 'synced' | 'pending' | 'conflict'
  ): Promise<Result<boolean>> {
    const result = await this.localDataSource.updateSyncStatus(noteId, status);
    return result;
  }

  /**
   * 删除笔记
   */
  async deleteNote(id: string): Promise<Result<boolean>> {
    return await this.localDataSource.deleteNote(id);
  }

  /**
   * 批量保存笔记 (用于分布式同步)
   */
  async saveNotes(notes: Note[]): Promise<Result<boolean>> {
    return await this.localDataSource.insertNotes(notes);
  }

  /**
   * 获取所有分类
   */
  async getAllCategories(): Promise<Result<NoteCategory[]>> {
    return await this.localDataSource.getAllCategories();
  }

  /**
   * 保存分类
   */
  async saveCategory(category: NoteCategory): Promise<Result<boolean>> {
    return await this.localDataSource.saveCategory(category);
  }

  /**
   * 删除分类及旗下所有笔记
   */
  async deleteCategory(categoryName: string): Promise<Result<number>> {
    return await this.localDataSource.deleteNotesByCategory(categoryName);
  }

  /**
   * 仅删除分类本身（保留笔记）
   */
  async deleteCategoryOnly(categoryName: string): Promise<Result<boolean>> {
    return await this.localDataSource.deleteCategory(categoryName);
  }
}
