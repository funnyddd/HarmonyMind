import http from '@ohos.net.http';
import { AISummaryResult } from '../../../model/AISummaryResult';
import { Note } from '../../../model/Note';
import { Result, success, failure } from '../../../common/Result';
import { Logger, getLogger } from '../../../common/Logger';
import {
  AI_CLOUD_API_URL,
  AI_REQUEST_TIMEOUT_MS,
  AI_MAX_SUMMARY_LENGTH,
  ERROR_AI_SERVICE,
  ERROR_NETWORK
} from '../../../common/Constants';

const TAG = 'CloudAIDataSource';
const log: Logger = getLogger(TAG);

/**
 * Interface for AI API request body (declared for ArkTS strict mode).
 */
interface AIRequestBody {
  prompt: string;
  task: string;
  max_tokens: number;
  temperature: number;
}

/**
 * Interface for AI API response data (declared for ArkTS strict mode).
 * Replaces Record<string, Object>.
 */
interface AIResponseData {
  summary?: string;
  tags?: string[];
  sentiment?: string;
  confidence?: number;
  tokensUsed?: number;
  category?: string;
  choices?: AIResponseChoice[];
}

/**
 * Interface for a single choice in OpenAI-format AI responses.
 */
interface AIResponseChoice {
  message?: AIMessageContent;
  text?: string;
}

/**
 * Interface for the message content inside an AI response choice.
 */
interface AIMessageContent {
  content?: string;
}

/**
 * Interface for categorize results returned by categorizeNote.
 */
interface AICategorizeResult {
  category: string;
  confidence: number;
}

/**
 * CloudAIDataSource — 云端 AI 数据源
 * 通过 HTTP 调用远端 AI API (GPT/盘古等) 生成摘要和分类
 */
export class CloudAIDataSource {
  private apiUrl: string;
  private apiKey: string = '';

  constructor(apiUrl: string = AI_CLOUD_API_URL) {
    this.apiUrl = apiUrl;
  }

  /**
   * 设置 API Key (从应用设置中读取)
   */
  setApiKey(key: string): void {
    this.apiKey = key;
  }

  /**
   * 调用云端 AI 生成笔记摘要
   */
  async summarizeNote(note: Note): Promise<Result<AISummaryResult>> {
    if (!this.apiKey) {
      return failure(ERROR_AI_SERVICE, 401, 'AI API Key 未配置');
    }

    try {
      const prompt: string = this.buildSummaryPrompt(note.title, note.content);
      const response: AIResponseData | null = await this.callAIAPI(prompt, 'summary');

      if (!response || !response.summary) {
        return failure(ERROR_AI_SERVICE, 500, 'AI 返回空结果');
      }

      const result: AISummaryResult = new AISummaryResult(response.summary, note.id, 'cloud');
      result.keyTags = response.tags || [];
      result.confidence = response.confidence || 0.8;
      result.tokensUsed = response.tokensUsed || 0;
      result.sentiment = response.sentiment || 'neutral';

      log.info('Cloud AI summary generated: noteId=' + note.id +
        ', tokens=' + result.tokensUsed + ', confidence=' + result.confidence);

      return success(result);
    } catch (err) {
      log.error('Cloud AI summarize failed: noteId=' + note.id, err);
      return failure(ERROR_AI_SERVICE, err as number, '云端 AI 摘要失败');
    }
  }

  /**
   * 调用云端 AI 进行文本分类
   */
  async categorizeNote(note: Note): Promise<Result<AICategorizeResult>> {
    if (!this.apiKey) {
      return failure(ERROR_AI_SERVICE, 401, 'AI API Key 未配置');
    }

    try {
      const prompt: string = this.buildCategoryPrompt(note.title, note.content);
      const response: AIResponseData | null = await this.callAIAPI(prompt, 'categorize');

      if (!response || !response.category) {
        return failure(ERROR_AI_SERVICE, 500, 'AI 分类返回空结果');
      }

      const categorizeResult: AICategorizeResult = {
        category: response.category,
        confidence: response.confidence || 0.7
      };
      return success(categorizeResult);
    } catch (err) {
      log.error('Cloud AI categorize failed: noteId=' + note.id, err);
      return failure(ERROR_AI_SERVICE, err as number, '云端 AI 分类失败');
    }
  }

  /**
   * 构建摘要生成 Prompt
   */
  private buildSummaryPrompt(title: string, content: string): string {
    return '请为以下笔记生成简洁摘要（不超过' + AI_MAX_SUMMARY_LENGTH +
      '字），并提取最多5个关键标签。\n\n' +
      '标题：' + (title || '无标题') + '\n' +
      '内容：\n' +
      content + '\n\n' +
      '请以JSON格式返回，包含 summary, tags (数组), sentiment (positive/negative/neutral)。';
  }

  /**
   * 构建分类 Prompt
   */
  private buildCategoryPrompt(title: string, content: string): string {
    return '请将以下笔记分类到最合适的类别中（工作/学习/生活/灵感/会议/读书/旅行/其他），\n' +
      '并返回置信度。\n\n' +
      '标题：' + (title || '无标题') + '\n' +
      '内容：\n' +
      content.substring(0, 500) + '\n\n' +
      '请以JSON格式返回，包含 category, confidence。';
  }

  /**
   * 调用远端 AI HTTP API
   */
  private async callAIAPI(
    prompt: string,
    taskType: string
  ): Promise<AIResponseData | null> {
    const httpRequest = http.createHttp();

    try {
      const requestBody: AIRequestBody = {
        prompt: prompt,
        task: taskType,
        max_tokens: taskType === 'summary' ? AI_MAX_SUMMARY_LENGTH : 50,
        temperature: 0.3
      };

      const requestBodyStr: string = JSON.stringify(requestBody);
      const url: string = this.apiUrl + '/chat/completions';

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + this.apiKey
        },
        extraData: requestBodyStr,
        connectTimeout: AI_REQUEST_TIMEOUT_MS,
        readTimeout: AI_REQUEST_TIMEOUT_MS
      });

      if (response.responseCode === 200) {
        const resultStr: string = (response.result as string) || '';
        try {
          const parsed: AIResponseData = JSON.parse(resultStr) as AIResponseData;

          // 适配 OpenAI 格式
          if (parsed.choices && Array.isArray(parsed.choices) && parsed.choices.length > 0) {
            const choice: AIResponseChoice = parsed.choices[0];
            const content: string = choice.message?.content || choice.text || '';
            return this.parseAIResponse(content);
          }

          return parsed;
        } catch (parseErr) {
          log.error('Failed to parse AI response', parseErr);
          return null;
        }
      } else {
        log.error('AI API returned non-200: code=' + response.responseCode);
        return null;
      }
    } catch (err) {
      log.error('HTTP request to AI API failed', err);
      throw new Error(String(err));
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 解析 AI 返回的 JSON 字符串
   */
  private parseAIResponse(content: string): AIResponseData | null {
    try {
      // 尝试直接解析整个内容
      const jsonMatch: RegExpMatchArray | null = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]) as AIResponseData;
      }
      return JSON.parse(content) as AIResponseData;
    } catch (e) {
      log.error('Failed to parse AI content as JSON', e);
      const fallback: AIResponseData = {
        summary: content,
        tags: [],
        sentiment: 'neutral',
        confidence: 0.5
      };
      return fallback;
    }
  }
}
