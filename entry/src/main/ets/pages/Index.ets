import common from '@ohos.app.ability.common'
import { EchoCard } from '../components/EchoCard'
import { CommunityTree } from '../components/CommunityTree'
import { LifecycleConfirmDialog } from '../components/LifecycleConfirmDialog'
import { PersonalGraph as PersonalGraphView } from '../components/PersonalGraph'
import { FragmentInputSheet } from '../components/FragmentInputSheet'
import { PrivacyExplainer } from '../components/PrivacyExplainer'
import {
  AiGatewayResult,
  FragmentEmbedding
} from '../model/AiModel'
import { CommunityNode, CommunitySaveRecord } from '../model/CommunityModel'
import { EchoCandidate, EchoRecord } from '../model/EchoModel'
import {
  FragmentItem,
  FragmentLifecycleAction,
  FragmentRelation,
  FragmentVisibility,
  ReminderPreference,
  visibilityLabel
} from '../model/FragmentModel'
import { GraphEdge, GraphNode } from '../model/GraphModel'
import { SeedData } from '../data/SeedData'
import { AiGatewayService } from '../service/AiGatewayService'
import {
  AiSimilarityService,
  SimilarFragmentMatch
} from '../service/AiSimilarityService'
import { CommunityService } from '../service/CommunityService'
import { CommunityDemoCatalog } from '../service/CommunityDemoCatalog'
import { EchoService } from '../service/EchoService'
import { GraphBuilderService, GraphSnapshot } from '../service/GraphBuilderService'
import { RelationService } from '../service/RelationService'
import { StableCommunityNodeIdService } from '../service/StableCommunityNodeIdService'
import { AppPage, BoxStyle } from '../theme/FragmentTheme'
import { DateUtils } from '../utils/DateUtils'
import { IdService } from '../utils/IdService'
import {
  AppDataSnapshot,
  FragmentAppViewModel,
  OperationResult
} from '../viewmodel/FragmentAppViewModel'

@Entry
@Component
struct Index {
  @State currentPage: AppPage = AppPage.BOX
  @State graphMode: boolean = false
  @State showInputSheet: boolean = false
  @State activeFragmentId: string = ''
  @State activeCommunityKey: string = ''
  @State expandedCommunityKeys: string[] = []
  @State draftContent: string = ''
  @State draftTag: string = ''
  @State draftRemind: ReminderPreference = ReminderPreference.COMMUTE
  @State fragmentSearchQuery: string = ''
  @State shareEnabled: boolean = false
  @State shareChoiceMade: boolean = false
  @State inputErrorText: string = ''
  @State toastText: string = ''
  @State showToast: boolean = false
  @State activeGraphNodeKey: string = ''
  @State archivedFragments: FragmentItem[] = []
  @State fragmentRelations: FragmentRelation[] = []
  @State showPrivacyExplainer: boolean = false
  @State databaseReady: boolean = false
  @State editingFragmentId: string = ''
  @State showArchivedList: boolean = false
  @State showLifecycleConfirm: boolean = false
  @State pendingLifecycleAction: FragmentLifecycleAction = FragmentLifecycleAction.NONE
  @State pendingLifecycleFragmentId: string = ''
  @State showAiSettings: boolean = false
  @State aiGatewayBaseUrl: string = ''
  @State aiGatewayToken: string = ''
  @State aiSettingsStatus: string = ''
  @State aiProcessingEnabled: boolean = false
  @State aiRequestInFlight: boolean = false
  @State operationInProgress: boolean = false
  @State embeddings: FragmentEmbedding[] = []

  private viewModel: FragmentAppViewModel = new FragmentAppViewModel()

  @State fragments: FragmentItem[] = []
  private graphNodes: GraphNode[] = []
  private graphEdges: GraphEdge[] = []
  @State communityNodes: CommunityNode[] = []
  @State communitySaveRecords: CommunitySaveRecord[] = []
  @State echoRecords: EchoRecord[] = []
  private toastTimer: number = -1

  aboutToAppear(): void {
    this.initializePersistence()
  }

  aboutToDisappear(): void {
    if (this.toastTimer >= 0) {
      clearTimeout(this.toastTimer)
      this.toastTimer = -1
    }
  }

  private async initializePersistence(): Promise<void> {
    try {
      let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
      let snapshot: AppDataSnapshot = await this.viewModel.initialize(
        context,
        SeedData.fragments(),
        SeedData.relations()
      )
      this.fragments = snapshot.fragments
      this.archivedFragments = snapshot.archivedFragments
      this.fragmentRelations = snapshot.relations
      this.echoRecords = snapshot.echoRecords
      this.communitySaveRecords = snapshot.communitySaveRecords
      this.embeddings = snapshot.embeddings
      this.aiGatewayBaseUrl = snapshot.aiGatewayBaseUrl
      this.showPrivacyExplainer = snapshot.shouldShowPrivacyExplainer
      if (!this.selectFragmentById(this.activeFragmentId) && this.fragments.length > 0) {
        this.selectFragmentById(this.fragments[0].id)
      }
      this.rebuildCommunityNodes()
      this.hydrateDynamicGraph()
      this.databaseReady = true
      await this.surfaceDailyEchoIfNeeded()
    } catch (error) {
      this.databaseReady = false
      this.showNotice('本地数据加载失败，当前仅使用临时数据')
    }
  }

  private hydrateCommunitySaveState(): void {
    for (let i: number = 0; i < this.communityNodes.length; i++) {
      let record: CommunitySaveRecord | null =
        CommunityService.findSavedRecord(this.communitySaveRecords, this.communityNodes[i].key)
      if (record !== null) {
        this.communityNodes[i].savedFragmentId = record.savedFragmentId
        this.communityNodes[i].savedAtTimestamp = record.savedAtTimestamp
      }
    }
    this.communityNodes = this.communityNodes.slice()
  }

  private rebuildCommunityNodes(): void {
    if (this.fragments.length === 0) {
      this.communityNodes = []
      this.activeCommunityKey = ''
      this.expandedCommunityKeys = []
      return
    }
    this.communityNodes = CommunityDemoCatalog.nodes(this.currentFragment().id)
    this.hydrateCommunitySaveState()
    this.resetCommunitySelection()
  }

  private hydrateDynamicGraph(): void {
    let graph: GraphSnapshot = GraphBuilderService.build(
      this.fragments,
      this.fragmentRelations
    )
    this.graphNodes = graph.nodes
    this.graphEdges = graph.edges
    this.activeGraphNodeKey = this.graphNodeKeyByFragmentId(this.activeFragmentId)
  }

  private async surfaceDailyEchoIfNeeded(): Promise<void> {
    let candidate: EchoCandidate | null = EchoService.selectCandidate(this.fragments, this.echoRecords, Date.now())
    if (candidate === null) {
      return
    }
    let nowTimestamp: number = Date.now()
    let record: EchoRecord = new EchoRecord(
      IdService.create('echo', nowTimestamp),
      candidate.fragmentId,
      nowTimestamp,
      0,
      0,
      candidate.reason
    )
    let result: OperationResult = await this.viewModel.surfaceEcho(record)
    if (result.success) {
      this.echoRecords = this.echoRecords.concat([record])
    } else {
      this.showNotice(result.message)
    }
  }

  private async acknowledgePrivacyExplainer(): Promise<void> {
    let result: OperationResult = await this.viewModel.acknowledgePrivacyExplainer()
    if (result.success) {
      this.showPrivacyExplainer = false
    } else {
      this.showNotice(result.message)
    }
  }

