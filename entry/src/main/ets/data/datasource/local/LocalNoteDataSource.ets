import relationalStore from '@ohos.data.relationalStore';
import { Note } from '../../../model/Note';
import { NoteCategory } from '../../../model/NoteCategory';
import { Result, success, failure } from '../../../common/Result';
import { Logger, getLogger } from '../../../common/Logger';
import { DatabaseConfig } from '../DatabaseConfig';
import { DB_TABLE_NOTES, DB_TABLE_CATEGORIES, ERROR_DB_OPERATION, ERROR_NOTE_NOT_FOUND } from '../../../common/Constants';

const TAG = 'LocalNoteDataSource';
const log: Logger = getLogger(TAG);

class NoteBucketData {
  id: string = '';
  title: string = '';
  content: string = '';
  preview: string = '';
  category_id: string = '';
  category_name: string = '';
  category_color: string = '';
  category_icon: string = '';
  created_at: string = '';
  updated_at: string = '';
  ai_summary: string = '';
  has_ai_summary: number = 0;
  sync_status: string = '';
  is_favorite: number = 0;
  source_device: string = '';
  version: number = 1;
  sort_order: number = 0;
  icon_name: string = '';
  color: string = '';
  name: string = '';
}

export class LocalNoteDataSource {
  private getStore(): relationalStore.RdbStore {
    const store = DatabaseConfig.getStore();
    if (store === null) {
      throw new Error('Database not initialized');
    }
    return store;
  }

  private buildNoteBucket(note: Note, includeAll: boolean): relationalStore.ValuesBucket {
    const b = new NoteBucketData();
    b.id = note.id;
    b.title = note.title;
    b.content = note.content;
    b.preview = note.preview;
    if (includeAll) {
      b.category_id = note.category ? note.category.id : '';
    }
    b.category_name = note.category ? note.category.name : '其他';
    b.category_color = note.category ? note.category.color : '#8E8E93';
    b.category_icon = note.category ? note.category.iconName : 'file';
    b.created_at = note.createdAt;
    b.updated_at = note.updatedAt;
    if (includeAll) {
      b.ai_summary = note.aiSummary;
      b.has_ai_summary = note.hasAiSummary ? 1 : 0;
      b.sync_status = note.syncStatus;
      b.is_favorite = note.isFavorite ? 1 : 0;
      b.source_device = note.sourceDevice;
      b.version = note.version;
    }
    return b as Object as relationalStore.ValuesBucket;
  }

  async insertNote(note: Note): Promise<Result<boolean>> {
    try {
      const store = this.getStore();
      await store.insert(DB_TABLE_NOTES, {
        'id': note.id,
        'title': note.title,
        'content': note.content,
        'preview': note.preview,
        'category_id': note.category ? note.category.id : '',
        'category_name': note.category ? note.category.name : '其他',
        'category_color': note.category ? note.category.color : '#8E8E93',
        'category_icon': note.category ? note.category.iconName : 'file',
        'created_at': note.createdAt,
        'updated_at': note.updatedAt,
        'ai_summary': note.aiSummary,
        'has_ai_summary': note.hasAiSummary ? 1 : 0,
        'sync_status': note.syncStatus,
        'is_favorite': note.isFavorite ? 1 : 0,
        'source_device': note.sourceDevice,
        'version': note.version
      });
      log.debug('Note inserted/updated: id=' + note.id);
      return success(true);
    } catch (err) {
      const msg = '插入失败 ' + String(err);
      log.error('Failed to insert note: id=' + note.id + ', error=' + String(err));
      return failure(ERROR_DB_OPERATION, -1, msg);
    }
  }

  async insertNotes(notes: Note[]): Promise<Result<boolean>> {
    if (notes.length === 0) {
      return success(true);
    }

    try {
      const store = this.getStore();
      store.beginTransaction();

      for (let i = 0; i < notes.length; i++) {
        const note = notes[i];
        const bucket = this.buildNoteBucket(note, false);

        await store.insert(DB_TABLE_NOTES, bucket);
      }

      store.commit();
      log.info('Batch inserted ' + notes.length + ' notes');
      return success(true);
    } catch (err) {
      log.error('Failed to batch insert notes: error=' + String(err));
      return failure(ERROR_DB_OPERATION, -1, '批量插入失败');
    }
  }

