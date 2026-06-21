import { NoteCategory } from './NoteCategory';

/**
 * Note — 笔记核心数据模型
 */
@Observed
export class Note {
  /** 笔记唯一标识 (UUID) */
  id: string;
  /** 笔记标题 */
  title: string;
  /** 笔记正文内容 */
  content: string;
  /** 内容预览（列表展示用） */
  preview: string;
  /** 分类对象 */
  category: NoteCategory;
  /** 创建时间 (ISO 8601 格式字符串) */
  createdAt: string;
  /** 最后更新时间 (ISO 8601 格式字符串) */
  updatedAt: string;
  /** AI 生成的摘要文本 */
  aiSummary: string;
  /** 是否有 AI 摘要 */
  hasAiSummary: boolean;
  /** 同步状态: 'synced' | 'pending' | 'conflict' | 'local_only' */
  syncStatus: SyncStatus;
  /** 是否被标记为收藏 */
  isFavorite: boolean;
  /** 来源设备名称 */
  sourceDevice: string;
  /** 乐观锁版本号 (用于冲突检测) */
  version: number;

  constructor(
    id: string = '',
    title: string = '',
    content: string = '',
    category: NoteCategory = new NoteCategory('其他'),
    createdAt: string = new Date().toISOString(),
    updatedAt: string = new Date().toISOString()
  ) {
    this.id = id;
    this.title = title;
    this.content = content;
    this.preview = content.length > 100 ? content.substring(0, 100) + '...' : content;
    this.category = category;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.aiSummary = '';
    this.hasAiSummary = false;
    this.syncStatus = 'local_only';
    this.isFavorite = false;
    this.sourceDevice = '';
    this.version = 1;
  }

  /**
   * 更新预览文本
   */
  updatePreview(): void {
    if (this.content && this.content.length > 100) {
      this.preview = this.content.substring(0, 100) + '...';
    } else {
      this.preview = this.content || '';
    }
  }

  /**
   * 生成用于分布式存储的 KV 键
   */
  getKvKey(): string {
    return `note_${this.id}`;
  }

  /**
   * 深拷贝
   */
  clone(): Note {
    const cloned = new Note(
      this.id,
      this.title,
      this.content,
      this.category ? this.category.clone() : new NoteCategory('其他'),
      this.createdAt,
      this.updatedAt
    );
    cloned.preview = this.preview;
    cloned.aiSummary = this.aiSummary;
    cloned.hasAiSummary = this.hasAiSummary;
    cloned.syncStatus = this.syncStatus;
    cloned.isFavorite = this.isFavorite;
    cloned.sourceDevice = this.sourceDevice;
    cloned.version = this.version;
    return cloned;
  }
}

/** 同步状态枚举 */
export type SyncStatus = 'synced' | 'pending' | 'conflict' | 'local_only';

/** 屏幕断点 */
export enum Breakpoint {
  SM = 'sm',   // 手机竖屏 (320-600)
  MD = 'md',   // 手机横屏 / 小平板 (600-840)
  LG = 'lg',   // 平板 / 2in1 (840+) — Continuation 目标设备
}
