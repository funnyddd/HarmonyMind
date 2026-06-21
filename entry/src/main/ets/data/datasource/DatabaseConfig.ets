import relationalStore from '@ohos.data.relationalStore';
import { Logger, getLogger } from '../../common/Logger';
import { DB_NAME, DB_TABLE_NOTES, DB_TABLE_CATEGORIES } from '../../common/Constants';

const TAG = 'DatabaseConfig';
const log: Logger = getLogger(TAG);

/**
 * DatabaseConfig — RelationalStore 数据库配置
 * 定义表结构、索引、升级策略
 */
export class DatabaseConfig {
  private static store: relationalStore.RdbStore | null = null;

  /** 数据库表 SQL 定义 */
  static readonly SQL_CREATE_TABLE_NOTES: string = `
    CREATE TABLE IF NOT EXISTS ${DB_TABLE_NOTES} (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL DEFAULT '',
      content TEXT NOT NULL DEFAULT '',
      preview TEXT NOT NULL DEFAULT '',
      category_id TEXT,
      category_name TEXT NOT NULL DEFAULT '其他',
      category_color TEXT NOT NULL DEFAULT '#8E8E93',
      category_icon TEXT NOT NULL DEFAULT 'file',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      ai_summary TEXT NOT NULL DEFAULT '',
      has_ai_summary INTEGER NOT NULL DEFAULT 0,
      sync_status TEXT NOT NULL DEFAULT 'local_only',
      is_favorite INTEGER NOT NULL DEFAULT 0,
      source_device TEXT NOT NULL DEFAULT '',
      version INTEGER NOT NULL DEFAULT 1
    )
  `;

  static readonly SQL_CREATE_TABLE_CATEGORIES: string = `
    CREATE TABLE IF NOT EXISTS ${DB_TABLE_CATEGORIES} (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      color TEXT NOT NULL DEFAULT '#8E8E93',
      icon_name TEXT NOT NULL DEFAULT 'file',
      created_at TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0
    )
  `;

  static readonly SQL_CREATE_INDEX_UPDATED: string = `
    CREATE INDEX IF NOT EXISTS idx_notes_updated_at
    ON ${DB_TABLE_NOTES}(updated_at DESC)
  `;

  static readonly SQL_CREATE_INDEX_CATEGORY: string = `
    CREATE INDEX IF NOT EXISTS idx_notes_category
    ON ${DB_TABLE_NOTES}(category_name)
  `;

  static readonly SQL_CREATE_INDEX_SYNC: string = `
    CREATE INDEX IF NOT EXISTS idx_notes_sync_status
    ON ${DB_TABLE_NOTES}(sync_status)
  `;

  /** RelationalStore 配置 */
  static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: DB_NAME,
    securityLevel: relationalStore.SecurityLevel.S1
  };

  /**
   * 获取数据库实例 (单例)
   */
  static getStore(): relationalStore.RdbStore | null {
    return DatabaseConfig.store;
  }

  /**
   * 设置数据库实例
   */
  static setStore(store: relationalStore.RdbStore): void {
    DatabaseConfig.store = store;
  }

  /**
   * 初始化数据库
   */
  static async initialize(context: Context): Promise<void> {
    log.info('Initializing database...');

    try {
      const store = await relationalStore.getRdbStore(
        context,
        DatabaseConfig.STORE_CONFIG
      );

      // 创建表结构
      await store.executeSql(DatabaseConfig.SQL_CREATE_TABLE_NOTES);
      await store.executeSql(DatabaseConfig.SQL_CREATE_TABLE_CATEGORIES);

      // 创建索引
      await store.executeSql(DatabaseConfig.SQL_CREATE_INDEX_UPDATED);
      await store.executeSql(DatabaseConfig.SQL_CREATE_INDEX_CATEGORY);
      await store.executeSql(DatabaseConfig.SQL_CREATE_INDEX_SYNC);

      DatabaseConfig.store = store;
      log.info('Database initialized successfully');
    } catch (err) {
      log.error('Failed to initialize database', err);
      throw new Error('Failed to initialize database: ' + err);
    }
  }

  /**
   * 关闭数据库
   */
  static async close(): Promise<void> {
    if (DatabaseConfig.store) {
      try {
        await DatabaseConfig.store.close();
        DatabaseConfig.store = null;
        log.info('Database closed');
      } catch (err) {
        log.error('Failed to close database', err);
      }
    }
  }
}
