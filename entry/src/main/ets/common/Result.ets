/**
 * Result<T> — 统一业务结果封装 (ArkTS 兼容)
 *
 * ArkTS 严格模式不支持 discriminated union 类型收窄。
 * 使用单 class: isSuccess 判断分支，所有字段始终可访问。
 *
 *   const r = result from any operation;
 *   if (r.isSuccess && r.data !== null) { ... r.data ... }
 *   else { ... r.error, r.code, r.message ... }
 */
export class Result<T> {
  readonly isSuccess: boolean;
  readonly isFailure: boolean;
  readonly data: T | null;
  readonly error: string;
  readonly code: number;
  readonly message: string;

  private constructor(
    isSuccess: boolean,
    data: T | null,
    error: string,
    code: number,
    message: string
  ) {
    this.isSuccess = isSuccess;
    this.isFailure = !isSuccess;
    this.data = data;
    this.error = error;
    this.code = code;
    this.message = message;
  }

  static success<T>(data: T): Result<T> {
    return new Result<T>(true, data, '', 0, '');
  }

  static failure<T>(error: string, code?: number, message?: string): Result<T> {
    return new Result<T>(false, null, error, code ?? -1, message ?? error);
  }
}

export function success<T>(data: T): Result<T> {
  return Result.success(data);
}

export function failure<T>(error: string, code?: number, message?: string): Result<T> {
  return Result.failure(error, code, message);
}

export function fold<T, R>(result: Result<T>, onSuccess: (data: T) => R, onFailure: (error: string) => R): R {
  if (result.isSuccess && result.data !== null) {
    return onSuccess(result.data);
  }
  return onFailure(result.error);
}

export function getOrDefault<T>(result: Result<T>, defaultValue: T): T {
  if (result.isSuccess && result.data !== null) {
    return result.data;
  }
  return defaultValue;
}
