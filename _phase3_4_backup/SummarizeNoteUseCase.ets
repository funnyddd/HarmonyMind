import { Note } from '../../model/Note';
import { AISummaryResult } from '../../model/AISummaryResult';
import { Result, success, failure } from '../../common/Result';
import { AIService } from '../service/AIService';
import { NoteRepository } from '../../data/repository/NoteRepository';
import { Logger, getLogger } from '../../common/Logger';
import { ERROR_AI_SERVICE, ERROR_NOTE_NOT_FOUND } from '../../common/Constants';

const TAG = 'SummarizeNoteUseCase';
const log: Logger = getLogger(TAG);

export class SummarizeNoteUseCase {
  private repository: NoteRepository;
  private aiService: AIService;

  constructor(repository: NoteRepository, aiService: AIService) {
    this.repository = repository;
    this.aiService = aiService;
  }

  async execute(noteId: string): Promise<Result<AISummaryResult>> {
    const noteResult = await this.repository.getNoteById(noteId);

    if (noteResult.isFailure) {
      return failure(noteResult.error, noteResult.code, noteResult.message);
    }

    if (noteResult.data === null) {
      return failure(ERROR_NOTE_NOT_FOUND, 404, `笔记不存在: ${noteId}`);
    }

    const note: Note = noteResult.data;

    log.info('Generating AI summary', { noteId: noteId });
    const summaryResult = await this.aiService.summarize(note);

    if (summaryResult.isFailure) {
      log.error('AI summary generation failed', { error: summaryResult.error });
      return summaryResult;
    }

    const aiResult: AISummaryResult = summaryResult.data as AISummaryResult;

    const updateResult = await this.repository.updateAISummary(
      noteId, aiResult.summary, aiResult.suggestedCategory
    );

    if (updateResult.isFailure) {
      log.warn('Failed to persist AI summary', { error: updateResult.error });
    }

    log.info('AI summary generated and persisted', {
      noteId: noteId,
      source: aiResult.source,
      confidence: aiResult.confidence
    });

    return success(aiResult);
  }

  async executeBatch(noteIds: string[]): Promise<Result<Map<string, AISummaryResult>>> {
    const results = new Map<string, AISummaryResult>();
    const errors: string[] = [];
    const batchSize: number = 3;

    for (let i = 0; i < noteIds.length; i += batchSize) {
      const batch: string[] = noteIds.slice(i, i + batchSize);
      const batchResults: Result<AISummaryResult>[] = await Promise.all(
        batch.map((id: string) => this.execute(id))
      );

      for (let j = 0; j < batch.length; j++) {
        const itemResult = batchResults[j];
        if (itemResult.isSuccess && itemResult.data !== null) {
          results.set(batch[j], itemResult.data);
        } else {
          errors.push('Note ' + batch[j] + ': ' + itemResult.message);
        }
      }
    }

    if (errors.length > 0) {
      log.warn('Some batch summaries failed', { errors: errors });
    }

    return success(results);
  }
}
