import { Note } from '../../model/Note';
import { Logger, getLogger } from '../../common/Logger';

const TAG = 'ContinuationService';
const log: Logger = getLogger(TAG);

/**
 * ContinuationService — 跨设备无缝切换服务
 *
 * 通过 onContinue / onRestore 回调实现编辑状态在设备间的传递。
 * 被 NoteEditorAbility 调用。
 *
 * 数据流:
 *   设备A (onContinue) → 序列化编辑状态 → 分布式软总线
 *   → 设备B (onRestore) → 恢复编辑状态 → 继续编辑
 */
export class ContinuationService {
  /**
   * 构建 Continuation 传输数据
   * 在 onContinue() 中调用
   *
   * @param noteId 当前编辑的笔记 ID
   * @param cursorPos 光标位置
   * @param scrollOffset 滚动偏移
   * @returns 序列化后的状态字符串
   */
  buildContinueData(
    noteId: string,
    cursorPos: number = 0,
    scrollOffset: number = 0
  ): string {
    const data = {
      noteId: noteId,
      cursorPos: cursorPos,
      scrollOffset: scrollOffset,
      timestamp: Date.now()
    };

    const jsonStr = JSON.stringify(data);
    log.info('Continuation data built', {
      noteId,
      cursorPos,
      dataLength: jsonStr.length
    });

    return jsonStr;
  }

  /**
   * 解析 Continuation 恢复数据
   * 在 onRestore() 中调用
   *
   * @param data onContinue 传输的序列化字符串
   * @returns 解析后的编辑状态
   */
  parseContinueData(data: string): ContinueData | null {
    try {
      const parsed = JSON.parse(data) as Object;
      const continueData: ContinueData = {
        noteId: (parsed['noteId'] as string) || '',
        cursorPos: (parsed['cursorPos'] as number) || 0,
        scrollOffset: (parsed['scrollOffset'] as number) || 0,
        timestamp: (parsed['timestamp'] as number) || 0
      };

      log.info('Continuation data parsed', {
        noteId: continueData.noteId,
        cursorPos: continueData.cursorPos
      });

      return continueData;
    } catch (err) {
      log.error('Failed to parse continuation data', err);
      return null;
    }
  }

  /**
   * 验证 Continuation 数据完整性
   */
  validateContinueData(data: ContinueData): boolean {
    if (!data.noteId || data.noteId.length === 0) {
      log.warn('Invalid continuation data: missing noteId');
      return false;
    }

    if (data.timestamp > 0 && Date.now() - data.timestamp > 300000) {
      log.warn('Continuation data expired', {
        timestamp: data.timestamp,
        age: Date.now() - data.timestamp
      });
      // 不过期拒绝，仅警告
    }

    return true;
  }
}

/**
 * Continuation 传输数据结构
 */
export interface ContinueData {
  noteId: string;
  cursorPos: number;
  scrollOffset: number;
  timestamp: number;
}