  async getNoteById(id: string): Promise<Result<Note | null>> {
    try {
      const store = this.getStore();
      const predicates = new relationalStore.RdbPredicates(DB_TABLE_NOTES);
      predicates.equalTo('id', id);

      const resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        const note = this.rowToNote(resultSet);
        resultSet.close();
        return success(note);
      }

      resultSet.close();
      return success(null);
    } catch (err) {
      const msg = '查询笔记失败: ' + id;
      log.error('Failed to query note: error=' + String(err) + ', id=' + id);
      return failure(ERROR_DB_OPERATION, -1, msg);
    }
  }

  async getAllNotes(limit: number = 100, offset: number = 0): Promise<Result<Note[]>> {
    try {
      const store = this.getStore();
      const predicates = new relationalStore.RdbPredicates(DB_TABLE_NOTES);
      predicates.orderByDesc('updated_at');
      predicates.limitAs(limit);
      predicates.offsetAs(offset);

      const resultSet = await store.query(predicates);
      const notes: Note[] = [];

      while (resultSet.goToNextRow()) {
        notes.push(this.rowToNote(resultSet));
      }

      resultSet.close();
      log.debug('Queried ' + notes.length + ' notes');
      return success(notes);
    } catch (err) {
      log.error('Failed to query all notes: error=' + String(err));
      return failure(ERROR_DB_OPERATION, -1, '查询所有笔记失败');
    }
  }

  async getNotesByCategory(categoryName: string): Promise<Result<Note[]>> {
    try {
      const store = this.getStore();
      const predicates = new relationalStore.RdbPredicates(DB_TABLE_NOTES);
      predicates.equalTo('category_name', categoryName);
      predicates.orderByDesc('updated_at');

      const resultSet = await store.query(predicates);
      const notes: Note[] = [];

      while (resultSet.goToNextRow()) {
        notes.push(this.rowToNote(resultSet));
      }

      resultSet.close();
      return success(notes);
    } catch (err) {
      const msg = '按分类查询失败: ' + categoryName;
      log.error('Failed to query notes by category: error=' + String(err) + ', category=' + categoryName);
      return failure(ERROR_DB_OPERATION, -1, msg);
    }
  }

  async searchNotes(keyword: string): Promise<Result<Note[]>> {
    try {
      const store = this.getStore();
      const bindArgs: string[] = ['%' + keyword + '%', '%' + keyword + '%'];

      const resultSet = await store.querySql(
        'SELECT * FROM ' + DB_TABLE_NOTES + ' WHERE title LIKE ? OR content LIKE ? ORDER BY updated_at DESC LIMIT 50',
        bindArgs
      );
      const notes: Note[] = [];

      while (resultSet.goToNextRow()) {
        notes.push(this.rowToNote(resultSet));
      }

      resultSet.close();
      log.debug('Search "' + keyword + '" found ' + notes.length + ' notes');
      return success(notes);
    } catch (err) {
      const msg = '搜索失败: ' + keyword;
      log.error('Failed to search notes: error=' + String(err) + ', keyword=' + keyword);
      return failure(ERROR_DB_OPERATION, -1, msg);
    }
  }

  async updateNote(note: Note): Promise<Result<boolean>> {
    try {
      const store = this.getStore();
      const bucket = this.buildNoteBucket(note, false);

      const predicates = new relationalStore.RdbPredicates(DB_TABLE_NOTES);
      predicates.equalTo('id', note.id);

      const rowsUpdated = await store.update(bucket, predicates);

      if (rowsUpdated === 0) {
        log.warn('No note updated: id=' + note.id);
        return failure(ERROR_NOTE_NOT_FOUND, 0, '笔记不存在: ' + note.id);
      }

      log.debug('Note updated: id=' + note.id + ', rows=' + rowsUpdated);
      return success(true);
    } catch (err) {
      const msg = '更新笔记失败: ' + note.id;
      log.error('Failed to update note: error=' + String(err) + ', id=' + note.id);
      return failure(ERROR_DB_OPERATION, -1, msg);
    }
  }

  async deleteNote(id: string): Promise<Result<boolean>> {
    try {
      const store = this.getStore();
      const predicates = new relationalStore.RdbPredicates(DB_TABLE_NOTES);
      predicates.equalTo('id', id);

      const rowsDeleted = await store.delete(predicates);

      if (rowsDeleted === 0) {
        log.warn('No note deleted: id=' + id);
        return failure(ERROR_NOTE_NOT_FOUND, 0, '笔记不存在: ' + id);
      }

      log.debug('Note deleted: id=' + id + ', rows=' + rowsDeleted);
      return success(true);
    } catch (err) {
      const msg = '删除笔记失败: ' + id;
      log.error('Failed to delete note: error=' + String(err) + ', id=' + id);
      return failure(ERROR_DB_OPERATION, -1, msg);
    }
  }

  async deleteNotesByCategory(categoryName: string): Promise<Result<number>> {
    try {
      const store = this.getStore();
      const predicates = new relationalStore.RdbPredicates(DB_TABLE_NOTES);
      predicates.equalTo('category_name', categoryName);

      const rowsDeleted = await store.delete(predicates);
      log.info('Deleted ' + rowsDeleted + ' notes in category "' + categoryName + '"');
      return success(rowsDeleted);
    } catch (err) {
      const msg = '批量删除失败: ' + categoryName;
      log.error('Failed to delete notes by category: error=' + String(err) + ', category=' + categoryName);
      return failure(ERROR_DB_OPERATION, -1, msg);
    }
  }

  async updateSyncStatus(id: string, status: string): Promise<Result<boolean>> {
    try {
      const store = this.getStore();
      const b = new NoteBucketData();
      b.sync_status = status;
      const bucket: relationalStore.ValuesBucket = b as Object as relationalStore.ValuesBucket;
      const predicates = new relationalStore.RdbPredicates(DB_TABLE_NOTES);
      predicates.equalTo('id', id);
      await store.update(bucket, predicates);
      return success(true);
    } catch (err) {
      const msg = '更新同步状态失败: ' + id;
      log.error('Failed to update sync status: error=' + String(err) + ', id=' + id + ', status=' + status);
      return failure(ERROR_DB_OPERATION, -1, msg);
    }
  }

  async getAllCategories(): Promise<Result<NoteCategory[]>> {
    try {
      const store = this.getStore();
      const predicates = new relationalStore.RdbPredicates(DB_TABLE_CATEGORIES);
      predicates.orderByAsc('sort_order');

      const resultSet = await store.query(predicates);
      const categories: NoteCategory[] = [];

      while (resultSet.goToNextRow()) {
        categories.push(this.rowToCategory(resultSet));
      }

      resultSet.close();
      return success(categories);
    } catch (err) {
      log.error('Failed to query categories: error=' + String(err));
      return failure(ERROR_DB_OPERATION, -1, '查询分类失败');
    }
  }

  async saveCategory(category: NoteCategory): Promise<Result<boolean>> {
    try {
      const store = this.getStore();
      // 只传 categories 表实际存在的列，避免 NoteBucketData 多余字段导致 insert 失败
      const bucket: relationalStore.ValuesBucket = {
        'id': category.id,
        'name': category.name,
        'color': category.color,
        'icon_name': category.iconName,
        'created_at': category.createdAt,
        'sort_order': category.order
      };

      await store.insert(DB_TABLE_CATEGORIES, bucket);
      return success(true);
    } catch (err) {
      const msg = '保存分类失败: ' + category.name;
      log.error('Failed to save category: error=' + String(err) + ', name=' + category.name);
      return failure(ERROR_DB_OPERATION, -1, msg);
    }
  }

  async deleteCategory(name: string): Promise<Result<boolean>> {
    try {
      const store = this.getStore();
      const predicates = new relationalStore.RdbPredicates(DB_TABLE_CATEGORIES);
      predicates.equalTo('name', name);
      await store.delete(predicates);
      return success(true);
    } catch (err) {
      const msg = '删除分类失败: ' + name;
      log.error('Failed to delete category: error=' + String(err) + ', name=' + name);
      return failure(ERROR_DB_OPERATION, -1, msg);
    }
  }

  private rowToNote(rs: relationalStore.ResultSet): Note {
    const note = new Note();
    note.id = rs.getString(rs.getColumnIndex('id'));
    note.title = rs.getString(rs.getColumnIndex('title'));
    note.content = rs.getString(rs.getColumnIndex('content'));
    note.preview = rs.getString(rs.getColumnIndex('preview'));
    note.category = new NoteCategory(
      rs.getString(rs.getColumnIndex('category_name')),
      rs.getString(rs.getColumnIndex('category_id')),
      rs.getString(rs.getColumnIndex('category_color')),
      rs.getString(rs.getColumnIndex('category_icon'))
    );
    note.createdAt = rs.getString(rs.getColumnIndex('created_at'));
    note.updatedAt = rs.getString(rs.getColumnIndex('updated_at'));
    note.aiSummary = rs.getString(rs.getColumnIndex('ai_summary'));
    note.hasAiSummary = rs.getLong(rs.getColumnIndex('has_ai_summary')) === 1;
    note.syncStatus = rs.getString(rs.getColumnIndex('sync_status')) as SyncStatus;
    note.isFavorite = rs.getLong(rs.getColumnIndex('is_favorite')) === 1;
    note.sourceDevice = rs.getString(rs.getColumnIndex('source_device'));
    note.version = rs.getLong(rs.getColumnIndex('version'));
    return note;
  }

  private rowToCategory(rs: relationalStore.ResultSet): NoteCategory {
    const category = new NoteCategory(
      rs.getString(rs.getColumnIndex('name')),
      rs.getString(rs.getColumnIndex('id')),
      rs.getString(rs.getColumnIndex('color')),
      rs.getString(rs.getColumnIndex('icon_name'))
    );
    category.createdAt = rs.getString(rs.getColumnIndex('created_at'));
    category.order = rs.getLong(rs.getColumnIndex('sort_order'));
    return category;
  }
}

type SyncStatus = 'synced' | 'pending' | 'conflict' | 'local_only';
