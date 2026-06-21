import distributedKVStore from '@ohos.data.distributedKVStore';
import { Logger, getLogger } from '../../../common/Logger';
import {
  DISTRIBUTED_STORE_ID,
  DISTRIBUTED_BUNDLE_NAME,
  ERROR_SYNC_FAILED
} from '../../../common/Constants';

const TAG = 'DistributedKVManager';
const log: Logger = getLogger(TAG);

/**
 * Local interface for KVStore sync constraint entries.
 * Replaces distributedKVStore.KVStoreDataSyncConstraint which may not exist in SDK 6.1.1.
 */
interface SyncConstraintEntry {
  prefix: string;
  isSynced: boolean;
}

/**
 * Local interface for device info entries returned by getAllKVStoreId.
 * Replaces distributedKVStore.DeviceInfo which may not exist in SDK 6.1.1.
 */
interface DeviceInfoEntry {
  deviceId: string;
  deviceName: string;
}

/**
 * DistributedKVManager — 分布式 KVStore 单例管理器 (Promise 模式)
 *
 * 使用单例 Promise 模式避免回调时序 bug:
 * - 首次调用时初始化，后续复用同一个 store 实例
 * - 支持 autoSync 自动同步
 * - 提供 onChange 监听跨设备数据变化
 */
export class DistributedKVManager {
  private static instance: DistributedKVManager | null = null;
  private kvManager: distributedKVStore.KVManager | null = null;
  private kvStore: distributedKVStore.SingleKVStore | null = null;
  private isReady: boolean = false;
  private initPromise: Promise<void> | null = null;
  private changeListeners: Set<(key: string, value: string | null) => void> = new Set();

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): DistributedKVManager {
    if (!DistributedKVManager.instance) {
      DistributedKVManager.instance = new DistributedKVManager();
    }
    return DistributedKVManager.instance;
  }

  /**
   * 初始化 KVStore (幂等 — 多次调用只会初始化一次)
   * @param context 应用上下文
   * @returns 初始化完成的 Promise
   */
  async initialize(context: Context): Promise<void> {
    // 已有初始化进行中，复用同一 Promise
    if (this.initPromise) {
      return this.initPromise;
    }

    // 已就绪，直接返回
    if (this.isReady) {
      return;
    }

    this.initPromise = this.doInitialize(context);

    try {
      await this.initPromise;
    } finally {
      this.initPromise = null;
    }
  }

  /**
   * 实际初始化逻辑
   */
  private async doInitialize(context: Context): Promise<void> {
    log.info('Starting distributed KVStore initialization...');

    try {
      // 1. 创建 KVManager
      const kvManagerConfig: distributedKVStore.KVManagerConfig = {
        context: context,
        bundleName: DISTRIBUTED_BUNDLE_NAME
      };
      this.kvManager = distributedKVStore.createKVManager(kvManagerConfig);
      log.info('KVManager created');

      // 2. 创建 SingleKVStore (autoSync 开启)
      const options: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: false,
        backup: false,
        autoSync: true,   // ★ 启用自动同步
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(
        DISTRIBUTED_STORE_ID,
        options
      );
      log.info('KVStore created with autoSync enabled');

      // 3. 注册数据变化监听
      this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL,
        (data: distributedKVStore.ChangeNotification) => {
          this.onDataChange(data);
        }
      );

      this.isReady = true;
      log.info('Distributed KVStore initialized successfully');
    } catch (err) {
      log.error('Failed to initialize distributed KVStore', err);
      this.kvManager = null;
      this.kvStore = null;
      this.isReady = false;
      throw new Error(String(err));
    }
  }

  /**
   * 数据变化回调处理
   */
  private onDataChange(data: distributedKVStore.ChangeNotification): void {
    if (!data || !data.insertEntries) {
      return;
    }

    for (const entry of data.insertEntries) {
      try {
        const key: string = entry.key;
        const value: string | null = entry.value ? entry.value.value?.toString() : null;
        log.debug('Remote data change: key=' + key + ', valueLength=' + (value ? value.length : 0));

        // 通知所有监听者
        this.changeListeners.forEach(listener => {
          try {
            listener(key, value);
          } catch (err) {
            log.error('Change listener error: key=' + key, err);
          }
        });
      } catch (err) {
        log.error('Error processing data change entry', err);
      }
    }
  }

  /**
   * 注册变化监听器
   */
  addChangeListener(listener: (key: string, value: string | null) => void): void {
    this.changeListeners.add(listener);
    log.debug('Change listener added, total: ' + this.changeListeners.size);
  }

  /**
   * 移除变化监听器
   */
  removeChangeListener(listener: (key: string, value: string | null) => void): void {
    this.changeListeners.delete(listener);
    log.debug('Change listener removed, total: ' + this.changeListeners.size);
  }

  /**
   * 存储字符串值
   */
  async putString(key: string, value: string): Promise<boolean> {
    await this.ensureReady();

    try {
      await this.kvStore!.put(key, value);
      log.debug('KVStore put string: key=' + key + ', length=' + value.length);
      return true;
    } catch (err) {
      log.error('KVStore put string failed: key=' + key, err);
      return false;
    }
  }

  /**
   * 获取字符串值
   */
  async getString(key: string): Promise<string | null> {
    await this.ensureReady();

    try {
      const value: Object | undefined | null = await this.kvStore!.get(key);
      if (value === undefined || value === null) {
        return null;
      }
      return value.toString();
    } catch (err) {
      log.error('KVStore get string failed: key=' + key, err);
      return null;
    }
  }

  /**
   * 删除键值对
   */
  async delete(key: string): Promise<boolean> {
    await this.ensureReady();

    try {
      await this.kvStore!.delete(key);
      log.debug('KVStore delete: key=' + key);
      return true;
    } catch (err) {
      log.error('KVStore delete failed: key=' + key, err);
      return false;
    }
  }

  /**
   * 批量获取所有匹配前缀的键值对
   */
  async getByPrefix(prefix: string): Promise<Map<string, string>> {
    await this.ensureReady();

    const result = new Map<string, string>();

    try {
      const entries = await this.kvStore!.getEntries(prefix);
      if (entries && entries.length > 0) {
        for (const entry of entries) {
          const key: string = entry.key;
          const value: string = entry.value?.value?.toString() || '';
          result.set(key, value);
        }
      }
      log.debug('KVStore getByPrefix "' + prefix + '": count=' + result.size);
    } catch (err) {
      log.error('KVStore getByPrefix failed: prefix=' + prefix, err);
    }

    return result;
  }

  /**
   * 删除匹配前缀的所有条目
   */
  async deleteByPrefix(prefix: string): Promise<number> {
    await this.ensureReady();

    let count: number = 0;

    try {
      const entries = await this.kvStore!.getEntries(prefix);
      if (entries && entries.length > 0) {
        for (const entry of entries) {
          await this.kvStore!.delete(entry.key);
          count++;
        }
      }
      log.debug('KVStore deleted ' + count + ' entries by prefix "' + prefix + '"');
    } catch (err) {
      log.error('KVStore deleteByPrefix failed: prefix=' + prefix, err);
    }

    return count;
  }

  /**
   * 同步指定数据范围的配置
   * 注意：enableSyncDataConstraint / KVStoreDataSyncConstraint 在当前SDK中不可用
   * 同步功能已通过 autoSync 配置启用
   */
  async enableSyncForPrefixes(prefixes: string[]): Promise<void> {
    await this.ensureReady();

    try {
      // enableSyncDataConstraint API 在当前 SDK 版本中不可用
      // 同步功能已通过 autoSync 配置启用
      log.info('Sync auto-enabled for ' + prefixes.length + ' prefixes via autoSync config');
    } catch (err) {
      log.error('Failed to enable sync constraints', err);
    }
  }

  /**
   * 获取设备同步状态列表
   */
  async getDeviceList(): Promise<DeviceInfoEntry[]> {
    await this.ensureReady();

    try {
      const devices = await this.kvManager!.getAllKVStoreId({
        bundleName: DISTRIBUTED_BUNDLE_NAME,
        storeId: DISTRIBUTED_STORE_ID
      });
      return devices || [];
    } catch (err) {
      log.error('Failed to get device list', err);
      return [];
    }
  }

  /**
   * 确保 KVStore 已初始化
   */
  private async ensureReady(): Promise<void> {
    if (!this.isReady) {
      throw new Error('DistributedKVManager not initialized. Call initialize() first.');
    }
  }

  /**
   * 是否已就绪
   */
  get ready(): boolean {
    return this.isReady;
  }

  /**
   * 关闭并释放资源
   */
  async close(): Promise<void> {
    try {
      this.changeListeners.clear();

      if (this.kvStore) {
        this.kvStore.off('dataChange');
        await this.kvManager?.closeKVStore(DISTRIBUTED_STORE_ID);
        this.kvStore = null;
        log.info('KVStore closed');
      }

      if (this.kvManager) {
        // deleteKVManager does not exist in SDK 6.1.1 — skip cleanup, just null the reference
        this.kvManager = null;
        log.info('KVManager reference released');
      }

      this.isReady = false;
      DistributedKVManager.instance = null;
    } catch (err) {
      log.error('Error closing distributed KVStore', err);
    }
  }
}
