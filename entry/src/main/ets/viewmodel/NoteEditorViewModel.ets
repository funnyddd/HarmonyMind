import { Note } from '../model/Note';
import { NoteCategory } from '../model/NoteCategory';
import { Result } from '../common/Result';
import { ServiceFactory } from '../domain/factory/ServiceFactory';

/**
 * 全局草稿：存放新建笔记的初始分类名
 * 不用 AppStorage / router params，避免框架状态管理问题
 */
export class NoteDraft {
  static initialCategory: string = '';
}

@Observed
export class NoteEditorViewModel {
  note: Note;
  private originalNote: Note;
  isNew: boolean = true;
  isDirty: boolean = false;
  isSaving: boolean = false;
  errorMessage: string = '';
  categories: NoteCategory[] = [];

  private factory: ServiceFactory = ServiceFactory.getInstance();

  constructor(note?: Note) {
    if (note) {
      this.note = note.clone();
      this.originalNote = note.clone();
      this.isNew = false;
    } else {
      this.note = new Note();
      // 从全局草稿读取初始分类
      if (NoteDraft.initialCategory.length > 0) {
        this.note.category = new NoteCategory(NoteDraft.initialCategory);
        NoteDraft.initialCategory = '';
      }
      this.originalNote = this.note.clone();
      this.isNew = true;
    }
  }

  async loadNote(noteId: string): Promise<void> {
    this.isNew = false;
    try {
      const useCase = this.factory.getGetNotesUseCase();
      const result = await useCase.getById(noteId);

      if (result.isSuccess && result.data !== null) {
        this.note = result.data;
        this.originalNote = result.data.clone();
        this.isDirty = false;
      } else {
        this.errorMessage = '笔记不存在';
      }
    } catch (err) {
      this.errorMessage = '加载笔记失败';
    }
  }

  async loadCategories(): Promise<void> {
    try {
      const repo = this.factory.getNoteRepository();
      const result = await repo.getAllCategories();
      if (result.isSuccess && result.data !== null) {
        this.categories = result.data;
      }
    } catch (err) {
      // silent
    }
  }

  updateTitle(title: string): void {
    this.note.title = title;
    this.checkDirty();
  }

  updateContent(content: string): void {
    this.note.content = content;
    this.note.updatePreview();
    this.checkDirty();
  }

  setCategory(categoryName: string): void {
    this.note.category = new NoteCategory(categoryName);
    this.checkDirty();
  }

  getCategoryName(): string {
    return this.note.category?.name || '其他';
  }

  async save(): Promise<boolean> {
    if (!this.isDirty) {
      return true;
    }
    this.isSaving = true;
    this.errorMessage = '';

    try {
      let result: Result<Note>;

      if (this.isNew) {
        const useCase = this.factory.getCreateNoteUseCase();
        result = await useCase.execute(this.note.title, this.note.content, this.note.category);
      } else {
        const repo = this.factory.getNoteRepository();
        result = await repo.updateNote(this.note);
      }

      if (result.isSuccess && result.data !== null) {
        if (this.isNew) {
          this.note = result.data;
          this.isNew = false;
        }
        this.originalNote = this.note.clone();
        this.isDirty = false;
        return true;
      } else {
        this.errorMessage = result.message;
        return false;
      }
    } catch (err) {
      this.errorMessage = '保存时发生未知错误';
      return false;
    } finally {
      this.isSaving = false;
    }
  }

  private checkDirty(): void {
    this.isDirty =
      this.note.title !== this.originalNote.title ||
      this.note.content !== this.originalNote.content ||
      this.note.category?.name !== this.originalNote.category?.name;
  }
}
