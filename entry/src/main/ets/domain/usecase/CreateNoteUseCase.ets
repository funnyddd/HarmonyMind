import { Note } from '../../model/Note';
import { NoteCategory } from '../../model/NoteCategory';
import { Result } from '../../common/Result';
import { NoteRepository } from '../../data/repository/NoteRepository';
import { Logger, getLogger } from '../../common/Logger';

const TAG = 'CreateNoteUseCase';
const log: Logger = getLogger(TAG);

export class CreateNoteUseCase {
  private repository: NoteRepository;

  constructor(repository: NoteRepository) {
    this.repository = repository;
  }

  async execute(title: string, content: string, categoryName: string): Promise<Result<Note>> {
    const finalTitle = (title || '').trim() || this.generateDefaultTitle(content);
    const finalContent = (content || '').trim();
    return await this.repository.createNote(finalTitle, finalContent, categoryName);
  }

  private generateDefaultTitle(content: string): string {
    const firstLine = content.split(/[\n\r]+/)[0];
    return firstLine.length > 30 ? firstLine.substring(0, 30) + '...' : firstLine;
  }
}
