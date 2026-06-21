import { Result, failure } from '../../common/Result';
import { NoteRepository } from '../../data/repository/NoteRepository';
import { Logger, getLogger } from '../../common/Logger';
import { ERROR_NOTE_NOT_FOUND } from '../../common/Constants';

const TAG = 'DeleteNoteUseCase';
const log: Logger = getLogger(TAG);

export class DeleteNoteUseCase {
  private repository: NoteRepository;

  constructor(repository: NoteRepository) {
    this.repository = repository;
  }

  async execute(id: string): Promise<Result<boolean>> {
    const noteResult = await this.repository.getNoteById(id);

    if (noteResult.isFailure) {
      return failure(noteResult.error, noteResult.code, noteResult.message);
    }

    if (noteResult.data === null) {
      log.warn('Cannot delete non-existent note: id=' + id);
      return failure(ERROR_NOTE_NOT_FOUND, 404, '笔记不存在: ' + id);
    }

    return await this.repository.deleteNote(id);
  }
}
