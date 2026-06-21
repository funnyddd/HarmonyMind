/**
 * NoteCategory — 笔记分类数据模型
 */
@Observed
export class NoteCategory {
  /** 分类唯一标识 */
  id: string;
  /** 分类名称 */
  name: string;
  /** 分类颜色 (十六进制值，如 '#FF6B6B') */
  color: string;
  /** 分类图标名 */
  iconName: string;
  /** 创建时间 */
  createdAt: string;
  /** 排序权重 (0-100，越大越靠前) */
  order: number;
  /** 该分类下的笔记数量 (运行时计算) */
  noteCount: number;

  constructor(
    name: string = '其他',
    id: string = '',
    color: string = '#8E8E93',
    iconName: string = 'file',
    order: number = 0
  ) {
    this.id = id || `${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
    this.name = name;
    this.color = color;
    this.iconName = iconName;
    this.createdAt = new Date().toISOString();
    this.order = order;
    this.noteCount = 0;
  }

  clone(): NoteCategory {
    const cloned = new NoteCategory(
      this.name,
      this.id,
      this.color,
      this.iconName,
      this.order
    );
    cloned.createdAt = this.createdAt;
    cloned.noteCount = this.noteCount;
    return cloned;
  }

  /**
   * 获取带 # 前缀的显示标签
   */
  getDisplayLabel(): string {
    return `#${this.name}`;
  }
}

/**
 * 预定义默认分类配色
 */
export const CATEGORY_COLORS: Record<string, string> = {
  '工作': '#FF6B6B',
  '学习': '#4ECDC4',
  '生活': '#45B7D1',
  '灵感': '#F7DC6F',
  '会议': '#9B59B6',
  '读书': '#2ECC71',
  '旅行': '#E67E22',
  '其他': '#8E8E93'
};

/**
 * 预定义默认分类图标
 */
export const CATEGORY_ICONS: Record<string, string> = {
  '工作': 'briefcase',
  '学习': 'book',
  '生活': 'home',
  '灵感': 'lightbulb',
  '会议': 'people',
  '读书': 'book_open',
  '旅行': 'plane',
  '其他': 'file'
};
