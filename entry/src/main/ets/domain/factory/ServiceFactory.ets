import { NoteRepository } from '../../data/repository/NoteRepository';
import { CreateNoteUseCase } from '../usecase/CreateNoteUseCase';
import { GetNotesUseCase } from '../usecase/GetNotesUseCase';
import { DeleteNoteUseCase } from '../usecase/DeleteNoteUseCase';
import { SearchNotesUseCase } from '../usecase/SearchNotesUseCase';
import { Logger, getLogger } from '../../common/Logger';

const TAG = 'ServiceFactory';
const log: Logger = getLogger(TAG);

export class ServiceFactory {
  private static instance: ServiceFactory;

  private noteRepository: NoteRepository | null = null;
  private createNoteUseCase: CreateNoteUseCase | null = null;
  private getNotesUseCase: GetNotesUseCase | null = null;
  private deleteNoteUseCase: DeleteNoteUseCase | null = null;
  private searchNotesUseCase: SearchNotesUseCase | null = null;

  private constructor() {}

  static getInstance(): ServiceFactory {
    if (ServiceFactory.instance === null || ServiceFactory.instance === undefined) {
      ServiceFactory.instance = new ServiceFactory();
    }
    return ServiceFactory.instance;
  }

  getNoteRepository(): NoteRepository {
    if (this.noteRepository === null) {
      this.noteRepository = new NoteRepository();
    }
    return this.noteRepository;
  }

  getCreateNoteUseCase(): CreateNoteUseCase {
    if (this.createNoteUseCase === null) {
      this.createNoteUseCase = new CreateNoteUseCase(this.getNoteRepository());
    }
    return this.createNoteUseCase;
  }

  getGetNotesUseCase(): GetNotesUseCase {
    if (this.getNotesUseCase === null) {
      this.getNotesUseCase = new GetNotesUseCase(this.getNoteRepository());
    }
    return this.getNotesUseCase;
  }

  getDeleteNoteUseCase(): DeleteNoteUseCase {
    if (this.deleteNoteUseCase === null) {
      this.deleteNoteUseCase = new DeleteNoteUseCase(this.getNoteRepository());
    }
    return this.deleteNoteUseCase;
  }

  getSearchNotesUseCase(): SearchNotesUseCase {
    if (this.searchNotesUseCase === null) {
      this.searchNotesUseCase = new SearchNotesUseCase(this.getNoteRepository());
    }
    return this.searchNotesUseCase;
  }
}
