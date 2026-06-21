/**
 * Constants — 应用全局常量
 */

/** 数据库配置 */
export const DB_NAME = 'HarmonyMind.db';
export const DB_TABLE_NOTES = 'notes';
export const DB_TABLE_CATEGORIES = 'categories';

/** 分布式数据同步 */
export const DISTRIBUTED_STORE_ID = 'HarmonyMind_KVStore';
export const DISTRIBUTED_BUNDLE_NAME = 'com.harmonymind.noteapp';

/** AI 服务配置 */
export const AI_CLOUD_API_URL = 'https://api.harmonymind.ai/v1';
export const AI_REQUEST_TIMEOUT_MS = 30000;
export const AI_MAX_SUMMARY_LENGTH = 200;
export const AI_DEFAULT_CATEGORIES: string[] = [
  '工作',
  '学习',
  '生活',
  '灵感',
  '会议',
  '读书',
  '旅行',
  '其他'
];

/** 页面路由 */
export const ROUTE_NOTE_LIST = 'pages/NoteListPage';
export const ROUTE_NOTE_EDITOR = 'pages/NoteEditorPage';
export const ROUTE_SEARCH = 'pages/SearchPage';
export const ROUTE_DEVICE_SYNC = 'pages/DeviceSyncPage';
export const ROUTE_SETTINGS = 'pages/SettingsPage';

/** 页面参数 */
export const PARAM_NOTE_ID = 'noteId';
export const PARAM_CATEGORY = 'category';

/** KVStore 键前缀 */
export const KV_KEY_NOTE_PREFIX = 'note_';
export const KV_KEY_SYNC_STATUS = 'sync_status';

/** 存储键 */
export const SETTINGS_KEY_DARK_MODE = 'dark_mode';
export const SETTINGS_KEY_AI_PROVIDER = 'ai_provider';
export const SETTINGS_KEY_AUTO_SYNC = 'auto_sync';
export const SETTINGS_KEY_DEFAULT_CATEGORY = 'default_category';

/** 错误消息 */
export const ERROR_NOTE_NOT_FOUND = '笔记不存在';
export const ERROR_DB_OPERATION = '数据库操作失败';
export const ERROR_SYNC_FAILED = '分布式同步失败';
export const ERROR_AI_SERVICE = 'AI 服务不可用';
export const ERROR_VOICE_RECORDING = '录音失败';
export const ERROR_NETWORK = '网络连接失败';
export const ERROR_PERMISSION_DENIED = '权限被拒绝';
