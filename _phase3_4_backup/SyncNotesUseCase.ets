import { Note } from '../../model/Note';
import { Result, success, failure } from '../../common/Result';
import { NoteRepository } from '../../data/repository/NoteRepository';
import { SyncService } from '../service/SyncService';
import { Logger, getLogger } from '../../common/Logger';

const TAG = 'SyncNotesUseCase';
const log: Logger = getLogger(TAG);

export interface SyncResult {
  pushed: number;
  pulled: number;
}

export class SyncNotesUseCase {
  private repository: NoteRepository;
  private syncService: SyncService;

  constructor(repository: NoteRepository, syncService: SyncService) {
    this.repository = repository;
    this.syncService = syncService;
  }

  async execute(): Promise<Result<SyncResult>> {
    log.info('Starting bidirectional sync...');

    try {
      const pushResult = await this.syncService.pushLocalNotes();
      if (pushResult.isFailure) {
        log.warn('Push failed, continuing with pull', { error: pushResult.error });
      }

      const pullResult = await this.syncService.pullRemoteNotes();
      if (pullResult.isFailure) {
        log.warn('Pull failed', { error: pullResult.error });
      }

      const pushed: number = pushResult.isSuccess ? pushResult.data.length : 0;
      const pulled: number = pullResult.isSuccess ? pullResult.data.length : 0;

      log.info('Sync completed', { pushed: pushed, pulled: pulled });
      const syncResult: SyncResult = { pushed: pushed, pulled: pulled };
      return success(syncResult);
    } catch (err) {
      log.error('Sync failed', { error: String(err) });
      return failure('sync_failed', -1, '同步失败');
    }
  }

  async pushOnly(): Promise<Result<number>> {
    const result = await this.syncService.pushLocalNotes();
    if (result.isSuccess) {
      return success(result.data.length);
    }
    return failure(result.error, result.code, result.message);
  }

  async pullOnly(): Promise<Result<Note[]>> {
    return await this.syncService.pullRemoteNotes();
  }

  startListening(onChange: (notes: Note[]) => void): void {
    this.syncService.startSyncEventListener((note: Note) => {
      const arr: Note[] = [note];
      onChange(arr);
    });
  }

  stopListening(): void {
    this.syncService.stopSyncEventListener();
  }
}
