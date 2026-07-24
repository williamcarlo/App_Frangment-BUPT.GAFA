import common from '@ohos.app.ability.common'
import {
  AiAnalysisRecord,
  AiGatewayResult,
  FragmentEmbedding
} from '../model/AiModel'
import { CommunitySaveRecord } from '../model/CommunityModel'
import { EchoRecord } from '../model/EchoModel'
import {
  FragmentItem,
  FragmentRelation,
  FragmentVisibility,
  SharingConsent
} from '../model/FragmentModel'
import { AiRepository } from '../data/AiRepository'
import { CommunitySaveRepository } from '../data/CommunitySaveRepository'
import { ConsentRepository } from '../data/ConsentRepository'
import { DatabaseManager } from '../data/DatabaseManager'
import { EchoRepository } from '../data/EchoRepository'
import { FragmentRepository } from '../data/FragmentRepository'
import { MetadataRepository } from '../data/MetadataRepository'
import { RelationRepository } from '../data/RelationRepository'
import { DataIntegrityService, IntegrityReport } from '../service/DataIntegrityService'
import { IdService } from '../utils/IdService'

export enum OperationErrorCode {
  NONE = 'NONE',
  DATABASE_WRITE_FAILED = 'DATABASE_WRITE_FAILED',
  DUPLICATE_COMMUNITY_SAVE = 'DUPLICATE_COMMUNITY_SAVE',
  INVALID_RELATION = 'INVALID_RELATION',
  INITIALIZATION_FAILED = 'INITIALIZATION_FAILED',
  AI_CONSENT_FAILED = 'AI_CONSENT_FAILED',
  AI_RESULT_SAVE_FAILED = 'AI_RESULT_SAVE_FAILED'
}

export class OperationResult {
  success: boolean = false
  message: string = ''
  errorCode: OperationErrorCode = OperationErrorCode.NONE

  constructor(
    success: boolean,
    message: string,
    errorCode: OperationErrorCode = OperationErrorCode.NONE
  ) {
    this.success = success
    this.message = message
    this.errorCode = errorCode
  }
}

export class AppDataSnapshot {
  fragments: FragmentItem[] = []
  archivedFragments: FragmentItem[] = []
  relations: FragmentRelation[] = []
  echoRecords: EchoRecord[] = []
  communitySaveRecords: CommunitySaveRecord[] = []
  embeddings: FragmentEmbedding[] = []
  aiGatewayBaseUrl: string = ''
  shouldShowPrivacyExplainer: boolean = false
  integrityWarningCodes: string[] = []
}

export class FragmentAppViewModel {
  private database: DatabaseManager
  private aiRepository: AiRepository
  private fragmentRepository: FragmentRepository
  private relationRepository: RelationRepository
  private echoRepository: EchoRepository
  private consentRepository: ConsentRepository
  private communitySaveRepository: CommunitySaveRepository
  private metadataRepository: MetadataRepository
  private integrityService: DataIntegrityService
  private latestIntegrityReport: IntegrityReport = new IntegrityReport(0)

  constructor(database: DatabaseManager = new DatabaseManager()) {
    this.database = database
    this.aiRepository = new AiRepository(database)
    this.fragmentRepository = new FragmentRepository(database)
    this.relationRepository = new RelationRepository(database)
    this.echoRepository = new EchoRepository(database)
    this.consentRepository = new ConsentRepository(database)
    this.communitySaveRepository = new CommunitySaveRepository(database)
    this.metadataRepository = new MetadataRepository(database)
    this.integrityService = new DataIntegrityService(database)
  }

  async initialize(
    context: common.Context,
    seedFragments: FragmentItem[],
    seedRelations: FragmentRelation[]
  ): Promise<AppDataSnapshot> {
    await this.database.initialize(context)
    let initialized: string =
      await this.metadataRepository.getValue('seed_data_initialized_v1')
    if (initialized !== 'true' && this.database.isSeedEnabled()) {
      await this.initializeSeedData(seedFragments, seedRelations)
    }
    this.latestIntegrityReport = await this.integrityService.inspectAndRepair()
    return this.loadSnapshot()
  }