  build() {
    Stack() {
      this.AppBackground()

      if (this.currentPage === AppPage.BOX) {
        this.BoxPage()
      } else if (this.currentPage === AppPage.COLLECTION) {
        this.CollectionPage()
      } else {
        this.CommunityPage()
      }

      this.PageDots()

      if (this.showToast) {
        this.Toast()
      }

      if (this.showPrivacyExplainer) {
        PrivacyExplainer({
          onAcknowledge: (): void => {
            this.acknowledgePrivacyExplainer()
          }
        })
      }

      if (this.showLifecycleConfirm) {
        LifecycleConfirmDialog({
          title: this.lifecycleConfirmTitle(),
          action: this.pendingLifecycleAction,
          disabled: this.operationInProgress,
          onCancel: (): void => {
            this.showLifecycleConfirm = false
          },
          onConfirm: (): void => {
            this.confirmLifecycleAction()
          }
        })
      }

      if (this.showAiSettings) {
        this.AiSettingsOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BoxStyle.PAGE_BG)
    .blur(this.showInputSheet ? 2 : 0)
    .bindSheet($$this.showInputSheet, this.InputSheetContent(), {
      height: 720,
      showClose: false,
      dragBar: false,
      backgroundColor: '#FBFAF6'
    })
    .animation({ duration: BoxStyle.MOTION_BASE, curve: Curve.EaseOut })
    .parallelGesture(
      PanGesture({ direction: PanDirection.Horizontal, distance: 18 })
        .onActionEnd((event: GestureEvent) => {
          this.handlePan(event.offsetX, event.offsetY)
        })
    )
  }

  private currentFragment(): FragmentItem {
    if (this.fragments.length === 0) {
      return this.emptyFragment()
    }
    return this.fragments[this.currentFragmentIndex()]
  }

  private fragmentIndexById(id: string): number {
    for (let i: number = 0; i < this.fragments.length; i++) {
      if (this.fragments[i].id === id) {
        return i
      }
    }
    return -1
  }

  private currentFragmentIndex(): number {
    let index: number = this.fragmentIndexById(this.activeFragmentId)
    return index >= 0 ? index : 0
  }

  private selectFragmentById(id: string): boolean {
    if (this.fragmentIndexById(id) >= 0) {
      this.activeFragmentId = id
      this.activeGraphNodeKey = this.graphNodeKeyByFragmentId(id)
      return true
    }
    if (this.fragments.length > 0) {
      this.activeFragmentId = this.fragments[0].id
      this.activeGraphNodeKey = this.graphNodeKeyByFragmentId(this.activeFragmentId)
    }
    return false
  }

  private fragmentAtOffset(delta: number): FragmentItem {
    if (this.fragments.length === 0) {
      return this.emptyFragment()
    }
    return this.fragments[(this.currentFragmentIndex() + delta + this.fragments.length) % this.fragments.length]
  }

  // 顶层手势：横向切换三页；在个人碎片页纵向切换碎片。
  private handlePan(offsetX: number, offsetY: number): void {
    if (this.showInputSheet || this.showAiSettings ||
      this.showPrivacyExplainer || this.showLifecycleConfirm) {
      return
    }
    if (Math.abs(offsetX) > Math.abs(offsetY) && Math.abs(offsetX) > 56) {
      if (offsetX < 0) {
        this.goNextPage()
      } else {
        this.goPreviousPage()
      }
      return
    }
  }

  private goNextPage(): void {
    if (this.currentPage === AppPage.BOX) {
      this.currentPage = AppPage.COLLECTION
      return
    }
    if (this.currentPage === AppPage.COLLECTION) {
      if (!this.prepareCommunityEntry()) {
        return
      }
      this.graphMode = false
      this.currentPage = AppPage.COMMUNITY
    }
  }

  private goPreviousPage(): void {
    if (this.currentPage === AppPage.COMMUNITY) {
      this.resetCommunitySelection()
      this.currentPage = AppPage.COLLECTION
      return
    }
    if (this.currentPage === AppPage.COLLECTION) {
      this.graphMode = false
      this.currentPage = AppPage.BOX
    }
  }

  private moveFragment(delta: number): void {
    let count: number = this.fragments.length
    if (count === 0) {
      return
    }
    let nextIndex: number = (this.currentFragmentIndex() + delta + count) % count
    this.selectFragmentById(this.fragments[nextIndex].id)
    this.rebuildCommunityNodes()
  }

  private filteredFragments(): FragmentItem[] {
    let keyword: string = this.fragmentSearchQuery.trim().toLowerCase()
    if (keyword.length === 0) {
      return this.fragments
    }
    return this.fragments.filter((item: FragmentItem) => {
      return item.id.toLowerCase().indexOf(keyword) >= 0 ||
        item.tag.toLowerCase().indexOf(keyword) >= 0 ||
        item.text.toLowerCase().indexOf(keyword) >= 0
    })
  }

  private sharedFragments(): FragmentItem[] {
    return this.fragments.filter((item: FragmentItem) => item.shared)
  }

  private prepareCommunityEntry(): boolean {
    if (this.fragments.length === 0) {
      this.showNotice('先放入一张碎片，再去社区延伸')
      return false
    }
    if (CommunityService.canUseAsCommunityRoot(this.currentFragment())) {
      this.rebuildCommunityNodes()
      return true
    }
    for (let i: number = 0; i < this.fragments.length; i++) {
      if (CommunityService.canUseAsCommunityRoot(this.fragments[i])) {
        this.selectFragmentById(this.fragments[i].id)
        this.rebuildCommunityNodes()
        this.showNotice('已切换到一张允许匿名共享的碎片')
        return true
      }
    }
    this.showNotice('没有可共享碎片，请先在放入时选择匿名共享')
    return false
  }

  private emptyFragment(): FragmentItem {
    return new FragmentItem({
      id: 'empty',
      displayCode: '--',
      tag: '空 Box',
      text: '还没有碎片。',
      tone: 'self',
      remind: ReminderPreference.NONE,
      visibility: FragmentVisibility.PRIVATE,
      createdAt: '',
      createdAtTimestamp: Date.now()
    })
  }

  private isEchoEligible(item: FragmentItem): boolean {
    return EchoService.isEligible(item, this.echoRecords, Date.now())
  }

  private fragmentDateLabel(item: FragmentItem): string {
    return DateUtils.relativeLabel(item.createdAtTimestamp)
  }

  private echoFragmentIndex(): number {
    let nowTimestamp: number = Date.now()
    for (let i: number = 0; i < this.echoRecords.length; i++) {
      let record: EchoRecord = this.echoRecords[i]
      if (record.surfacedAtTimestamp > 0 &&
        record.dismissedUntilTimestamp <= nowTimestamp &&
        DateUtils.isSameLocalDay(record.surfacedAtTimestamp, nowTimestamp)) {
        return this.fragmentIndexById(record.fragmentId)
      }
    }
    let candidate: EchoCandidate | null = EchoService.selectCandidate(this.fragments, this.echoRecords, Date.now())
    if (candidate === null) {
      return -1
    }
    return this.fragmentIndexById(candidate.fragmentId)
  }

  private openEchoFragment(item: FragmentItem): void {
    this.markEchoOpened(item.id)
    this.selectFragmentById(item.id)
    this.graphMode = false
    this.currentPage = AppPage.COLLECTION
  }

  private async markEchoOpened(fragmentId: string): Promise<void> {
    for (let i: number = 0; i < this.echoRecords.length; i++) {
      let record: EchoRecord = this.echoRecords[i]
      if (record.fragmentId === fragmentId && record.openedAtTimestamp === 0) {
        let result: OperationResult = await this.viewModel.openEcho(record.id)
        if (result.success) {
          record.openedAtTimestamp = Date.now()
          this.echoRecords = this.echoRecords.slice()
        } else {
          this.showNotice(result.message)
        }
        return
      }
    }
  }

  private echoReason(fragmentId: string): string {
    for (let i: number = 0; i < this.echoRecords.length; i++) {
      if (this.echoRecords[i].fragmentId === fragmentId &&
        DateUtils.isSameLocalDay(this.echoRecords[i].surfacedAtTimestamp, Date.now())) {
        return this.echoRecords[i].reason
      }
    }
    return '在合适的时刻重新看见'
  }

  private async dismissEcho(fragmentId: string): Promise<void> {
    for (let i: number = 0; i < this.echoRecords.length; i++) {
      let record: EchoRecord = this.echoRecords[i]
      if (record.fragmentId === fragmentId &&
        DateUtils.isSameLocalDay(record.surfacedAtTimestamp, Date.now())) {
        let dismissedUntilTimestamp: number = Date.now() + DateUtils.DAY_MS
        let result: OperationResult =
          await this.viewModel.dismissEcho(record.id, dismissedUntilTimestamp)
        if (result.success) {
          record.dismissedUntilTimestamp = dismissedUntilTimestamp
          this.echoRecords = this.echoRecords.slice()
          this.showNotice('这张回响今天先安静一下')
        } else {
          this.showNotice(result.message)
        }
        return
      }
    }
  }

  private openInputSheet(): void {
    this.editingFragmentId = ''
    this.inputErrorText = ''
    this.aiProcessingEnabled = false
    this.showInputSheet = true
  }

  private closeInputSheet(): void {
    this.editingFragmentId = ''
    this.inputErrorText = ''
    this.aiProcessingEnabled = false
    this.showInputSheet = false
  }

  private saveDraftFragment(): void {
    if (this.operationInProgress) {
      return
    }
    if (!this.databaseReady) {
      this.showNotice('本地数据还在准备，请稍等一下')
      return
    }
    let content: string = this.draftContent.trim()
    if (content.length === 0) {
      this.inputErrorText = '请先写下碎片内容'
      this.showNotice('碎片内容不能为空')
      return
    }
    if (content.length > 500) {
      this.inputErrorText = '一张碎片最多 500 字'
      this.showNotice('内容太长，可以拆成两张碎片')
      return
    }
    if (!this.shareChoiceMade) {
      this.inputErrorText = '请选择可见范围'
      this.showNotice('请先选择可见范围')
      return
    }

    let tag: string = this.draftTag.trim()
    let archivedShared: boolean = this.shareEnabled
    if (tag.length === 0) {
      tag = '未命名碎片'
    }
    let previousId: string = this.fragments.length > 0 ? this.currentFragment().id : ''
    let nextId: string = this.nextFragmentId()
    let visibility: FragmentVisibility = this.shareEnabled ?
      FragmentVisibility.COMMUNITY : FragmentVisibility.PRIVATE
    if (this.editingFragmentId.length > 0) {
      this.persistEditedFragment(tag, content, visibility)
      return
    }
    if (this.aiProcessingEnabled && !this.isAiConfigReady()) {
      this.inputErrorText = '请先在 Box 顶部配置幕后整理地址和本次访问口令'
      this.showNotice('幕后整理还没配好，草稿没有丢')
      return
    }
    let item: FragmentItem = new FragmentItem({
      id: nextId,
      displayCode: '',
      tag: tag,
      text: content,
      tone: 'self',
      remind: this.draftRemind,
      visibility: visibility,
      createdAt: '今天',
      createdAtTimestamp: Date.now()
    })
    let relation: FragmentRelation | null = previousId.length > 0 ?
      RelationService.create(previousId, item.id, 'created_after') : null
    this.persistNewFragment(item, relation, archivedShared)
  }

  private async persistNewFragment(
    item: FragmentItem,
    relation: FragmentRelation | null,
    archivedShared: boolean
  ): Promise<void> {
    if (this.operationInProgress) {
      return
    }
    this.operationInProgress = true
    let shouldProcessWithAi: boolean = this.aiProcessingEnabled
    try {
      let result: OperationResult = await this.viewModel.createFragment(item, relation)
      if (!result.success) {
        this.inputErrorText = result.message
        this.showNotice(result.message)
        return
      }
      this.fragments = this.fragments.concat([item])
      if (relation !== null) {
        this.fragmentRelations = this.fragmentRelations.concat([relation])
      }
      this.selectFragmentById(item.id)
      this.rebuildCommunityNodes()
      this.hydrateDynamicGraph()
      this.draftContent = ''
      this.draftTag = ''
      this.inputErrorText = ''
      this.shareEnabled = false
      this.shareChoiceMade = false
      this.aiProcessingEnabled = false
      this.showInputSheet = false
      this.showNotice(archivedShared ? '已放入 Box · 匿名共享' : '已放入 Box · 仅自己可见')
      if (shouldProcessWithAi) {
        this.processFragmentWithAi(item)
      }
    } finally {
      this.operationInProgress = false
    }
  }

  private async persistEditedFragment(
    tag: string,
    content: string,
    visibility: FragmentVisibility
  ): Promise<void> {
    if (this.operationInProgress) {
      return
    }
    this.operationInProgress = true
    let shouldProcessWithAi: boolean = this.aiProcessingEnabled
    try {
      let index: number = this.fragmentIndexById(this.editingFragmentId)
      if (index < 0) {
        this.showNotice('要编辑的碎片已经不存在')
        return
      }
      let original: FragmentItem = this.fragments[index]
      let updated: FragmentItem = new FragmentItem({
      id: original.id,
      displayCode: original.displayCode,
      tag: tag,
      text: content,
      tone: original.tone,
      remind: this.draftRemind,
      visibility: visibility,
      createdAt: original.createdAt,
      createdAtTimestamp: original.createdAtTimestamp,
      updatedAtTimestamp: Date.now(),
      archivedAtTimestamp: original.archivedAtTimestamp,
      sourceCommunityNodeId: original.sourceCommunityNodeId,
      moderationStatus: original.moderationStatus
      })
      let result: OperationResult = await this.viewModel.updateFragment(updated)
      if (!result.success) {
        this.inputErrorText = result.message
        this.showNotice(result.message)
        return
      }
      let nextFragments: FragmentItem[] = this.fragments.slice()
      nextFragments[index] = updated
      this.fragments = nextFragments
      this.rebuildCommunityNodes()
      this.hydrateDynamicGraph()
      this.editingFragmentId = ''
      this.showInputSheet = false
      this.aiProcessingEnabled = false
      this.inputErrorText = ''
      this.showNotice(result.message)
      if (shouldProcessWithAi) {
        this.processFragmentWithAi(updated)
      }
    } finally {
      this.operationInProgress = false
    }
  }

  private editFragment(item: FragmentItem): void {
    this.editingFragmentId = item.id
    this.draftContent = item.text
    this.draftTag = item.tag
    this.draftRemind = item.remind
    this.shareEnabled = item.visibility === FragmentVisibility.COMMUNITY
    this.shareChoiceMade = true
    this.aiProcessingEnabled = false
    this.inputErrorText = ''
    this.showInputSheet = true
  }

  private requestLifecycle(action: FragmentLifecycleAction, fragmentId: string): void {
    if (this.operationInProgress) {
      return
    }
    this.pendingLifecycleAction = action
    this.pendingLifecycleFragmentId = fragmentId
    this.showLifecycleConfirm = true
  }

  private lifecycleConfirmTitle(): string {
    if (this.pendingLifecycleAction === FragmentLifecycleAction.ARCHIVE) {
      return '把这张碎片移入归档箱？'
    }
    if (this.pendingLifecycleAction === FragmentLifecycleAction.RESTORE) {
      return '恢复这张碎片？'
    }
    if (this.pendingLifecycleAction === FragmentLifecycleAction.REVOKE) {
      return '撤回这张碎片的社区共享？'
    }
    return '永久删除这张碎片？'
  }

  private async confirmLifecycleAction(): Promise<void> {
    if (this.operationInProgress) {
      return
    }
    this.operationInProgress = true
    let action: FragmentLifecycleAction = this.pendingLifecycleAction
    let fragmentId: string = this.pendingLifecycleFragmentId
    this.showLifecycleConfirm = false
    try {
      let result: OperationResult
      if (action === FragmentLifecycleAction.ARCHIVE) {
        result = await this.viewModel.archiveFragment(fragmentId)
      } else if (action === FragmentLifecycleAction.RESTORE) {
        result = await this.viewModel.restoreFragment(fragmentId)
      } else if (action === FragmentLifecycleAction.REVOKE) {
        result = await this.viewModel.revokeSharing(fragmentId)
      } else {
        result = await this.viewModel.deleteFragment(fragmentId)
      }
      if (!result.success) {
        this.showNotice(result.message)
        return
      }
      let snapshot: AppDataSnapshot = await this.viewModel.loadSnapshot()
      this.fragments = snapshot.fragments
      this.archivedFragments = snapshot.archivedFragments
      this.fragmentRelations = snapshot.relations
      this.communitySaveRecords = snapshot.communitySaveRecords
      this.embeddings = snapshot.embeddings
      this.hydrateDynamicGraph()
      if (this.fragments.length > 0) {
        this.selectFragmentById(this.fragments[0].id)
      } else {
        this.activeFragmentId = ''
      }
      this.rebuildCommunityNodes()
      this.pendingLifecycleAction = FragmentLifecycleAction.NONE
      this.pendingLifecycleFragmentId = ''
      this.showNotice(result.message)
    } catch (error) {
      this.showNotice('本地状态刷新失败，请稍后重试')
    } finally {
      this.operationInProgress = false
    }
  }

  private filteredArchivedFragments(): FragmentItem[] {
    let keyword: string = this.fragmentSearchQuery.trim().toLowerCase()
    if (keyword.length === 0) {
      return this.archivedFragments
    }
    return this.archivedFragments.filter((item: FragmentItem) => {
      return item.displayCode.toLowerCase().indexOf(keyword) >= 0 ||
        item.tag.toLowerCase().indexOf(keyword) >= 0 ||
        item.text.toLowerCase().indexOf(keyword) >= 0
    })
  }

  private relatedFragments(): FragmentItem[] {
    let relatedIds: string[] = RelationService.relatedFragmentIds(
      this.currentFragment().id,
      this.fragmentRelations
    )
    let related: FragmentItem[] = []
    for (let i: number = 0; i < relatedIds.length; i++) {
      let index: number = this.fragmentIndexById(relatedIds[i])
      if (index >= 0) {
        related.push(this.fragments[index])
      }
    }
    return related
  }

  private isAiConfigReady(): boolean {
    return this.aiGatewayBaseUrl.trim().startsWith('https://') &&
      this.aiGatewayToken.trim().length >= 16
  }

  private openAiSettings(): void {
    this.aiSettingsStatus = ''
    this.showAiSettings = true
  }

  private async saveAndTestAiSettings(): Promise<void> {
    let baseUrl: string = this.aiGatewayBaseUrl.trim()
    if (!baseUrl.startsWith('https://')) {
      this.aiSettingsStatus = '地址必须使用 HTTPS'
      return
    }
    if (this.aiGatewayToken.trim().length < 16) {
      this.aiSettingsStatus = '请输入至少 16 位的网关访问口令'
      return
    }
    this.aiSettingsStatus = '正在检测网关…'
    try {
      let reachable: boolean = await AiGatewayService.testConnection(baseUrl)
      if (!reachable) {
        this.aiSettingsStatus = '网关没有正确响应，请检查地址'
        return
      }
      let result: OperationResult = await this.viewModel.saveAiGatewayBaseUrl(baseUrl)
      if (!result.success) {
        this.aiSettingsStatus = result.message
        return
      }
      this.aiGatewayBaseUrl = baseUrl
      this.aiSettingsStatus = '连接正常，访问口令仅保留到本次退出'
      this.showNotice('幕后整理网关已就绪')
    } catch (error) {
      this.aiSettingsStatus = '连接失败，请检查网络和网关地址'
    }
  }

  private async restoreDemoData(): Promise<void> {
    if (this.operationInProgress || !this.databaseReady) {
      return
    }
    this.operationInProgress = true
    try {
      let result: OperationResult = await this.viewModel.restoreDemoData(
        SeedData.fragments(),
        SeedData.relations()
      )
      if (!result.success) {
        this.showNotice(result.message)
        return
      }
      let snapshot: AppDataSnapshot = await this.viewModel.loadSnapshot()
      this.fragments = snapshot.fragments
      this.archivedFragments = snapshot.archivedFragments
      this.fragmentRelations = snapshot.relations
      this.communitySaveRecords = snapshot.communitySaveRecords
      this.echoRecords = snapshot.echoRecords
      this.embeddings = snapshot.embeddings
      if (this.fragments.length > 0) {
        this.selectFragmentById(this.fragments[0].id)
      }
      this.rebuildCommunityNodes()
      this.hydrateDynamicGraph()
      this.showNotice(result.message)
    } finally {
      this.operationInProgress = false
    }
  }

  private async processFragmentWithAi(fragment: FragmentItem): Promise<void> {
    this.aiRequestInFlight = true
    try {
      let consentResult: OperationResult =
        await this.viewModel.grantAiProcessingConsent(fragment.id)
      if (!consentResult.success) {
        this.showNotice(consentResult.message)
        return
      }
      let gatewayResult: AiGatewayResult = await AiGatewayService.analyze(
        this.aiGatewayBaseUrl,
        this.aiGatewayToken,
        fragment
      )
      let match: SimilarFragmentMatch | null =
        AiSimilarityService.bestMatch(gatewayResult.embedding, this.embeddings)
      let related: FragmentRelation | null = null
      if (match !== null) {
        related = new FragmentRelation(
          'ai-semantic-' + fragment.id,
          match.fragmentId,
          fragment.id,
          'semantic_ai',
          Date.now()
        )
      }
      let enhanced: FragmentItem = this.aiEnhancedFragment(fragment, gatewayResult)
      let saveResult: OperationResult =
        await this.viewModel.saveAiProcessingResult(enhanced, gatewayResult, related)
      if (!saveResult.success) {
        this.showNotice(saveResult.message)
        return
      }
      let index: number = this.fragmentIndexById(fragment.id)
      if (index >= 0) {
        let nextFragments: FragmentItem[] = this.fragments.slice()
        nextFragments[index] = enhanced
        this.fragments = nextFragments
      }
      this.embeddings = this.embeddings
        .filter((item: FragmentEmbedding) => item.fragmentId !== fragment.id)
        .concat([gatewayResult.embedding])
      if (related !== null) {
        this.fragmentRelations = this.fragmentRelations
          .filter((item: FragmentRelation) => item.id !== related!.id)
          .concat([related])
      }
      this.hydrateDynamicGraph()
      this.showNotice('幕后整理完成 · ' + gatewayResult.analysis.summary)
    } catch (error) {
      this.showNotice('已安全保存在本机，幕后整理稍后再试')
    } finally {
      this.aiRequestInFlight = false
    }
  }

  private aiEnhancedFragment(
    fragment: FragmentItem,
    result: AiGatewayResult
  ): FragmentItem {
    let tag: string = fragment.tag
    if (tag === '未命名碎片' && result.analysis.normalizedTag.length > 0) {
      tag = result.analysis.normalizedTag
    }
    let reminder: ReminderPreference = fragment.remind
    if (reminder === ReminderPreference.NONE) {
      reminder = AiGatewayService.reminderFromCode(
        result.analysis.suggestedReminder,
        fragment.remind
      )
    }
    return new FragmentItem({
      id: fragment.id,
      displayCode: fragment.displayCode,
      tag: tag,
      text: fragment.text,
      tone: result.analysis.tone,
      remind: reminder,
      visibility: fragment.visibility,
      createdAt: fragment.createdAt,
      createdAtTimestamp: fragment.createdAtTimestamp,
      updatedAtTimestamp: Date.now(),
      archivedAtTimestamp: fragment.archivedAtTimestamp,
      sourceCommunityNodeId: fragment.sourceCommunityNodeId,
      moderationStatus: fragment.moderationStatus
    })
  }

  private nextFragmentId(): string {
    return IdService.create('fragment')
  }

  private graphNodeKeyByFragmentId(fragmentId: string): string {
    for (let i: number = 0; i < this.graphNodes.length; i++) {
      if (this.graphNodes[i].fragmentId === fragmentId) {
        return this.graphNodes[i].key
      }
    }
    return ''
  }

  private showNotice(message: string): void {
    this.toastText = message
    this.showToast = true
    if (this.toastTimer >= 0) {
      clearTimeout(this.toastTimer)
    }
    this.toastTimer = setTimeout(() => {
      this.showToast = false
      this.toastTimer = -1
    }, 1500)
  }

  private childrenOf(key: string): CommunityNode[] {
    return this.communityNodes.filter((item: CommunityNode) => item.parent === key)
  }

  private getCommunityNode(key: string): CommunityNode {
    for (let i: number = 0; i < this.communityNodes.length; i++) {
      if (this.communityNodes[i].key === key) {
        return this.communityNodes[i]
      }
    }
    if (this.communityNodes.length > 0) {
      return this.communityNodes[0]
    }
    return new CommunityNode('', '', '当前碎片', '当前碎片', '我的 Box', '延申起点', '', 'root', 0, 0, 0, 0)
  }

  private communityRootKey(): string {
    if (this.communityNodes.length === 0) {
      return ''
    }
    return this.communityNodes[0].key
  }

  private resetCommunitySelection(): void {
    let rootKey: string = this.communityRootKey()
    this.activeCommunityKey = rootKey
    this.expandedCommunityKeys = rootKey.length > 0 ? [rootKey] : []
  }

  private selectCommunityNode(key: string): void {
    this.activeCommunityKey = key
    if (this.childrenOf(key).length === 0 && key !== this.communityRootKey()) {
      let branches: CommunityNode[] = this.createCommunityBranches(key)
      for (let i: number = 0; i < branches.length; i++) {
        let record: CommunitySaveRecord | null =
          CommunityService.findSavedRecord(this.communitySaveRecords, branches[i].key)
        if (record !== null) {
          branches[i].savedFragmentId = record.savedFragmentId
          branches[i].savedAtTimestamp = record.savedAtTimestamp
        }
      }
      this.communityNodes = this.communityNodes.concat(branches)
    }
    this.expandedCommunityKeys = this.communityPathKeys(key)
  }

  private communityPathKeys(key: string): string[] {
    let path: string[] = []
    let currentKey: string = key
    while (currentKey.length > 0) {
      path.unshift(currentKey)
      let node: CommunityNode = this.getCommunityNode(currentKey)
      currentKey = node.parent
    }
    let rootKey: string = this.communityRootKey()
    if (rootKey.length > 0 && path.indexOf(rootKey) < 0) {
      path.unshift(rootKey)
    }
    return path
  }

  private createCommunityBranches(parentKey: string): CommunityNode[] {
    let parent: CommunityNode = this.getCommunityNode(parentKey)
    let rootFragmentId: string = this.currentFragment().id
    let similarText: string =
      '换一个生活场景看，问题也许不是社交本身，而是节奏被打断。'
    let oppositeText: string =
      '它也许不该被马上解决，只是需要被另一种方式看见。'
    return [
      new CommunityNode(
        StableCommunityNodeIdService.create(
          rootFragmentId, parentKey, 'similar', similarText, 'anonymous'
        ),
        parentKey, '相似分支', parent.tag, '匿名共享', '相似经验',
        similarText, 'slate', 0, 0, 0, 0
      ),
      new CommunityNode(
        StableCommunityNodeIdService.create(
          rootFragmentId, parentKey, 'opposite', oppositeText, 'boxer'
        ),
        parentKey, '反向视角', parent.tag, 'BOXer', '相反经验',
        oppositeText, 'rose', 0, 0, 0, 0
      )
    ]
  }

  private saveActiveCommunityFragment(): void {
    if (this.operationInProgress) {
      return
    }
    if (!this.databaseReady) {
      this.showNotice('本地数据还在准备，请稍等一下')
      return
    }
    if (this.activeCommunityKey === this.communityRootKey()) {
      this.showNotice('这张碎片已经在你的 Box 里')
      return
    }

    let node: CommunityNode = this.getCommunityNode(this.activeCommunityKey)
    let existing: CommunitySaveRecord | null =
      CommunityService.findSavedRecord(this.communitySaveRecords, node.key)
    if (existing !== null || node.savedFragmentId.length > 0) {
      this.showNotice('这条社区碎片已经收进 Box 了')
      return
    }

    let previousId: string = this.currentFragment().id
    let nowTimestamp: number = Date.now()
    let item: FragmentItem = CommunityService.createPrivateCopy(
      node,
      nowTimestamp
    )
    let saveRecord: CommunitySaveRecord = new CommunitySaveRecord(node.key, item.id, nowTimestamp)
    let relation: FragmentRelation = RelationService.create(previousId, item.id, 'saved_from_community', nowTimestamp)
    this.persistCommunityCopy(node, item, relation, saveRecord)
  }

  private async persistCommunityCopy(
    node: CommunityNode,
    item: FragmentItem,
    relation: FragmentRelation,
    saveRecord: CommunitySaveRecord
  ): Promise<void> {
    if (this.operationInProgress) {
      return
    }
    this.operationInProgress = true
    try {
      let result: OperationResult =
        await this.viewModel.saveCommunityCopy(item, relation, saveRecord)
      if (!result.success) {
        this.showNotice(result.message)
        return
      }
      this.fragments = this.fragments.concat([item])
      this.fragmentRelations = this.fragmentRelations.concat([relation])
      this.communitySaveRecords = this.communitySaveRecords.concat([saveRecord])
      node.savedFragmentId = item.id
      node.savedAtTimestamp = saveRecord.savedAtTimestamp
      this.selectFragmentById(item.id)
      this.hydrateDynamicGraph()
      this.currentPage = AppPage.COLLECTION
      this.graphMode = false
      this.rebuildCommunityNodes()
      this.showNotice(result.message)
    } finally {
      this.operationInProgress = false
    }
  }

  private continueFromActiveCommunityFragment(): void {
    let tag: string = this.currentFragment().tag
    if (this.activeCommunityKey !== this.communityRootKey()) {
      tag = this.getCommunityNode(this.activeCommunityKey).tag
    }
    this.draftContent = ''
    this.draftTag = tag
    this.draftRemind = ReminderPreference.WEEKEND
    this.shareEnabled = false
    this.shareChoiceMade = false
    this.inputErrorText = ''
    this.showInputSheet = true
  }

  private waterfallActiveFragmentId(firstIndex: number, lastIndex: number, centerIndex?: number): string {
    if (this.fragments.length === 0) {
      return ''
    }

    // List item 0 is the top spacer and real fragments start from item 1.
    // Prefer ArkUI's centerIndex so the card at the visual center becomes black,
    // including 02 / 03 / 05. Fallback to visible midpoint for older runtimes.
    let activeListIndex: number = 1
    if (centerIndex !== undefined && centerIndex >= 1 && centerIndex <= this.fragments.length) {
      activeListIndex = centerIndex
    } else {
      activeListIndex = Math.round((firstIndex + lastIndex) / 2)
    }

    if (activeListIndex < 1) {
      activeListIndex = 1
    }
    if (activeListIndex > this.fragments.length) {
      activeListIndex = this.fragments.length
    }
    return this.fragments[activeListIndex - 1].id
  }

  @Builder
  AppBackground() {
    Stack() {
      // 纸面颗粒与极淡轨道，承担统一视觉质感，不参与交互。
      Circle()
        .width(420)
        .height(420)
        .fill('rgba(255, 255, 255, 0.36)')
        .stroke('rgba(196, 199, 190, 0.38)')
        .strokeWidth(1)
        .position({ x: -238, y: 250 })

      Circle()
        .width(250)
        .height(250)
        .fill('rgba(104, 114, 103, 0.10)')
        .position({ x: 210, y: 382 })

      Circle()
        .width(230)
        .height(230)
        .fill('rgba(255, 255, 255, 0.54)')
        .position({ x: 88, y: 130 })

      Circle().width(4).height(4).fill('rgba(48, 50, 49, 0.12)').position({ x: 70, y: 88 })
      Circle().width(3).height(3).fill('rgba(48, 50, 49, 0.08)').position({ x: 245, y: 118 })
      Circle().width(5).height(5).fill('rgba(48, 50, 49, 0.10)').position({ x: 112, y: 308 })
      Circle().width(3).height(3).fill('rgba(48, 50, 49, 0.08)').position({ x: 306, y: 510 })
      Circle().width(5).height(5).fill('rgba(48, 50, 49, 0.09)').position({ x: 52, y: 648 })
      Circle().width(3).height(3).fill('rgba(48, 50, 49, 0.07)').position({ x: 268, y: 692 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  BrandBadge() {
    Text('BOX')
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor('#F8F7F1')
      .letterSpacing(3)
      .height(38)
      .lineHeight(38)
      .padding({ left: 15, right: 15 })
      .backgroundColor('#232620')
      .border({ width: 1, color: 'rgba(35, 38, 32, 0.18)' })
      .borderRadius(19)
      .shadow({ radius: 16, color: 'rgba(35, 38, 32, 0.14)', offsetX: 0, offsetY: 7 })
  }

  @Builder
  BoxPage() {
    Stack() {
      Column() {
        Row() {
          Blank()

          Button(this.aiRequestInFlight ? '整理中…' : '幕后整理')
            .height(36)
            .fontSize(12)
            .fontColor(BoxStyle.TEXT_SOFT)
            .backgroundColor('rgba(255, 255, 255, 0.72)')
            .border({ width: 1, color: BoxStyle.HAIRLINE })
            .borderRadius(18)
            .enabled(!this.aiRequestInFlight)
            .onClick(() => {
              this.openAiSettings()
            })
        }
        .width('100%')
        .height(38)

        Blank()

        Column() {
          this.BoxArt()

          Text('记录碎片')
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
            .fontColor(BoxStyle.TEXT)
            .letterSpacing(2)
            .margin({ top: 34 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('A quiet place for stray thoughts')
            .fontSize(12)
            .fontColor('#7D837B')
            .letterSpacing(0.2)
            .margin({ top: 9 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.openInputSheet()
        })

        this.BoxEchoPanel()

        Blank()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 26, right: 26, top: 42, bottom: 88 })
  }

  @Builder
  BoxEchoPanel() {
    if (this.echoFragmentIndex() >= 0) {
      EchoCard({
        item: this.fragments[this.echoFragmentIndex()],
        dateLabel: this.fragmentDateLabel(this.fragments[this.echoFragmentIndex()]),
        reason: this.echoReason(this.fragments[this.echoFragmentIndex()].id),
        onOpen: (): void => {
          this.openEchoFragment(this.fragments[this.echoFragmentIndex()])
        },
        onDismiss: (): void => {
          this.dismissEcho(this.fragments[this.echoFragmentIndex()].id)
        }
      })
    } else {
      Row() {
        Circle()
          .width(7)
          .height(7)
          .fill('rgba(119, 125, 118, 0.32)')

        Text('旧碎片正在安静等待合适的提醒时刻')
          .fontSize(12)
          .fontColor(BoxStyle.TEXT_MUTED)
          .margin({ left: 9 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
      .margin({ top: 24 })
    }
  }

  @Builder
  BoxArt() {
    Stack({ alignContent: Alignment.Center }) {
      Ellipse()
        .width(258)
        .height(38)
        .fill('rgba(34, 37, 32, 0.18)')
        .blur(13)
        .translate({ y: 108 })

      Stack({ alignContent: Alignment.Center }) {
        // A single paper puzzle piece: direct fragment metaphor, no box or note props.
        Path({ width: 286, height: 286, commands: 'M82 54 L124 54 C124 34 140 20 158 20 C176 20 192 34 192 54 L236 54 C248 54 258 64 258 76 L258 124 C236 124 222 140 222 158 C222 176 236 192 258 192 L258 236 C258 248 248 258 236 258 L190 258 C190 236 174 222 156 222 C138 222 122 236 122 258 L82 258 C70 258 60 248 60 236 L60 190 C38 190 24 174 24 156 C24 138 38 122 60 122 L60 76 C60 64 70 54 82 54 Z' })
          .fill('#EFE4BC')
          .stroke('rgba(35, 38, 32, 0.24)')
          .strokeWidth(1.5)
          .shadow({ radius: 30, color: 'rgba(35, 38, 32, 0.18)', offsetX: 0, offsetY: 15 })

        Path({ width: 286, height: 286, commands: 'M82 54 L124 54 C124 34 140 20 158 20 C176 20 192 34 192 54 L236 54 C248 54 258 64 258 76 L258 124 C236 124 222 140 222 158 C222 176 236 192 258 192 L258 236 C258 248 248 258 236 258 L190 258 C190 236 174 222 156 222 C138 222 122 236 122 258 L82 258 C70 258 60 248 60 236 L60 190 C38 190 24 174 24 156 C24 138 38 122 60 122 L60 76 C60 64 70 54 82 54 Z' })
          .fill('rgba(255, 255, 255, 0.16)')
          .stroke('rgba(255, 255, 255, 0.12)')
          .strokeWidth(1)
          .translate({ x: -4, y: -5 })

        Rect()
          .width(100)
          .height(2)
          .radius(1)
          .fill('rgba(62, 68, 58, 0.24)')
          .translate({ x: -6, y: -22 })

        Rect()
          .width(132)
          .height(2)
          .radius(1)
          .fill('rgba(62, 68, 58, 0.18)')
          .translate({ x: 7, y: 0 })

        Rect()
          .width(86)
          .height(2)
          .radius(1)
          .fill('rgba(62, 68, 58, 0.15)')
          .translate({ x: -16, y: 22 })

        Circle()
          .width(9)
          .height(9)
          .fill('rgba(62, 72, 58, 0.24)')
          .translate({ x: 62, y: -58 })

        Circle()
          .width(6)
          .height(6)
          .fill('rgba(62, 72, 58, 0.20)')
          .translate({ x: -78, y: 58 })
      }
      .width(286)
      .height(286)
    }
    .width(336)
    .height(300)
  }

  @Builder
  CollectionPage() {
    Stack() {
      Stack() {
        this.WaterfallBackground()
      }
      .width('100%')
      .height('100%')
        .zIndex(0)

      if (!this.graphMode) {
        Stack() {
          this.WaterfallOrbitLines()
        }
        .width('100%')
        .height('100%')
          .zIndex(1)
      }

      if (this.graphMode) {
        Stack() {
          this.PersonalGraph()
        }
        .width('100%')
        .height('100%')
          .zIndex(2)
      } else {
        Stack() {
          this.FragmentWaterfallPage()
        }
        .width('100%')
        .height('100%')
          .zIndex(2)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  WaterfallBackground() {
    Stack() {
      Circle()
        .width(430)
        .height(430)
        .fill('rgba(255, 255, 255, 0.18)')
        .stroke('rgba(204, 206, 200, 0.42)')
        .strokeWidth(1)
        .position({ x: -282, y: 176 })

      Circle()
        .width(226)
        .height(226)
        .fill('rgba(255, 255, 255, 0.42)')
        .position({ x: 136, y: 166 })

      Circle()
        .width(220)
        .height(220)
        .fill('rgba(151, 161, 156, 0.07)')
        .position({ x: 238, y: 520 })

      Circle().width(5).height(5).fill('rgba(46, 48, 47, 0.12)').position({ x: 92, y: 152 })
      Circle().width(4).height(4).fill('rgba(46, 48, 47, 0.10)').position({ x: 248, y: 210 })
      Circle().width(6).height(6).fill('rgba(46, 48, 47, 0.12)').position({ x: 146, y: 386 })
      Circle().width(4).height(4).fill('rgba(46, 48, 47, 0.08)').position({ x: 306, y: 634 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  WaterfallOrbitLines() {
    Stack() {
      Circle()
        .width(470)
        .height(470)
        .fill('rgba(255, 255, 255, 0.00)')
        .stroke('rgba(199, 201, 194, 0.46)')
        .strokeWidth(1)
        .position({ x: -312, y: 276 })

      Circle()
        .width(560)
        .height(560)
        .fill('rgba(255, 255, 255, 0.00)')
        .stroke('rgba(199, 201, 194, 0.24)')
        .strokeWidth(1)
        .position({ x: -360, y: 196 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  FragmentWaterfallPage() {
    Column() {
      this.WaterfallHeader()

      TextInput({
        text: this.fragmentSearchQuery,
        placeholder: '搜索关键词、Tag 或碎片编号'
      })
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontColor(BoxStyle.TEXT)
        .placeholderColor(BoxStyle.TEXT_MUTED)
        .backgroundColor('rgba(255, 255, 255, 0.68)')
        .border({ width: 1, color: BoxStyle.HAIRLINE })
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .margin({ bottom: 10 })
        .onChange((value: string) => {
          this.fragmentSearchQuery = value
        })

      List({ space: 8 }) {
        ListItem() {
          Column() {
            Blank()
              .height(188)
          }
          .width('100%')
        }

        if (this.showArchivedList) {
          if (this.filteredArchivedFragments().length === 0) {
            ListItem() {
              Text($r('app.string.archive_empty'))
                .width('100%')
                .height(120)
                .fontSize(14)
                .fontColor(BoxStyle.TEXT_MUTED)
                .textAlign(TextAlign.Center)
            }
          } else {
            ForEach(this.filteredArchivedFragments(), (item: FragmentItem) => {
              ListItem() {
                this.ArchivedFragmentItem(item)
              }
            }, (item: FragmentItem) => item.id)
          }
        } else {
          if (this.filteredFragments().length === 0) {
            ListItem() {
              Text('没有找到对应碎片，换一个关键词试试。')
                .width('100%')
                .height(120)
                .fontSize(14)
                .fontColor(BoxStyle.TEXT_MUTED)
                .textAlign(TextAlign.Center)
            }
          } else {
            ForEach(this.filteredFragments(), (item: FragmentItem) => {
              ListItem() {
                this.FragmentWaterfallItem(item)
              }
            }, (item: FragmentItem) => item.id)
          }
        }

        ListItem() {
          Column() {
            Blank()
              .height(230)
          }
          .width('100%')
        }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .onScrollIndex((firstIndex: number, lastIndex: number, centerIndex?: number) => {
        if (!this.showArchivedList && this.fragmentSearchQuery.trim().length === 0) {
          this.selectFragmentById(this.waterfallActiveFragmentId(firstIndex, lastIndex, centerIndex))
        }
      })

      Row() {
        Blank()
        this.WaterfallHintCard()
        Blank()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 8, bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 22, right: 22, top: 50, bottom: 72 })
  }

  @Builder
  WaterfallHeader() {
    Row() {
      Column() {
        Text(this.showArchivedList ? '归档箱' : '我的碎片')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#252729')
          .letterSpacing(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.showArchivedList ? '可恢复，或永久删除' : '回看最近留下的记录')
          .fontSize(12)
          .fontColor('#9a9d97')
          .margin({ top: 7 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)

      Row({ space: 8 }) {
        Button(this.showArchivedList ? '返回' : '归档箱')
          .width(74)
          .height(40)
          .fontSize(12)
          .fontColor('#343635')
          .padding({ left: 0, right: 0 })
          .backgroundColor('rgba(255, 255, 255, 0.72)')
          .border({ width: 1, color: 'rgba(56, 58, 57, 0.08)' })
          .borderRadius(20)
          .onClick(() => {
            this.showArchivedList = !this.showArchivedList
          })

        if (!this.showArchivedList) {
          Button('关系图')
            .width(74)
            .height(40)
            .fontSize(12)
            .fontColor('#343635')
            .padding({ left: 0, right: 0 })
            .backgroundColor('rgba(255, 255, 255, 0.72)')
            .border({ width: 1, color: 'rgba(56, 58, 57, 0.08)' })
            .borderRadius(20)
            .onClick(() => {
              this.graphMode = true
            })
        }
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 24 })
  }

  @Builder
  FragmentWaterfallItem(item: FragmentItem) {
    Column() {
      Row() {
        Text(item.displayCode)
          .fontSize(item.id === this.currentFragment().id ? 68 : 56)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.id === this.currentFragment().id ? BoxStyle.TEXT : '#D4D6CF')
          .width(112)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Column() {
          Text(item.tag)
            .fontSize(item.id === this.currentFragment().id ? 19 : 16)
            .fontWeight(FontWeight.Bold)
            .fontColor(item.id === this.currentFragment().id ? BoxStyle.TEXT : '#969A94')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(item.text)
            .fontSize(15)
            .fontColor(item.id === this.currentFragment().id ? BoxStyle.TEXT_SOFT : '#A7AAA4')
            .lineHeight(24)
            .margin({ top: 8 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row() {
            Text(visibilityLabel(item.visibility))
              .fontSize(11)
              .fontColor(BoxStyle.TEXT_MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(item.remind)
              .fontSize(11)
              .fontColor(BoxStyle.TEXT_MUTED)
              .margin({ left: 16 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.fragmentDateLabel(item))
              .fontSize(11)
              .fontColor(BoxStyle.TEXT_MUTED)
              .margin({ left: 16 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .margin({ top: 12 })

          if (item.id === this.currentFragment().id) {
            Row({ space: 8 }) {
              this.LifecycleTextButton('编辑', () => {
                this.editFragment(item)
              })
              this.LifecycleTextButton('归档', () => {
                this.requestLifecycle(FragmentLifecycleAction.ARCHIVE, item.id)
              })
              if (item.visibility === FragmentVisibility.COMMUNITY) {
                this.LifecycleTextButton('撤回共享', () => {
                  this.requestLifecycle(FragmentLifecycleAction.REVOKE, item.id)
                })
              }
            }
            .margin({ top: 12 })
          }
        }
        .layoutWeight(1)
        .padding({ left: 8, right: 4 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .height(176)
      .padding({ top: 16, bottom: 16 })
    }
    .width('100%')
    .padding({ left: 10, right: 8 })
    .backgroundColor(item.id === this.currentFragment().id ? 'rgba(255, 255, 255, 0.68)' : 'rgba(255, 255, 255, 0.10)')
    .borderRadius(26)
    .border({ width: 1, color: item.id === this.currentFragment().id ? 'rgba(58, 60, 58, 0.10)' : 'rgba(255, 255, 255, 0.00)' })
    .margin({ bottom: 4 })
    .shadow({ radius: item.id === this.currentFragment().id ? 16 : 0, color: 'rgba(44, 46, 45, 0.07)', offsetX: 0, offsetY: 7 })
    .animation({ duration: BoxStyle.MOTION_FAST, curve: Curve.EaseOut })
    .onClick(() => {
      this.selectFragmentById(item.id)
    })
  }

  @Builder
  WaterfallHintCard() {
    Text('停在中间的碎片会被选中')
      .fontSize(14)
      .fontColor('#767974')
      .textAlign(TextAlign.Center)
      .width('100%')
      .height(48)
      .lineHeight(48)
      .padding({ left: 18, right: 18 })
      .backgroundColor('rgba(255, 255, 255, 0.72)')
      .border({ width: 1, color: 'rgba(56, 58, 57, 0.08)' })
      .borderRadius(26)
      .shadow({ radius: 14, color: 'rgba(44, 46, 45, 0.06)', offsetX: 0, offsetY: 7 })
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }

  @Builder
  PersonalGraph() {
    PersonalGraphView({
      nodes: this.graphNodes,
      edges: this.graphEdges,
      activeNodeKey: this.activeGraphNodeKey,
      relatedFragments: this.relatedFragments(),
      onSelectFragment: (fragmentId: string): void => {
        this.selectFragmentById(fragmentId)
      },
      onClose: (): void => {
        this.graphMode = false
      }
    })
  }

  @Builder
  CommunityPage() {
    Stack() {
      Circle()
        .width(420)
        .height(420)
        .fill('rgba(255, 255, 255, 0.24)')
        .stroke('rgba(204, 206, 200, 0.32)')
        .strokeWidth(1)
        .position({ x: -250, y: 118 })
        .zIndex(0)

      Circle()
        .width(230)
        .height(230)
        .fill('rgba(151, 161, 156, 0.07)')
        .position({ x: 224, y: 520 })
        .zIndex(0)

      Column() {
        this.TopBar('碎片社区发散', 'Community branches', false)

        Text('选择一个自己的碎片，从它开始查看别人共享出的相似、相反或行动经验。')
          .fontSize(13)
          .fontColor(BoxStyle.TEXT_MUTED)
          .lineHeight(20)
          .margin({ top: 6, bottom: 12 })
          .alignSelf(ItemAlign.Start)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        this.StartFragmentSelector()

        this.CommunityTreePanel()
      }
      .width('100%')
      .height('100%')
      .padding({ left: 24, right: 24, top: 34, bottom: 58 })
      .zIndex(2)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CommunityTreePanel() {
    CommunityTree({
      nodes: this.communityNodes,
      activeKey: this.activeCommunityKey,
      expandedKeys: this.expandedCommunityKeys,
      rootTitle: this.currentFragment().tag,
      operationInProgress: this.operationInProgress,
      onSelect: (nodeId: string): void => {
        this.selectCommunityNode(nodeId)
      },
      onSave: (): void => {
        this.saveActiveCommunityFragment()
      },
      onContinue: (): void => {
        this.continueFromActiveCommunityFragment()
      }
    })
  }

  @Builder
  StartFragmentSelector() {
    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
      ForEach(this.sharedFragments(), (item: FragmentItem) => {
        this.StartFragmentPill(item)
      }, (item: FragmentItem) => item.id)
    }
    .width('100%')
    .height(82)
    .padding({ left: 1, right: 1, top: 1, bottom: 1 })
  }

  @Builder
  StartFragmentPill(item: FragmentItem) {
    Text(item.displayCode + ' / ' + item.tag)
      .fontSize(12)
      .fontColor(item.id === this.currentFragment().id ? BoxStyle.TEXT : BoxStyle.TEXT_MUTED)
      .textAlign(TextAlign.Center)
      .height(34)
      .lineHeight(34)
      .padding({ left: 12, right: 12 })
      .backgroundColor(item.id === this.currentFragment().id ? '#FFFFFF' : 'rgba(255, 255, 255, 0.46)')
      .border({ width: 1, color: item.id === this.currentFragment().id ? 'rgba(64, 68, 64, 0.18)' : BoxStyle.HAIRLINE })
      .borderRadius(18)
      .margin({ right: 8, bottom: 8 })
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .onClick(() => {
        this.selectFragmentById(item.id)
        this.rebuildCommunityNodes()
      })
  }

  @Builder
  TopBar(title: string, subtitle: string, showGraphButton: boolean) {
    Column() {
      Row() {
        if (showGraphButton) {
          this.BrandBadge()
        } else {
          Text(title)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#353637')
        }

        Blank()

        if (showGraphButton) {
          Button(this.graphMode ? '◎' : '↘')
            .width(46)
            .height(46)
            .fontSize(21)
            .fontColor('#3f4140')
            .backgroundColor('rgba(255, 255, 255, 0.74)')
            .borderRadius(23)
            .shadow({ radius: 22, color: 'rgba(39, 40, 41, 0.10)', offsetX: 0, offsetY: 10 })
            .onClick(() => {
              this.graphMode = !this.graphMode
            })
        }
      }
      .width('100%')

      if (showGraphButton) {
        Text(title)
          .fontSize(this.graphMode ? 28 : 12)
          .fontWeight(this.graphMode ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.graphMode ? '#333536' : '#babbb6')
          .letterSpacing(this.graphMode ? 0 : 1)
          .margin({ top: this.graphMode ? 24 : 12 })
      }

      Text(subtitle)
        .fontSize(showGraphButton ? 13 : 14)
        .fontColor('#8e918b')
        .lineHeight(22)
        .margin({ top: showGraphButton ? 6 : 8 })
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
  }

  @Builder
  InputSheetContent() {
    FragmentInputSheet({
      draftContent: this.draftContent,
      draftTag: this.draftTag,
      draftRemind: this.draftRemind,
      shareEnabled: this.shareEnabled,
      shareChoiceMade: this.shareChoiceMade,
      aiProcessingEnabled: this.aiProcessingEnabled,
      inputErrorText: this.inputErrorText,
      operationInProgress: this.operationInProgress,
      onContentChange: (value: string): void => {
        this.draftContent = value
      },
      onTagChange: (value: string): void => {
        this.draftTag = value
      },
      onReminderChange: (value: ReminderPreference): void => {
        this.draftRemind = value
      },
      onShareChange: (value: boolean): void => {
        this.shareEnabled = value
        this.shareChoiceMade = true
        this.inputErrorText = ''
      },
      onAiProcessingChange: (value: boolean): void => {
        this.aiProcessingEnabled = value
        this.inputErrorText = ''
      },
      onClose: (): void => {
        this.closeInputSheet()
      },
      onSave: (): void => {
        this.saveDraftFragment()
      }
    })
  }

  @Builder
  PageDots() {
    Column() {
      Blank()
      Row() {
        Blank()
        Row() {
          this.PageDot(AppPage.BOX)
          this.PageDot(AppPage.COLLECTION)
          this.PageDot(AppPage.COMMUNITY)
        }
        .height(18)
        .padding({ left: 10, right: 3, top: 6, bottom: 6 })
        .backgroundColor('rgba(255, 255, 255, 0.50)')
        .border({ width: 1, color: 'rgba(55, 57, 55, 0.07)' })
        .borderRadius(15)
        Blank()
      }
      .width('100%')
      .margin({ bottom: 22 })
    }
    .width('100%')
    .height('100%')
    .zIndex(20)
    .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  PageDot(page: AppPage) {
    Rect()
      .width(this.currentPage === page ? 18 : 6)
      .height(6)
      .radius(3)
      .fill(this.currentPage === page ? 'rgba(35, 38, 32, 0.74)' : 'rgba(45, 47, 46, 0.15)')
      .margin({ right: 7 })
  }

  @Builder
  LifecycleTextButton(label: string, action: () => void) {
    Text(label)
      .fontSize(11)
      .fontColor(BoxStyle.TEXT_SOFT)
      .height(28)
      .lineHeight(28)
      .padding({ left: 10, right: 10 })
      .backgroundColor('rgba(232, 233, 228, 0.82)')
      .borderRadius(14)
      .onClick(action)
  }

  @Builder
  ArchivedFragmentItem(item: FragmentItem) {
    Column({ space: 12 }) {
      Row() {
        Text(item.displayCode)
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor('#B6B9B2')
          .width(66)

        Column({ space: 6 }) {
          Text(item.tag)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(BoxStyle.TEXT)
            .width('100%')
          Text(item.text)
            .fontSize(14)
            .lineHeight(21)
            .fontColor(BoxStyle.TEXT_SOFT)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .layoutWeight(1)
      }
      .width('100%')

      Row({ space: 10 }) {
        Button('恢复')
          .height(34)
          .fontSize(12)
          .fontColor(BoxStyle.TEXT)
          .backgroundColor(BoxStyle.SELECTED_SOFT)
          .borderRadius(17)
          .onClick(() => {
            this.requestLifecycle(FragmentLifecycleAction.RESTORE, item.id)
          })

        Button('永久删除')
          .height(34)
          .fontSize(12)
          .fontColor('#8F6258')
          .backgroundColor('rgba(143, 98, 88, 0.08)')
          .borderRadius(17)
          .onClick(() => {
            this.requestLifecycle(FragmentLifecycleAction.DELETE, item.id)
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor('rgba(255, 255, 255, 0.62)')
    .border({ width: 1, color: BoxStyle.HAIRLINE })
    .borderRadius(24)
    .margin({ bottom: 8 })
  }

  @Builder
  AiSettingsOverlay() {
    Stack() {
      Rect()
        .width('100%')
        .height('100%')
        .fill('rgba(30, 32, 29, 0.34)')
        .onClick(() => {
          this.showAiSettings = false
        })

      Column({ space: 16 }) {
        Row() {
          Text('幕后整理设置')
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor(BoxStyle.TEXT)

          Blank()

          Text('×')
            .width(38)
            .height(38)
            .fontSize(23)
            .fontColor(BoxStyle.TEXT_SOFT)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.showAiSettings = false
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text('应用只连接你自己的 HTTPS 网关；DeepSeek 与嵌入服务密钥不会进入安装包。')
          .fontSize(13)
          .lineHeight(21)
          .fontColor(BoxStyle.TEXT_MUTED)
          .width('100%')

        Column({ space: 8 }) {
          Text('网关地址')
            .fontSize(12)
            .fontColor(BoxStyle.TEXT_MUTED)
            .width('100%')

          TextInput({
            placeholder: 'https://fragment-ai-gateway.你的域名',
            text: this.aiGatewayBaseUrl
          })
            .width('100%')
            .height(48)
            .fontSize(14)
            .fontColor(BoxStyle.TEXT)
            .placeholderColor('#A4A7A1')
            .backgroundColor(BoxStyle.INPUT_BG)
            .borderRadius(16)
            .padding({ left: 14, right: 14 })
            .onChange((value: string) => {
              this.aiGatewayBaseUrl = value
              this.aiSettingsStatus = ''
            })
        }
        .width('100%')

        Column({ space: 8 }) {
          Text('网关访问口令')
            .fontSize(12)
            .fontColor(BoxStyle.TEXT_MUTED)
            .width('100%')

          TextInput({
            placeholder: '输入为测试设备分配的访问口令',
            text: this.aiGatewayToken
          })
            .type(InputType.Password)
            .width('100%')
            .height(48)
            .fontSize(14)
            .fontColor(BoxStyle.TEXT)
            .placeholderColor('#A4A7A1')
            .backgroundColor(BoxStyle.INPUT_BG)
            .borderRadius(16)
            .padding({ left: 14, right: 14 })
            .onChange((value: string) => {
              this.aiGatewayToken = value
              this.aiSettingsStatus = ''
            })
        }
        .width('100%')

        Text('访问口令只驻留在本次运行内存中，退出应用后不会写入本地数据库。')
          .fontSize(11)
          .lineHeight(18)
          .fontColor(BoxStyle.TEXT_MUTED)
          .width('100%')

        if (this.aiSettingsStatus.length > 0) {
          Text(this.aiSettingsStatus)
            .fontSize(12)
            .lineHeight(20)
            .fontColor(this.aiSettingsStatus.startsWith('连接正常') ? '#5E7A64' : '#8F6258')
            .width('100%')
            .padding({ left: 12, right: 12, top: 9, bottom: 9 })
            .backgroundColor(BoxStyle.SOFT_PANEL)
            .borderRadius(14)
        }

        Button('保存并检测连接')
          .width('100%')
          .height(50)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor(BoxStyle.BUTTON_BG)
          .borderRadius(25)
          .onClick(() => {
            this.saveAndTestAiSettings()
          })

        Button(this.operationInProgress ? '正在恢复…' : '恢复演示数据')
          .width('100%')
          .height(44)
          .fontSize(13)
          .fontColor(BoxStyle.TEXT_SOFT)
          .backgroundColor(BoxStyle.INPUT_BG)
          .border({ width: 1, color: BoxStyle.HAIRLINE })
          .enabled(!this.operationInProgress)
          .borderRadius(22)
          .onClick(() => {
            this.restoreDemoData()
          })
      }
      .width('88%')
      .padding({ left: 22, right: 22, top: 22, bottom: 22 })
      .backgroundColor('#FBFAF6')
      .borderRadius(28)
      .shadow({ radius: 24, color: BoxStyle.SHADOW, offsetX: 0, offsetY: 12 })
    }
    .width('100%')
    .height('100%')
    .zIndex(220)
  }

  @Builder
  Toast() {
    Column() {
      Blank()
      Row() {
        Blank()
        Text(this.toastText)
          .fontSize(13)
          .fontColor('#F8F8F4')
          .textAlign(TextAlign.Center)
          .padding({ left: 16, right: 16, top: 9, bottom: 9 })
          .backgroundColor('rgba(45, 48, 43, 0.82)')
          .borderRadius(18)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
      }
      .width('100%')
      .padding({ left: 26, right: 26 })
      .margin({ bottom: 92 })
    }
    .width('100%')
    .height('100%')
    .zIndex(120)
    .hitTestBehavior(HitTestMode.Transparent)
  }
}
