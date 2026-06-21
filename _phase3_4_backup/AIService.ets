import { Note } from '../../model/Note';
import { AISummaryResult } from '../../model/AISummaryResult';
import { Result, success, failure } from '../../common/Result';
import { CloudAIDataSource } from '../../data/datasource/ai/CloudAIDataSource';
import { OnDeviceAIDataSource } from '../../data/datasource/ai/OnDeviceAIDataSource';
import { Logger, getLogger } from '../../common/Logger';
import { ERROR_AI_SERVICE } from '../../common/Constants';

const TAG = 'AIService';
const log: Logger = getLogger(TAG);

/** AI 服务提供者类型 */
export type AIProvider = 'cloud' | 'on_device' | 'auto';

/**
 * AIService — AI 领域服务 (策略模式)
 *
 * 双路径策略: 端侧推理 (MindSpore Lite) / 云端 API (GPT/盘古)
 * - 'auto': 优先端侧，不可用时降级云端
 * - 'cloud': 强制使用云端 API
 * - 'on_device': 强制使用端侧模型
 */
export class AIService {
  private cloudSource: CloudAIDataSource;
  private onDeviceSource: OnDeviceAIDataSource;
  private provider: AIProvider = 'auto';
  private cloudAvailable: boolean = true;

  constructor() {
    this.cloudSource = new CloudAIDataSource();
    this.onDeviceSource = new OnDeviceAIDataSource();
  }

  /**
   * 设置 AI 提供者策略
   */
  setProvider(provider: AIProvider): void {
    this.provider = provider;
    log.info('AI provider set', { provider });
  }

  /**
   * 获取当前提供者
   */
  getProvider(): AIProvider {
    return this.provider;
  }

  /**
   * 设置云端 API Key
   */
  setCloudApiKey(key: string): void {
    this.cloudSource.setApiKey(key);
    this.cloudAvailable = !!key;
  }

  /**
   * 初始化服务
   */
  async initialize(): Promise<void> {
    // 预加载端侧模型
    const loaded = await this.onDeviceSource.loadModel();
    if (loaded) {
      log.info('On-device AI model loaded');
    } else {
      log.warn('On-device model not available, will use cloud fallback');
    }
  }

  /**
   * 生成笔记摘要
   */
  async summarize(note: Note): Promise<Result<AISummaryResult>> {
    if (this.provider === 'on_device') {
      return await this.summarizeOnDevice(note);
    }

    if (this.provider === 'cloud') {
      return await this.summarizeWithCloud(note);
    }

    // auto 模式：先端侧，失败降级云端
    const deviceResult = await this.summarizeOnDevice(note);
    if (deviceResult.isSuccess) {
      return deviceResult;
    }

    log.info('On-device summarize failed, falling back to cloud');
    return await this.summarizeWithCloud(note);
  }

  /**
   * 笔记分类
   */
  async categorize(note: Note): Promise<Result<{ category: string; confidence: number }>> {
    if (this.provider === 'on_device') {
      return await this.onDeviceSource.categorizeNote(note);
    }

    if (this.provider === 'cloud' && this.cloudAvailable) {
      const result = await this.cloudSource.categorizeNote(note);
      if (result.isSuccess) {
        return result;
      }
      log.warn('Cloud categorize failed, falling back to on-device');
    }

    // 降级到端侧规则引擎
    return await this.onDeviceSource.categorizeNote(note);
  }

  /**
   * 端侧摘要
   */
  private async summarizeOnDevice(note: Note): Promise<Result<AISummaryResult>> {
    return await this.onDeviceSource.summarizeNote(note);
  }

  /**
   * 云端摘要
   */
  private async summarizeWithCloud(note: Note): Promise<Result<AISummaryResult>> {
    if (!this.cloudAvailable) {
      return failure(ERROR_AI_SERVICE, 503, '云端 AI 不可用，请配置 API Key');
    }
    return await this.cloudSource.summarizeNote(note);
  }
}
