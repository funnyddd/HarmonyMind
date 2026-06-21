import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import formProvider from '@ohos.app.form.formProvider';
import formInfo from '@ohos.app.form.formInfo';
import { ServiceFactory } from '../domain/factory/ServiceFactory';
import { Note } from '../model/Note';
import { Logger, getLogger } from '../common/Logger';

const TAG = 'QuickNoteFormAbility';
const log: Logger = getLogger(TAG);

/**
 * QuickNoteFormAbility — 桌面元服务卡片
 *
 * 功能:
 * - 桌面 2×2 / 2×4 卡片快速记笔记
 * - 显示最近笔记摘要
 * - 一键进入编辑
 * - 定时更新卡片内容
 *
 * FormExtensionAbility (Stage 模型元服务核心) ★
 */
export default class QuickNoteFormAbility extends FormExtensionAbility {
  /**
   * 卡片创建时
   */
  onAddForm(want: Record<string, Object>): formBindingData.FormBindingData {
    log.info('QuickNoteFormAbility onAddForm');

    const formData: Record<string, Object> = {
      'recentNoteTitle': '点击快速记录笔记',
      'recentNotePreview': '通过桌面卡片一键记录灵感和想法',
      'noteCount': 0,
      'lastSyncTime': '—'
    };

    // 异步加载最新数据
    this.loadRecentNoteData(formData);

    return formBindingData.createFormBindingData(formData);
  }

  /**
   * 卡片更新时 (定时更新 / 主动刷新)
   */
  onUpdateForm(formId: string): void {
    log.info('QuickNoteFormAbility onUpdateForm', { formId });

    const formData: Record<string, Object> = {
      'recentNoteTitle': '点击快速记录笔记',
      'recentNotePreview': '通过桌面卡片一键记录灵感和想法',
      'noteCount': 0,
      'lastSyncTime': '—'
    };

    // 加载最新数据并更新卡片
    this.loadRecentNoteData(formData).then(() => {
      const bindingData = formBindingData.createFormBindingData(formData);
      formProvider.updateForm(formId, bindingData).catch((err: Error) => {
        log.error('Failed to update form', err);
      });
    });
  }

  /**
   * 卡片点击事件处理
   */
  onFormEvent(formId: string, message: string): void {
    log.info('QuickNoteFormAbility onFormEvent', { formId, message });

    switch (message) {
      case 'newNote':
        // 跳转到编辑页 (通过 startAbility)
        this.openNewNote();
        break;

      case 'voiceNote':
        // 跳转到语音笔记
        this.openVoiceNote();
        break;

      default:
        log.debug('Unknown form event', { message });
    }
  }

  /**
   * 卡片销毁时
   */
  onRemoveForm(formId: string): void {
    log.info('QuickNoteFormAbility onRemoveForm', { formId });
  }

  /**
   * 卡片可见性变更
   */
  onVisibilityChange(newStatus: Record<string, number>): void {
    log.info('QuickNoteFormAbility onVisibilityChange', {
      visibility: JSON.stringify(newStatus)
    });
  }

  /**
   * 卡片配置变更 (如旋转、语言切换)
   */
  onConfigurationUpdate(config: Record<string, Object>): void {
    log.info('QuickNoteFormAbility onConfigurationUpdate');
  }

  /**
   * 分享给其他设备 (分布式能力)
   */
  onShareForm(wantParam: Record<string, Object>): Record<string, Object> {
    log.info('QuickNoteFormAbility onShareForm (distributed)');
    return wantParam;
  }

  // ========== 私有方法 ==========

  /**
   * 异步加载最近笔记数据
   */
  private async loadRecentNoteData(formData: Record<string, Object>): Promise<void> {
    try {
      const factory = ServiceFactory.getInstance();
      const repo = factory.getNoteRepository();
      const result = await repo.getAllNotes(1, 0);

      if (result.isSuccess && result.data.length > 0) {
        const note = result.data[0];
        formData['recentNoteTitle'] = note.title || '无标题';
        formData['recentNotePreview'] = note.preview || '';
        formData['noteCount'] = result.data.length;
        formData['lastSyncTime'] = this.formatTime(note.updatedAt);
      }
    } catch (err) {
      log.warn('Failed to load recent note data for widget', err);
    }
  }

  /**
   * 打开新建笔记页面
   */
  private openNewNote(): void {
    // 通过 FormExtensionContext 启动 NoteEditorAbility
    // 注意: FormExtension 中需要使用特定的 API 启动 Ability
    log.info('Opening new note from widget');
    // TODO: 实现 Ability 跳转逻辑
  }

  /**
   * 打开语音笔记
   */
  private openVoiceNote(): void {
    log.info('Opening voice note from widget');
    // TODO: 实现语音笔记跳转
  }

  /**
   * 格式化时间
   */
  private formatTime(isoStr: string): string {
    if (!isoStr) return '—';
    try {
      const date = new Date(isoStr);
      const h = date.getHours().toString().padStart(2, '0');
      const m = date.getMinutes().toString().padStart(2, '0');
      return `${h}:${m}`;
    } catch (e) {
      return '—';
    }
  }
}
