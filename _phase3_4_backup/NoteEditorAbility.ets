import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import window from '@ohos.window';
import { ServiceFactory } from '../domain/factory/ServiceFactory';
import { Logger, getLogger } from '../common/Logger';

const TAG = 'NoteEditorAbility';
const log: Logger = getLogger(TAG);

/**
 * NoteEditorAbility — 笔记编辑 Ability
 *
 * 核心特性：支持 Continuation（跨设备无缝切换）
 *
 * 场景:
 *   用户在手机上编辑笔记 → 靠近平板 → Continuation 触发
 *   → 笔记编辑状态无缝迁移到平板继续编辑
 *
 * Continuation 流程:
 *   设备A (onContinue) → 保存编辑状态 → 分布式软总线
 *   → 设备B (onCreate/onNewWant) → onRestore 恢复状态
 */
export default class NoteEditorAbility extends UIAbility {
  private noteId: string = '';
  private cursorPosition: number = 0;
  private scrollOffset: number = 0;

  /**
   * Ability 创建时调用
   * 可能包含 Continuation 恢复数据
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    log.info('NoteEditorAbility onCreate', {
      launchReason: launchParam.launchReason,
      hasParameters: !!want.parameters
    });

    // 提取笔记 ID
    if (want.parameters) {
      const params = want.parameters as Record<string, Object>;
      if (params['noteId']) {
        this.noteId = params['noteId'] as string;
      }
    }
  }

  /**
   * WindowStage 创建
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    log.info('NoteEditorAbility onWindowStageCreate', { noteId: this.noteId });

    // 构建页面参数
    const pageParams: Record<string, Object> = {};

    if (this.noteId) {
      pageParams['noteId'] = this.noteId;
    }

    // 如果是从 Continuation 恢复，传递光标位置
    if (this.cursorPosition > 0) {
      pageParams['cursorPos'] = this.cursorPosition;
    }
    if (this.scrollOffset > 0) {
      pageParams['scrollOffset'] = this.scrollOffset;
    }

    // 加载编辑页面
    windowStage.loadContent('pages/NoteEditorPage', pageParams, (err) => {
      if (err.code) {
        log.error('Failed to load editor page', err);
        return;
      }
      log.info('Editor page loaded', { noteId: this.noteId });
    });
  }

  /**
   * ★ Continuation: 设备A 保存编辑状态
   *
   * 系统在迁移前调用，返回当前编辑状态。
   * 这些数据通过分布式软总线传递到目标设备。
   */
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    log.info('NoteEditorAbility onContinue — saving editor state', {
      noteId: this.noteId,
      cursorPos: this.cursorPosition
    });

    try {
      const factory = ServiceFactory.getInstance();
      const continuationService = factory.getContinuationService();

      // 构建 Continuation 数据
      const continueData = continuationService.buildContinueData(
        this.noteId || '',
        this.cursorPosition,
        this.scrollOffset
      );

      // 存入 wantParam，系统将投递这些数据到目标设备
      wantParam['continueData'] = continueData;
      wantParam['noteId'] = this.noteId;
      wantParam['timestamp'] = Date.now();

      log.info('Continuation state saved', {
        dataLength: continueData.length
      });

      return AbilityConstant.OnContinueResult.AGREE;
    } catch (err) {
      log.error('onContinue failed', err);

      // 降级：至少传递笔记 ID
      wantParam['noteId'] = this.noteId;
      return AbilityConstant.OnContinueResult.AGREE;
    }
  }

  /**
   * ★ Continuation: 设备B 恢复编辑状态
   *
   * 从系统传递的 wantParam 中解析并恢复编辑状态。
   * 此方法在 onNewWant 或 onCreate 中合适时机调用。
   */
  onRestore(wantParam: Record<string, Object>): void {
    log.info('NoteEditorAbility onRestore — restoring editor state');

    try {
      // 恢复笔记 ID
      if (wantParam['noteId']) {
        this.noteId = wantParam['noteId'] as string;
      }

      // 恢复 Continuation 数据
      if (wantParam['continueData']) {
        const continueDataJson = wantParam['continueData'] as string;
        const factory = ServiceFactory.getInstance();
        const continuationService = factory.getContinuationService();
        const continueData = continuationService.parseContinueData(continueDataJson);

        if (continueData && continuationService.validateContinueData(continueData)) {
          this.noteId = continueData.noteId || this.noteId;
          this.cursorPosition = continueData.cursorPos;
          this.scrollOffset = continueData.scrollOffset;

          log.info('Editor state restored', {
            noteId: this.noteId,
            cursorPos: this.cursorPosition,
            scrollOffset: this.scrollOffset
          });
        }
      }
    } catch (err) {
      log.error('onRestore failed', err);
    }
  }

  /**
   * 新 Want 到来 (可能包含 Continuation 数据)
   */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    log.info('NoteEditorAbility onNewWant');

    // 检查是否为 Continuation 恢复
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      if (want.parameters) {
        this.onRestore(want.parameters as Record<string, Object>);
      }
    }

    // 处理新笔记 ID
    if (want.parameters) {
      const params = want.parameters as Record<string, Object>;
      if (params['noteId']) {
        this.noteId = params['noteId'] as string;
      }
    }
  }

  /**
   * 前台回调
   */
  onForeground(): void {
    log.info('NoteEditorAbility onForeground', { noteId: this.noteId });
  }

  /**
   * 后台回调 — 触发自动保存
   */
  onBackground(): void {
    log.info('NoteEditorAbility onBackground', { noteId: this.noteId });
    // 编辑中的笔记自动保存由 NoteEditorViewModel 处理
  }

  /**
   * 销毁
   */
  onDestroy(): void {
    log.info('NoteEditorAbility onDestroy', { noteId: this.noteId });
  }
}
