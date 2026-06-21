import { Note } from '../../model/Note';
import { NoteCategory } from '../../model/NoteCategory';
import { Result } from '../../common/Result';
import { NoteRepository } from '../../data/repository/NoteRepository';
import { Logger, getLogger } from '../../common/Logger';

const TAG = 'GetNotesUseCase';
const log: Logger = getLogger(TAG);

export class GetNotesUseCase {
  private repository: NoteRepository;

  constructor(repository: NoteRepository) {
    this.repository = repository;
  }

  async execute(category?: NoteCategory, limit: number = 100, offset: number = 0): Promise<Result<Note[]>> {
    if (category) {
      return await this.repository.getNotesByCategory(category.name);
    }
    return await this.repository.getAllNotes(limit, offset);
  }

  async getById(id: string): Promise<Result<Note | null>> {
    return await this.repository.getNoteById(id);
  }
}
