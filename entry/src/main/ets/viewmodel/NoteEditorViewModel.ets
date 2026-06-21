import { Note } from '../model/Note';
import { NoteCategory } from '../model/NoteCategory';
import { Result } from '../common/Result';
import { ServiceFactory } from '../domain/factory/ServiceFactory';

@Observed
export class NoteEditorViewModel {
  note: Note;
  private originalNote: Note;
  isNew: boolean = true;
  isDirty: boolean = false;
  isSaving: boolean = false;
  errorMessage: string = '';
  /** 初始分类名，保存时确保不丢失 */
  private pendingCategoryName: string = '';

  private factory: ServiceFactory = ServiceFactory.getInstance();

  constructor(note?: Note, initialCategoryName?: string) {
    if (note) {
      this.note = note.clone();
      this.originalNote = note.clone();
      this.isNew = false;
    } else {
      this.note = new Note();
      // 构造时直接设分类，不依赖事后调用
      if (initialCategoryName && initialCategoryName.length > 0) {
        this.pendingCategoryName = initialCategoryName;
        const cat = new NoteCategory(initialCategoryName);
        this.note.category = cat;
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

  updateTitle(title: string): void {
    this.note.title = title;
    this.checkDirty();
  }

  updateContent(content: string): void {
    this.note.content = content;
    this.note.updatePreview();
    this.checkDirty();
  }

  updateCategory(category: NoteCategory): void {
    this.note.category = category;
    this.checkDirty();
  }

  async save(): Promise<boolean> {
    // 防御：保存前确认分类名称没有被覆盖
    if (this.isNew && this.pendingCategoryName.length > 0 &&
        this.note.category?.name !== this.pendingCategoryName) {
      this.note.category = new NoteCategory(this.pendingCategoryName);
    }

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
