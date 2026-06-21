import { Note } from '../model/Note';
import { NoteCategory, CATEGORY_ICONS } from '../model/NoteCategory';
import { ServiceFactory } from '../domain/factory/ServiceFactory';

@Observed
export class NoteListViewModel {
  notes: Note[] = [];
  categories: NoteCategory[] = [];
  selectedCategory: NoteCategory | null = null;
  isLoading: boolean = false;
  isRefreshing: boolean = false;
  errorMessage: string = '';

  private factory: ServiceFactory = ServiceFactory.getInstance();

  async loadNotes(category?: NoteCategory): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      const useCase = this.factory.getGetNotesUseCase();
      const result = await useCase.execute(category);

      if (result.isSuccess && result.data !== null) {
        this.notes = result.data;
      } else if (result.isFailure) {
        this.errorMessage = result.message;
      }
    } catch (err) {
      this.errorMessage = '加载笔记时发生未知错误';
    } finally {
      this.isLoading = false;
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

  async filterByCategory(category: NoteCategory | null): Promise<void> {
    this.selectedCategory = category;
    await this.loadNotes(category || undefined);
  }

  async refresh(): Promise<void> {
    this.isRefreshing = true;
    await this.loadNotes(this.selectedCategory || undefined);
    this.isRefreshing = false;
  }

  async deleteNote(id: string): Promise<boolean> {
    const useCase = this.factory.getDeleteNoteUseCase();
    const result = await useCase.execute(id);

    if (result.isSuccess) {
      this.notes = this.notes.filter(n => n.id !== id);
      return true;
    } else {
      this.errorMessage = result.message;
      return false;
    }
  }

  async createCategory(name: string, color: string): Promise<boolean> {
    // 重名校验
    const exists = this.categories.some(c => c.name === name);
    if (exists) {
      this.errorMessage = '分类名已存在';
      return false;
    }

    const iconName = CATEGORY_ICONS[name] || 'file';
    const category = new NoteCategory(name, '', color, iconName, this.categories.length);

    try {
      const repo = this.factory.getNoteRepository();
      const result = await repo.saveCategory(category);

      if (result.isSuccess) {
        // 刷新分类列表
        await this.loadCategories();
        return true;
      } else {
        this.errorMessage = result.message;
        return false;
      }
    } catch (err) {
      this.errorMessage = '创建分类失败';
      return false;
    }
  }
}
