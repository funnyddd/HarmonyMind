import { Note } from '../../model/Note';
import { Result, success } from '../../common/Result';
import { NoteRepository } from '../../data/repository/NoteRepository';
import { Logger, getLogger } from '../../common/Logger';

const TAG = 'SearchNotesUseCase';
const log: Logger = getLogger(TAG);

export class SearchNotesUseCase {
  private repository: NoteRepository;

  constructor(repository: NoteRepository) {
    this.repository = repository;
  }

  async execute(keyword: string): Promise<Result<Note[]>> {
    if (!keyword || keyword.trim().length === 0) {
      return success([]);
    }

    log.info('Searching notes: keyword=' + keyword.trim());
    return await this.repository.searchNotes(keyword.trim());
  }
}
