import { Note } from '../../../model/Note';
import { Result, success, failure } from '../../../common/Result';
import { Logger, getLogger } from '../../../common/Logger';
import { DistributedKVManager } from './DistributedKVManager';
import { KV_KEY_NOTE_PREFIX, ERROR_SYNC_FAILED } from '../../../common/Constants';

const TAG = 'DistributedNoteDataSource';
const log: Logger = getLogger(TAG);

/**
 * Interface for note data serialized to distributed KVStore.
 * Declared to satisfy ArkTS strict mode requirement that all object literals
 * map to a declared class/interface.
 */
interface NoteKVData {
  id: string;
  title: string;
  content: string;
  category_name: string;
  created_at: string;
  updated_at: string;
  version: number;
}

/**
 * DistributedNoteDataSource — 分布式笔记数据源
 * 包装 DistributedKVManager，提供笔记级别的读写接口
 */
export class DistributedNoteDataSource {
  private kvManager: DistributedKVManager;

  constructor() {
    this.kvManager = DistributedKVManager.getInstance();
  }

  /**
   * 保存笔记到分布式 KVStore
   */
  async saveNote(note: Note): Promise<Result<boolean>> {
    try {
      const key: string = KV_KEY_NOTE_PREFIX + note.id;
      const kvData: NoteKVData = {
        id: note.id,
        title: note.title,
        content: note.content,
        category_name: note.category?.name || '其他',
        created_at: note.createdAt,
        updated_at: note.updatedAt,
        version: note.version
      };
      const value: string = JSON.stringify(kvData);

      const ok: boolean = await this.kvManager.putString(key, value);

      if (ok) {
        note.syncStatus = 'synced';
        return success(true);
      } else {
        return failure(ERROR_SYNC_FAILED, 0, 'KVStore 写入失败');
      }
    } catch (err) {
      log.error('Failed to save note to distributed store', err);
      return failure(ERROR_SYNC_FAILED, err as number, '分布式保存失败: ' + note.id);
    }
  }

  /**
   * 从分布式 KVStore 读取笔记
   */
  async getNote(id: string): Promise<Result<Note | null>> {
    try {
      const key: string = KV_KEY_NOTE_PREFIX + id;
      const value: string | null = await this.kvManager.getString(key);

      if (!value) {
        return success(null);
      }

      const data: NoteKVData = JSON.parse(value) as NoteKVData;
      const note: Note = this.mapToNote(data);
      note.syncStatus = 'synced';
      return success(note);
    } catch (err) {
      log.error('Failed to get note from distributed store', err);
      return failure(ERROR_SYNC_FAILED, err as number, '分布式读取失败: ' + id);
    }
  }

  /**
   * 获取所有分布式笔记
   */
  async getAllNotes(): Promise<Result<Note[]>> {
    try {
      const entries: Map<string, string> = await this.kvManager.getByPrefix(KV_KEY_NOTE_PREFIX);
      const notes: Note[] = [];

      entries.forEach((value: string, key: string) => {
        try {
          const data: NoteKVData = JSON.parse(value) as NoteKVData;
          const note: Note = this.mapToNote(data);
          note.syncStatus = 'synced';
          notes.push(note);
        } catch (err) {
          log.error('Failed to parse note from KV: key=' + key, err);
        }
      });

      log.debug('Loaded ' + notes.length + ' notes from distributed store');
      return success(notes);
    } catch (err) {
      log.error('Failed to get all notes from distributed store', err);
      return failure(ERROR_SYNC_FAILED, err as number, '分布式批量读取失败');
    }
  }

  /**
   * 从分布式存储删除笔记
   */
  async deleteNote(id: string): Promise<Result<boolean>> {
    try {
      const key: string = KV_KEY_NOTE_PREFIX + id;
      const ok: boolean = await this.kvManager.delete(key);

      if (ok) {
        return success(true);
      } else {
        return failure(ERROR_SYNC_FAILED, 0, 'KVStore 删除失败');
      }
    } catch (err) {
      log.error('Failed to delete note from distributed store', err);
      return failure(ERROR_SYNC_FAILED, err as number, '分布式删除失败: ' + id);
    }
  }

  /**
   * 注册数据变化监听
   */
  addChangeListener(listener: (key: string, value: string | null) => void): void {
    this.kvManager.addChangeListener(listener);
  }

  /**
   * 移除数据变化监听
   */
  removeChangeListener(listener: (key: string, value: string | null) => void): void {
    this.kvManager.removeChangeListener(listener);
  }

  // ========== 私有方法 ==========

  /**
   * JSON 对象 → Note 映射
   */
  private mapToNote(data: NoteKVData): Note {
    const note: Note = new Note();
    note.id = data.id || '';
    note.title = data.title || '';
    note.content = data.content || '';
    note.createdAt = data.created_at || '';
    note.updatedAt = data.updated_at || '';
    note.version = data.version || 1;

    if (data.category_name) {
      note.category.name = data.category_name;
    }

    return note;
  }
}
