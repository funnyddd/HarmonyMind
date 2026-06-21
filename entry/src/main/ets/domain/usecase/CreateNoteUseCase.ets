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

  async execute(title: string, content: string, category?: NoteCategory): Promise<Result<Note>> {
    const trimmedTitle = (title || '').trim();
    const trimmedContent = (content || '').trim();

    if (!trimmedContent) {
      const defaultTitle = trimmedTitle || `无标题笔记 ${new Date().toLocaleDateString()}`;
      return await this.repository.createNote(defaultTitle, '');
    }

    const finalTitle = trimmedTitle || this.generateDefaultTitle(trimmedContent);
    return await this.repository.createNote(finalTitle, trimmedContent, category);
  }

  private generateDefaultTitle(content: string): string {
    const firstLine = content.split(/[\n\r]+/)[0];
    return firstLine.length > 30 ? firstLine.substring(0, 30) + '...' : firstLine;
  }
}
