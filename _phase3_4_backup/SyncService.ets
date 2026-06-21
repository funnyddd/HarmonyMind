import { Note } from '../../model/Note';
import { Result, success, failure } from '../../common/Result';
import { NoteRepository } from '../../data/repository/NoteRepository';
import { DistributedNoteDataSource } from '../../data/datasource/distributed/DistributedNoteDataSource';
import { Logger, getLogger } from '../../common/Logger';
import { ERROR_SYNC_FAILED } from '../../common/Constants';

const TAG = 'SyncService';
const log: Logger = getLogger(TAG);

/**
 * SyncService — 分布式同步服务
 * 编排本地 ↔ 分布式之间的双向数据同步逻辑
 */
export class SyncService {
  private repository: NoteRepository;
  private distributedDS: DistributedNoteDataSource;
  private syncListener: ((note: Note) => void) | null = null;
  private kvChangeListener: ((key: string, value: string | null) => void) | null = null;

  constructor(repository: NoteRepository) {
    this.repository = repository;
    this.distributedDS = new DistributedNoteDataSource();
  }

  /**
   * 推送本地笔记到分布式存储
   * 标记为 'pending' 的本地笔记将被推送并标记为 'synced'
   */
  async pushLocalNotes(): Promise<Result<Note[]>> {
    log.info('Pushing local notes to distributed store...');

    try {
      // 获取所有笔记，筛选待同步的
      const notesResult = await this.repository.getAllNotes();
      if (notesResult.isFailure) {
        return failure(notesResult.error, notesResult.code, notesResult.message);
      }

      const pendingNotes = notesResult.data.filter(
        n => n.syncStatus === 'pending' || n.syncStatus === 'local_only'
      );

      if (pendingNotes.length === 0) {
        log.info('No pending notes to push');
        return success([]);
      }

      // 逐条推送到分布式 KVStore
      const syncedNotes: Note[] = [];
      for (const note of pendingNotes) {
        const pushResult = await this.distributedDS.saveNote(note);
        if (pushResult.isSuccess) {
          await this.repository.updateSyncStatus(note.id, 'synced');
          note.syncStatus = 'synced';
          syncedNotes.push(note);
        } else {
          log.error('Failed to push note', { id: note.id });
        }
      }

      log.info('Pushed ' + syncedNotes.length + '/' + pendingNotes.length + ' notes');
      return success(syncedNotes);
    } catch (err) {
      log.error('Push local notes failed', err);
      return failure(ERROR_SYNC_FAILED, err as number, '推送本地笔记失败');
    }
  }

  /**
   * 拉取分布式存储中的远程笔记到本地
   * 冲突解决：以 updatedAt 较新者为准
   */
  async pullRemoteNotes(): Promise<Result<Note[]>> {
    log.info('Pulling remote notes from distributed store...');

    try {
      const remoteResult = await this.distributedDS.getAllNotes();
      if (remoteResult.isFailure) {
        return failure(remoteResult.error, remoteResult.code, remoteResult.message);
      }

      const remoteNotes = remoteResult.data;
      if (remoteNotes.length === 0) {
        log.info('No remote notes to pull');
        return success([]);
      }

      // 冲突解决：对比本地版本
      const toSave: Note[] = [];

      for (const remoteNote of remoteNotes) {
        const localResult = await this.repository.getNoteById(remoteNote.id);

        if (localResult.isFailure || !localResult.data) {
          // 本地不存在 → 直接保存
          remoteNote.syncStatus = 'synced';
          toSave.push(remoteNote);
          continue;
        }

        const localNote = localResult.data;

        // 冲突解决: 时间戳较新者为准
        if (remoteNote.updatedAt > localNote.updatedAt || remoteNote.version > localNote.version) {
          remoteNote.syncStatus = 'synced';
          toSave.push(remoteNote);
        }
        // 否则保留本地版本
      }

      if (toSave.length > 0) {
        const saveResult = await this.repository.saveNotes(toSave);
        if (saveResult.isFailure) {
          return failure(saveResult.error, saveResult.code, saveResult.message);
        }
      }

      log.info('Pulled ' + toSave.length + '/' + remoteNotes.length + ' remote notes');
      return success(toSave);
    } catch (err) {
      log.error('Pull remote notes failed', err);
      return failure(ERROR_SYNC_FAILED, err as number, '拉取远程笔记失败');
    }
  }

  /**
   * 开始监听分布式数据变化
   */
  startSyncEventListener(onNoteChanged: (note: Note) => void): void {
    if (this.kvChangeListener) {
      return; // 已经监听
    }

    this.syncListener = onNoteChanged;

    this.kvChangeListener = async (key: string, value: string | null) => {
      log.debug('Remote KV change detected', { key });

      if (value) {
        try {
          const data = JSON.parse(value) as Object;
          const idStr = data['id'] as string;
          const titleStr = data['title'] as string;
          const contentStr = data['content'] as string;
          const note = new Note(
            idStr || '',
            titleStr || '',
            contentStr || ''
          );
          note.updatedAt = (data['updated_at'] as string) || note.updatedAt;
          note.version = (data['version'] as number) || note.version;
          note.syncStatus = 'synced';

          // 保存到本地
          await this.repository.saveNotes([note]);

          // 通知外部
          if (this.syncListener) {
            this.syncListener(note);
          }
        } catch (err) {
          log.error('Error processing remote KV change', err, { key });
        }
      }
    };

    this.distributedDS.addChangeListener(this.kvChangeListener);
    log.info('Sync event listener started');
  }

  /**
   * 停止监听
   */
  stopSyncEventListener(): void {
    if (this.kvChangeListener) {
      this.distributedDS.removeChangeListener(this.kvChangeListener);
      this.kvChangeListener = null;
      this.syncListener = null;
      log.info('Sync event listener stopped');
    }
  }
}
