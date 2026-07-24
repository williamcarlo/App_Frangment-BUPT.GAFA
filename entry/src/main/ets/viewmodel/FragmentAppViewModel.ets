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
import { CommunitySaveRepository } from '../data/CommunitySaveRepository'
import { AiRepository } from '../data/AiRepository'
import { ConsentRepository } from '../data/ConsentRepository'
import { DatabaseManager } from '../data/DatabaseManager'
import { EchoRepository } from '../data/EchoRepository'
import { FragmentRepository } from '../data/FragmentRepository'
import { MetadataRepository } from '../data/MetadataRepository'
import { RelationRepository } from '../data/RelationRepository'
import { IdService } from '../utils/IdService'

export class OperationResult {
  success: boolean = false
  message: string = ''

  constructor(success: boolean, message: string) {
    this.success = success
    this.message = message
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
}

export class FragmentAppViewModel {
  private database: DatabaseManager = new DatabaseManager()
  private aiRepository: AiRepository = new AiRepository(this.database)
  private fragmentRepository: FragmentRepository = new FragmentRepository(this.database)
  private relationRepository: RelationRepository = new RelationRepository(this.database)
  private echoRepository: EchoRepository = new EchoRepository(this.database)
  private consentRepository: ConsentRepository = new ConsentRepository(this.database)
  private communitySaveRepository: CommunitySaveRepository = new CommunitySaveRepository(this.database)
  private metadataRepository: MetadataRepository = new MetadataRepository(this.database)

  async initialize(
    context: common.UIAbilityContext,
    seedFragments: FragmentItem[],
    seedRelations: FragmentRelation[]
  ): Promise<AppDataSnapshot> {
    await this.database.initialize(context)
    if (await this.fragmentRepository.count() === 0) {
      await this.seed(seedFragments, seedRelations)
    }
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
    return snapshot
  }

  async createFragment(fragment: FragmentItem, relation: FragmentRelation): Promise<OperationResult> {
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      await this.fragmentRepository.insert(fragment)
      await this.relationRepository.insert(relation)
      await this.consentRepository.insert(this.consentFor(fragment))
      store.commit()
      return new OperationResult(true, '已放入 Box')
    } catch (error) {
      store.rollBack()
      return new OperationResult(false, '保存失败，请稍后重试')
    }
  }

  async saveCommunityCopy(
    fragment: FragmentItem,
    relation: FragmentRelation,
    saveRecord: CommunitySaveRecord
  ): Promise<OperationResult> {
    if (await this.communitySaveRepository.findBySource(saveRecord.sourceCommunityNodeId) !== null) {
      return new OperationResult(false, '这条社区碎片已经收进 Box 了')
    }
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      await this.fragmentRepository.insert(fragment)
      await this.relationRepository.insert(relation)
      await this.consentRepository.insert(this.consentFor(fragment))
      await this.communitySaveRepository.insert(saveRecord)
      store.commit()
      return new OperationResult(true, '已收进 Box · 仅自己可见')
    } catch (error) {
      store.rollBack()
      return new OperationResult(false, '收存失败，没有写入任何数据')
    }
  }

  async updateFragment(fragment: FragmentItem): Promise<OperationResult> {
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      await this.fragmentRepository.update(fragment)
      await this.consentRepository.insert(this.consentFor(fragment))
      store.commit()
      return new OperationResult(true, '碎片已更新')
    } catch (error) {
      store.rollBack()
      return new OperationResult(false, '更新失败，请稍后重试')
    }
  }

  async grantAiProcessingConsent(fragmentId: string): Promise<OperationResult> {
    try {
      await this.aiRepository.grantConsent(fragmentId, Date.now())
      return new OperationResult(true, '')
    } catch (error) {
      return new OperationResult(false, '无法记录幕后整理授权')
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
      return new OperationResult(false, '整理结果保存失败，本地碎片仍然安全')
    }
  }

  async saveAiGatewayBaseUrl(baseUrl: string): Promise<OperationResult> {
    try {
      await this.metadataRepository.putValue('ai_gateway_base_url', baseUrl)
      return new OperationResult(true, '幕后整理地址已保存')
    } catch (error) {
      return new OperationResult(false, '幕后整理地址保存失败')
    }
  }

  async archiveFragment(fragmentId: string): Promise<OperationResult> {
    try {
      await this.fragmentRepository.archive(fragmentId, Date.now())
      return new OperationResult(true, '已移入归档箱')
    } catch (error) {
      return new OperationResult(false, '归档失败，请稍后重试')
    }
  }

  async restoreFragment(fragmentId: string): Promise<OperationResult> {
    try {
      await this.fragmentRepository.restore(fragmentId, Date.now())
      return new OperationResult(true, '碎片已恢复')
    } catch (error) {
      return new OperationResult(false, '恢复失败，请稍后重试')
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
      return new OperationResult(false, '删除失败，没有写入部分状态')
    }
  }

  async revokeSharing(fragmentId: string): Promise<OperationResult> {
    let nowTimestamp: number = Date.now()
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      await this.fragmentRepository.revokeSharing(fragmentId, nowTimestamp)
      await this.consentRepository.revokeForFragment(fragmentId, nowTimestamp)
      store.commit()
      return new OperationResult(true, '已撤回共享，社区入口立即失效')
    } catch (error) {
      store.rollBack()
      return new OperationResult(false, '撤回失败，请稍后重试')
    }
  }

  async surfaceEcho(record: EchoRecord): Promise<OperationResult> {
    try {
      await this.echoRepository.insert(record)
      return new OperationResult(true, '')
    } catch (error) {
      return new OperationResult(false, '回响记录保存失败')
    }
  }

  async openEcho(recordId: string): Promise<OperationResult> {
    try {
      await this.echoRepository.markOpened(recordId, Date.now())
      return new OperationResult(true, '')
    } catch (error) {
      return new OperationResult(false, '回响打开状态保存失败')
    }
  }

  async dismissEcho(recordId: string, dismissedUntilTimestamp: number): Promise<OperationResult> {
    try {
      await this.echoRepository.dismiss(recordId, dismissedUntilTimestamp)
      return new OperationResult(true, '')
    } catch (error) {
      return new OperationResult(false, '回响稍后提醒状态保存失败')
    }
  }

  async acknowledgePrivacyExplainer(): Promise<OperationResult> {
    try {
      await this.metadataRepository.putValue('privacy_explainer_v1', 'acknowledged')
      return new OperationResult(true, '')
    } catch (error) {
      return new OperationResult(false, '隐私说明状态保存失败')
    }
  }

  private async seed(fragments: FragmentItem[], relations: FragmentRelation[]): Promise<void> {
    let store = this.database.getStore()
    store.beginTransaction()
    try {
      for (let i: number = 0; i < fragments.length; i++) {
        await this.fragmentRepository.insert(fragments[i])
        await this.consentRepository.insert(this.consentFor(fragments[i]))
      }
      for (let i: number = 0; i < relations.length; i++) {
        await this.relationRepository.insert(relations[i])
      }
      store.commit()
    } catch (error) {
      store.rollBack()
      throw new Error('初始化示例数据失败')
    }
  }

  private consentFor(fragment: FragmentItem): SharingConsent {
    return new SharingConsent(
      IdService.create('consent', fragment.createdAtTimestamp),
      fragment.id,
      fragment.visibility,
      '',
      fragment.createdAtTimestamp,
      fragment.visibility === FragmentVisibility.REVOKED ? fragment.updatedAtTimestamp : 0
    )
  }
}
