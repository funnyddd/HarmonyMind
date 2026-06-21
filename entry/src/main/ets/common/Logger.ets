import hilog from '@ohos.hilog';

/**
 * Logger — 统一日志工具
 * 基于 hilog 封装，支持模块化标签
 */

const TAG_PREFIX = 'HarmonyMind';
const DOMAIN = 0x0001;

export enum LogLevel {
  DEBUG = 4,
  INFO = 3,
  WARN = 2,
  ERROR = 1,
  FATAL = 0
}

export class Logger {
  private tag: string;
  private static globalLevel: LogLevel = LogLevel.DEBUG;

  constructor(tag: string) {
    this.tag = `${TAG_PREFIX}.${tag}`;
  }

  static setLogLevel(level: LogLevel): void {
    Logger.globalLevel = level;
  }

  debug(msg: string, ...args: Object[]): void {
    if (LogLevel.DEBUG <= Logger.globalLevel) {
      hilog.debug(DOMAIN, this.tag, `%{public}s`, this.formatMsg(msg, args));
    }
  }

  info(msg: string, ...args: Object[]): void {
    if (LogLevel.INFO <= Logger.globalLevel) {
      hilog.info(DOMAIN, this.tag, `%{public}s`, this.formatMsg(msg, args));
    }
  }

  warn(msg: string, ...args: Object[]): void {
    if (LogLevel.WARN <= Logger.globalLevel) {
      hilog.warn(DOMAIN, this.tag, `%{public}s`, this.formatMsg(msg, args));
    }
  }

  error(msg: string, ...args: Object[]): void {
    if (LogLevel.ERROR <= Logger.globalLevel) {
      hilog.error(DOMAIN, this.tag, `%{public}s`, this.formatMsg(msg, args));
    }
  }

  fatal(msg: string, ...args: Object[]): void {
    hilog.fatal(DOMAIN, this.tag, `%{public}s`, this.formatMsg(msg, args));
  }

  private formatMsg(msg: string, args: Object[]): string {
    if (args.length === 0) {
      return msg;
    }
    try {
      return `${msg} | ${JSON.stringify(args)}`;
    } catch (e) {
      return msg;
    }
  }
}

/**
 * 获取一个带标签的 Logger 实例
 * 使用方式: const log = getLogger('Repository');
 */
export function getLogger(tag: string): Logger {
  return new Logger(tag);
}

export const Log = getLogger('Core');