  async loadSnapshot(): Promise<AppDataSnapshot> {
    let snapshot: AppDataSnapshot = new AppDataSnapshot()
    snapshot.fragments = await this.fragmentRepository.loadActive()
    snapshot.archivedFragments = await this.fragmentRepository.loadArchived()
    snapshot.relations = await this.relationRepository.loadAll()
    snapshot.echoRecords = await this.echoRepository.loadAll()
    snapshot.communitySaveRecords = await this.communitySaveRepository.loadAll()
    snapshot.embeddings = await this.aiRepository.loadEmbeddings()
    snapshot.aiGatewayBaseUrl = await this.metadataRepository.getValue('ai_gateway_base_url')
    snapshot.shouldShowPrivacyExplainer =
      await this.metadataRepository.getValue('privacy_explainer_v1') !== 'acknowledged'
    snapshot.integrityWarningCodes = this.latestIntegrityReport.warningCodes.slice()
    return snapshot
  }

  async createFragment(
    fragment: FragmentItem,
    relation: FragmentRelation | null
  ): Promise<OperationResult> {
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      fragment.displayCode = await this.metadataRepository.allocateNextDisplayCode()
      await this.fragmentRepository.insert(fragment)
      if (relation !== null) {
        await this.relationRepository.insert(relation)
      }
      await this.consentRepository.recordTransition(
        this.consentFor(fragment, Date.now())
      )
      store.commit()
      return new OperationResult(true, '已放入 Box')
    } catch (error) {
      store.rollBack()
      return new OperationResult(
        false,
        '保存失败，请稍后重试',
        relation !== null &&
          (relation.fromFragmentId === 'empty' || relation.toFragmentId === 'empty') ?
          OperationErrorCode.INVALID_RELATION : OperationErrorCode.DATABASE_WRITE_FAILED
      )
    }
  }

  async saveCommunityCopy(
    fragment: FragmentItem,
    relation: FragmentRelation,
    saveRecord: CommunitySaveRecord
  ): Promise<OperationResult> {
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      if (await this.communitySaveRepository.findBySource(
        saveRecord.sourceCommunityNodeId
      ) !== null) {
        store.rollBack()
        return new OperationResult(
          false,
          '这条社区碎片已经收进 Box 了',
          OperationErrorCode.DUPLICATE_COMMUNITY_SAVE
        )
      }
      fragment.displayCode = await this.metadataRepository.allocateNextDisplayCode()
      await this.fragmentRepository.insert(fragment)
      await this.relationRepository.insert(relation)
      await this.consentRepository.recordTransition(
        this.consentFor(fragment, Date.now())
      )
      await this.communitySaveRepository.insert(saveRecord)
      store.commit()
      return new OperationResult(true, '已收进 Box · 仅自己可见')
    } catch (error) {
      store.rollBack()
      return new OperationResult(
        false,
        '收存失败，没有写入任何数据',
        OperationErrorCode.DATABASE_WRITE_FAILED
      )
    }
  }

  async updateFragment(fragment: FragmentItem): Promise<OperationResult> {
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      let existing: FragmentItem | null = await this.fragmentRepository.findById(fragment.id)
      if (existing === null) {
        throw new Error('FRAGMENT_NOT_FOUND')
      }
      let operationTime: number = Date.now()
      fragment.updatedAtTimestamp = operationTime
      await this.fragmentRepository.update(fragment)
      if (existing.visibility !== fragment.visibility) {
        await this.consentRepository.recordTransition(
          this.consentFor(fragment, operationTime)
        )
      }
      store.commit()
      return new OperationResult(true, '碎片已更新')
    } catch (error) {
      store.rollBack()
      return new OperationResult(
        false,
        '更新失败，请稍后重试',
        OperationErrorCode.DATABASE_WRITE_FAILED
      )
    }
  }

  async grantAiProcessingConsent(fragmentId: string): Promise<OperationResult> {
    try {
      await this.aiRepository.grantConsent(fragmentId, Date.now())
      return new OperationResult(true, '')
    } catch (error) {
      return new OperationResult(
        false,
        '无法记录幕后整理授权',
        OperationErrorCode.AI_CONSENT_FAILED
      )
    }
  }

  async saveAiProcessingResult(
    fragment: FragmentItem,
    result: AiGatewayResult,
    relation: FragmentRelation | null
  ): Promise<OperationResult> {
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      await this.fragmentRepository.update(fragment)
      await this.aiRepository.saveAnalysis(new AiAnalysisRecord(
        fragment.id,
        result.analysisProvider,
        result.analysisModel,
        result.analysis,
        Date.now()
      ))
      await this.aiRepository.saveEmbedding(result.embedding)
      if (relation !== null) {
        await this.relationRepository.insertOrReplace(relation)
      }
      store.commit()
      return new OperationResult(true, '幕后整理完成')
    } catch (error) {
      store.rollBack()
      return new OperationResult(
        false,
        '整理结果保存失败，本地碎片仍然安全',
        OperationErrorCode.AI_RESULT_SAVE_FAILED
      )
    }
  }

  async saveAiGatewayBaseUrl(baseUrl: string): Promise<OperationResult> {
    try {
      await this.metadataRepository.putValue('ai_gateway_base_url', baseUrl)
      return new OperationResult(true, '幕后整理地址已保存')
    } catch (error) {
      return this.writeFailure('幕后整理地址保存失败')
    }
  }

  async archiveFragment(fragmentId: string): Promise<OperationResult> {
    try {
      await this.fragmentRepository.archive(fragmentId, Date.now())
      return new OperationResult(true, '已移入归档箱')
    } catch (error) {
      return this.writeFailure('归档失败，请稍后重试')
    }
  }

  async restoreFragment(fragmentId: string): Promise<OperationResult> {
    try {
      await this.fragmentRepository.restore(fragmentId, Date.now())
      return new OperationResult(true, '碎片已恢复')
    } catch (error) {
      return this.writeFailure('恢复失败，请稍后重试')
    }
  }

  async deleteFragment(fragmentId: string): Promise<OperationResult> {
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      await this.relationRepository.deleteForFragment(fragmentId)
      await this.consentRepository.deleteForFragment(fragmentId)
      await this.echoRepository.deleteForFragment(fragmentId)
      await this.communitySaveRepository.deleteForFragment(fragmentId)
      await this.aiRepository.deleteForFragment(fragmentId)
      await this.fragmentRepository.deletePermanently(fragmentId)
      store.commit()
      return new OperationResult(true, '碎片已永久删除')
    } catch (error) {
      store.rollBack()
      return this.writeFailure('删除失败，没有写入部分状态')
    }
  }

  async revokeSharing(fragmentId: string): Promise<OperationResult> {
    let operationTime: number = Date.now()
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      await this.fragmentRepository.revokeSharing(fragmentId, operationTime)
      let revoked: FragmentItem | null = await this.fragmentRepository.findById(fragmentId)
      if (revoked === null) {
        throw new Error('FRAGMENT_NOT_FOUND')
      }
      await this.consentRepository.recordTransition(
        this.consentFor(revoked, operationTime)
      )
      store.commit()
      return new OperationResult(true, '已撤回共享，社区入口立即失效')
    } catch (error) {
      store.rollBack()
      return this.writeFailure('撤回失败，请稍后重试')
    }
  }

  async surfaceEcho(record: EchoRecord): Promise<OperationResult> {
    try {
      await this.echoRepository.insert(record)
      return new OperationResult(true, '')
    } catch (error) {
      return this.writeFailure('回响记录保存失败')
    }
  }

  async openEcho(recordId: string): Promise<OperationResult> {
    try {
      await this.echoRepository.markOpened(recordId, Date.now())
      return new OperationResult(true, '')
    } catch (error) {
      return this.writeFailure('回响打开状态保存失败')
    }
  }

  async dismissEcho(recordId: string, dismissedUntilTimestamp: number): Promise<OperationResult> {
    try {
      await this.echoRepository.dismiss(recordId, dismissedUntilTimestamp)
      return new OperationResult(true, '')
    } catch (error) {
      return this.writeFailure('回响稍后提醒状态保存失败')
    }
  }

  async acknowledgePrivacyExplainer(): Promise<OperationResult> {
    try {
      await this.metadataRepository.putValue('privacy_explainer_v1', 'acknowledged')
      return new OperationResult(true, '')
    } catch (error) {
      return this.writeFailure('隐私说明状态保存失败')
    }
  }

  async restoreDemoData(
    seedFragments: FragmentItem[],
    seedRelations: FragmentRelation[]
  ): Promise<OperationResult> {
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      let operationTime: number = Date.now()
      for (let i: number = 0; i < seedFragments.length; i++) {
        let existing: FragmentItem | null =
          await this.fragmentRepository.findById(seedFragments[i].id)
        if (existing !== null) {
          continue
        }
        let restored: FragmentItem = this.copyFragment(seedFragments[i])
        restored.displayCode = await this.metadataRepository.allocateNextDisplayCode()
        await this.fragmentRepository.insert(restored)
        await this.consentRepository.recordTransition(
          this.consentFor(restored, operationTime)
        )
      }
      for (let i: number = 0; i < seedRelations.length; i++) {
        let relation: FragmentRelation = seedRelations[i]
        let from: FragmentItem | null =
          await this.fragmentRepository.findById(relation.fromFragmentId)
        let to: FragmentItem | null =
          await this.fragmentRepository.findById(relation.toFragmentId)
        if (from !== null && to !== null) {
          await this.relationRepository.insertOrReplace(relation)
        }
      }
      await this.metadataRepository.putValue('seed_data_initialized_v1', 'true')
      store.commit()
      return new OperationResult(true, '演示数据已恢复')
    } catch (error) {
      store.rollBack()
      return this.writeFailure('恢复演示数据失败，没有留下部分数据')
    }
  }

  private async initializeSeedData(
    fragments: FragmentItem[],
    relations: FragmentRelation[]
  ): Promise<void> {
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      let operationTime: number = Date.now()
      for (let i: number = 0; i < fragments.length; i++) {
        await this.fragmentRepository.insert(fragments[i])
        await this.consentRepository.recordTransition(
          this.consentFor(fragments[i], operationTime)
        )
      }
      for (let i: number = 0; i < relations.length; i++) {
        await this.relationRepository.insert(relations[i])
      }
      let nextDisplayCode: number = await this.metadataRepository.maximumDisplayCode() + 1
      await this.metadataRepository.putValue(
        'next_display_code',
        nextDisplayCode.toString()
      )
      await this.metadataRepository.putValue('seed_data_initialized_v1', 'true')
      store.commit()
    } catch (error) {
      store.rollBack()
      throw new Error('初始化示例数据失败')
    }
  }

  private consentFor(fragment: FragmentItem, operationTime: number): SharingConsent {
    return new SharingConsent(
      IdService.create('consent', operationTime),
      fragment.id,
      fragment.visibility,
      '',
      operationTime,
      fragment.visibility === FragmentVisibility.REVOKED ? operationTime : 0,
      0,
      true
    )
  }

  private copyFragment(fragment: FragmentItem): FragmentItem {
    return new FragmentItem({
      id: fragment.id,
      displayCode: fragment.displayCode,
      tag: fragment.tag,
      text: fragment.text,
      tone: fragment.tone,
      remind: fragment.remind,
      visibility: fragment.visibility,
      createdAt: fragment.createdAt,
      createdAtTimestamp: fragment.createdAtTimestamp,
      updatedAtTimestamp: fragment.updatedAtTimestamp,
      archivedAtTimestamp: fragment.archivedAtTimestamp,
      sourceCommunityNodeId: fragment.sourceCommunityNodeId,
      moderationStatus: fragment.moderationStatus
    })
  }

  private writeFailure(message: string): OperationResult {
    return new OperationResult(
      false,
      message,
      OperationErrorCode.DATABASE_WRITE_FAILED
    )
  }
}
