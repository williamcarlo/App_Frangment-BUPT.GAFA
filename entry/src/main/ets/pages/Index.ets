import common from '@ohos.app.ability.common'
import {
  AiGatewayResult,
  FragmentEmbedding
} from '../model/AiModel'
import { CommunityNode, CommunitySaveRecord } from '../model/CommunityModel'
import { EchoCandidate, EchoRecord } from '../model/EchoModel'
import {
  FragmentItem,
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
import { EchoService } from '../service/EchoService'
import { RelationService } from '../service/RelationService'
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
  @State activeFragmentId: string = 'seed-fragment-03'
  @State activeCommunityKey: string = 'root'
  @State expandedCommunityKeys: string[] = ['root']
  @State draftContent: string = ''
  @State draftTag: string = ''
  @State draftRemind: ReminderPreference = ReminderPreference.COMMUTE
  @State fragmentSearchQuery: string = ''
  @State shareEnabled: boolean = false
  @State shareChoiceMade: boolean = false
  @State inputErrorText: string = ''
  @State toastText: string = ''
  @State showToast: boolean = false
  @State activeGraphNodeKey: string = 'n3'
  @State boxFloatY: number = 0
  @State archivedFragments: FragmentItem[] = []
  @State fragmentRelations: FragmentRelation[] = SeedData.relations()
  @State showPrivacyExplainer: boolean = false
  @State databaseReady: boolean = false
  @State editingFragmentId: string = ''
  @State showArchivedList: boolean = false
  @State showLifecycleConfirm: boolean = false
  @State pendingLifecycleAction: string = ''
  @State pendingLifecycleFragmentId: string = ''
  @State showAiSettings: boolean = false
  @State aiGatewayBaseUrl: string = ''
  @State aiGatewayToken: string = ''
  @State aiSettingsStatus: string = ''
  @State aiProcessingEnabled: boolean = false
  @State aiRequestInFlight: boolean = false
  @State embeddings: FragmentEmbedding[] = []

  private viewModel: FragmentAppViewModel = new FragmentAppViewModel()

  private graphCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private graphCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.graphCanvasSettings)
  private graphNodeRadius: number = BoxStyle.GRAPH_NODE_RADIUS
  private graphSourceMinX: number = BoxStyle.GRAPH_SOURCE_MIN_X
  private graphSourceMaxX: number = BoxStyle.GRAPH_SOURCE_MAX_X
  private graphSourceMinY: number = BoxStyle.GRAPH_SOURCE_MIN_Y
  private graphSourceMaxY: number = BoxStyle.GRAPH_SOURCE_MAX_Y

  @State fragments: FragmentItem[] = SeedData.fragments()
  private graphNodes: GraphNode[] = SeedData.graphNodes()
  private graphEdges: GraphEdge[] = SeedData.graphEdges()
  @State communityNodes: CommunityNode[] = SeedData.communityNodes()
  @State communitySaveRecords: CommunitySaveRecord[] = []
  @State echoRecords: EchoRecord[] = []

  aboutToAppear(): void {
    this.initializePersistence()
    setInterval(() => {
      this.boxFloatY = 0
    }, 3200)
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
      this.hydrateCommunitySaveState()
      this.hydrateDynamicGraph()
      if (!this.selectFragmentById(this.activeFragmentId) && this.fragments.length > 0) {
        this.selectFragmentById(this.fragments[0].id)
      }
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

  private hydrateDynamicGraph(): void {
    this.graphNodes = SeedData.graphNodes()
    this.graphEdges = SeedData.graphEdges()
    for (let i: number = 0; i < this.fragments.length; i++) {
      let fragment: FragmentItem = this.fragments[i]
      if (this.graphNodeKeyByFragmentId(fragment.id) !== 'n3' || fragment.id === 'seed-fragment-03') {
        continue
      }
      let sourceId: string = RelationService.sourceFor(fragment.id, this.fragmentRelations)
      if (sourceId.length === 0) {
        sourceId = 'seed-fragment-03'
      }
      this.appendGraphNode(fragment, sourceId)
    }
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
        this.PrivacyExplainer()
      }

      if (this.showLifecycleConfirm) {
        this.LifecycleConfirm()
      }

      if (this.showAiSettings) {
        this.AiSettingsOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BoxStyle.PAGE_BG)
    .blur(this.showInputSheet ? 2 : 0)
    .bindSheet($$this.showInputSheet, this.InputSheet(), {
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
      return new FragmentItem('empty', '空 Box', '还没有碎片。', 'self', ReminderPreference.NONE, false, '', Date.now(), '--')
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
      return new FragmentItem('empty', '空 Box', '还没有碎片。', 'self', ReminderPreference.NONE, false, '', Date.now(), '--')
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
      this.activeCommunityKey = 'root'
      this.expandedCommunityKeys = ['root']
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
    this.activeCommunityKey = 'root'
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
      return true
    }
    for (let i: number = 0; i < this.fragments.length; i++) {
      if (CommunityService.canUseAsCommunityRoot(this.fragments[i])) {
        this.selectFragmentById(this.fragments[i].id)
        this.activeCommunityKey = 'root'
        this.expandedCommunityKeys = ['root']
        this.showNotice('已切换到一张允许匿名共享的碎片')
        return true
      }
    }
    this.showNotice('没有可共享碎片，请先在放入时选择匿名共享')
    return false
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
    let previousId: string = this.currentFragment().id
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
    let item: FragmentItem = new FragmentItem(
      nextId,
      tag,
      content,
      'self',
      this.draftRemind,
      this.shareEnabled,
      '今天',
      Date.now(),
      IdService.displayCode(this.fragments.length + this.archivedFragments.length),
      visibility
    )
    let relation: FragmentRelation = RelationService.create(previousId, item.id, 'created_after')
    this.persistNewFragment(item, relation, archivedShared)
  }

  private async persistNewFragment(
    item: FragmentItem,
    relation: FragmentRelation,
    archivedShared: boolean
  ): Promise<void> {
    let shouldProcessWithAi: boolean = this.aiProcessingEnabled
    let result: OperationResult = await this.viewModel.createFragment(item, relation)
    if (!result.success) {
      this.inputErrorText = result.message
      this.showNotice(result.message)
      return
    }
    this.fragments = this.fragments.concat([item])
    this.fragmentRelations = this.fragmentRelations.concat([relation])
    this.appendGraphNode(item, relation.fromFragmentId)
    this.selectFragmentById(item.id)
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
  }

  private async persistEditedFragment(
    tag: string,
    content: string,
    visibility: FragmentVisibility
  ): Promise<void> {
    let shouldProcessWithAi: boolean = this.aiProcessingEnabled
    let index: number = this.fragmentIndexById(this.editingFragmentId)
    if (index < 0) {
      this.showNotice('要编辑的碎片已经不存在')
      return
    }
    let original: FragmentItem = this.fragments[index]
    let updated: FragmentItem = new FragmentItem(
      original.id,
      tag,
      content,
      original.tone,
      this.draftRemind,
      visibility === FragmentVisibility.COMMUNITY,
      original.createdAt,
      original.createdAtTimestamp,
      original.displayCode,
      visibility,
      Date.now(),
      original.archivedAtTimestamp,
      original.sourceCommunityNodeId,
      original.moderationStatus
    )
    let result: OperationResult = await this.viewModel.updateFragment(updated)
    if (!result.success) {
      this.inputErrorText = result.message
      this.showNotice(result.message)
      return
    }
    let nextFragments: FragmentItem[] = this.fragments.slice()
    nextFragments[index] = updated
    this.fragments = nextFragments
    this.editingFragmentId = ''
    this.showInputSheet = false
    this.aiProcessingEnabled = false
    this.inputErrorText = ''
    this.showNotice(result.message)
    if (shouldProcessWithAi) {
      this.processFragmentWithAi(updated)
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

  private requestLifecycle(action: string, fragmentId: string): void {
    this.pendingLifecycleAction = action
    this.pendingLifecycleFragmentId = fragmentId
    this.showLifecycleConfirm = true
  }

  private lifecycleConfirmTitle(): string {
    if (this.pendingLifecycleAction === 'archive') {
      return '把这张碎片移入归档箱？'
    }
    if (this.pendingLifecycleAction === 'restore') {
      return '恢复这张碎片？'
    }
    if (this.pendingLifecycleAction === 'revoke') {
      return '撤回这张碎片的社区共享？'
    }
    return '永久删除这张碎片？'
  }

  private async confirmLifecycleAction(): Promise<void> {
    let action: string = this.pendingLifecycleAction
    let fragmentId: string = this.pendingLifecycleFragmentId
    this.showLifecycleConfirm = false
    let result: OperationResult
    if (action === 'archive') {
      result = await this.viewModel.archiveFragment(fragmentId)
    } else if (action === 'restore') {
      result = await this.viewModel.restoreFragment(fragmentId)
    } else if (action === 'revoke') {
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
    this.pendingLifecycleAction = ''
    this.pendingLifecycleFragmentId = ''
    this.showNotice(result.message)
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

  private isShareChoiceSelected(value: boolean): boolean {
    return this.shareChoiceMade && this.shareEnabled === value
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
    return new FragmentItem(
      fragment.id,
      tag,
      fragment.text,
      result.analysis.tone,
      reminder,
      fragment.shared,
      fragment.createdAt,
      fragment.createdAtTimestamp,
      fragment.displayCode,
      fragment.visibility,
      Date.now(),
      fragment.archivedAtTimestamp,
      fragment.sourceCommunityNodeId,
      fragment.moderationStatus
    )
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
    return 'n3'
  }

  private appendGraphNode(item: FragmentItem, previousId: string): void {
    let fragmentNodeCount: number = 0
    for (let i: number = 0; i < this.graphNodes.length; i++) {
      if (this.graphNodes[i].fragmentId.length > 0) {
        fragmentNodeCount++
      }
    }

    let nodeKey: string = 'user-' + item.id
    let sourceKey: string = this.graphNodeKeyByFragmentId(previousId)
    let node: GraphNode = new GraphNode(
      nodeKey,
      item.displayCode,
      item.tag,
      item.tone,
      70 + (fragmentNodeCount * 83) % 240,
      92 + (fragmentNodeCount * 109) % 330,
      item.id
    )
    this.graphNodes = this.graphNodes.concat([node])
    this.graphEdges = this.graphEdges.concat([
      new GraphEdge('user-edge-' + item.id, sourceKey, nodeKey, 'rgba(113, 151, 160, 0.26)')
    ])
    this.activeGraphNodeKey = nodeKey
    this.drawGraphCanvas()
  }

  private showNotice(message: string): void {
    this.toastText = message
    this.showToast = true
    setTimeout(() => {
      this.showToast = false
    }, 1500)
  }

  private getToneColor(tone: string): string {
    if (tone === 'idea') {
      return '#b695a5'
    }
    if (tone === 'memory') {
      return '#8aa9ae'
    }
    if (tone === 'green') {
      return '#8fa783'
    }
    if (tone === 'blue') {
      return '#91a4b5'
    }
    if (tone === 'rose') {
      return '#b08a9a'
    }
    if (tone === 'slate') {
      return '#a5a8a5'
    }
    if (tone === 'micro') {
      return '#a9aca8'
    }
    return '#91a883'
  }

  private isExpanded(key: string): boolean {
    return this.expandedCommunityKeys.indexOf(key) >= 0
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
    return new CommunityNode('root', '', '当前碎片', '当前碎片', '我的 Box', '延申起点', '', 'root', 0, 0, 0, 0)
  }

  private selectCommunityNode(key: string): void {
    this.activeCommunityKey = key
    if (this.childrenOf(key).length === 0 && key !== 'root') {
      this.communityNodes = this.communityNodes.concat(this.createCommunityBranches(key))
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
    if (path.indexOf('root') < 0) {
      path.unshift('root')
    }
    return path
  }

  private createCommunityBranches(parentKey: string): CommunityNode[] {
    let base: number = this.communityNodes.length + 1
    let parent: CommunityNode = this.getCommunityNode(parentKey)
    return [
      new CommunityNode(parentKey + '-a' + base.toString(), parentKey, '相似分支', parent.tag, '匿名共享', '相似经验', '换一个生活场景看，问题也许不是社交本身，而是节奏被打断。', 'slate', 0, 0, 0, 0),
      new CommunityNode(parentKey + '-b' + base.toString(), parentKey, '反向视角', parent.tag, 'BOXer', '相反经验', '它也许不该被马上解决，只是需要被另一种方式看见。', 'rose', 0, 0, 0, 0)
    ]
  }

  private saveActiveCommunityFragment(): void {
    if (!this.databaseReady) {
      this.showNotice('本地数据还在准备，请稍等一下')
      return
    }
    if (this.activeCommunityKey === 'root') {
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
      IdService.displayCode(this.fragments.length + this.archivedFragments.length),
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
    let result: OperationResult = await this.viewModel.saveCommunityCopy(item, relation, saveRecord)
    if (!result.success) {
      this.showNotice(result.message)
      return
    }
    this.fragments = this.fragments.concat([item])
    this.fragmentRelations = this.fragmentRelations.concat([relation])
    this.communitySaveRecords = this.communitySaveRecords.concat([saveRecord])
    node.savedFragmentId = item.id
    node.savedAtTimestamp = saveRecord.savedAtTimestamp
    this.appendGraphNode(item, relation.fromFragmentId)
    this.selectFragmentById(item.id)
    this.currentPage = AppPage.COLLECTION
    this.graphMode = false
    this.activeCommunityKey = 'root'
    this.expandedCommunityKeys = ['root']
    this.showNotice(result.message)
  }

  private continueFromActiveCommunityFragment(): void {
    let tag: string = this.currentFragment().tag
    if (this.activeCommunityKey !== 'root') {
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

  private treeNodeWidth(depth: number, count: number): number {
    if (count <= 1) {
      return depth === 0 ? 136 : 108
    }
    let availableWidth: number = 306
    let gapWidth: number = (count - 1) * 8
    let fitWidth: number = (availableWidth - gapWidth) / count
    let depthWidth: number = 108 - depth * 10
    if (depthWidth < 64) {
      depthWidth = 64
    }
    return Math.max(52, Math.min(depthWidth, fitWidth))
  }

  private treeNodeHeight(depth: number): number {
    if (depth <= 0) {
      return 66
    }
    if (depth === 1) {
      return 60
    }
    if (depth === 2) {
      return 54
    }
    return 50
  }

  private treeTitleSize(depth: number): number {
    if (depth <= 0) {
      return 15
    }
    if (depth === 1) {
      return 13
    }
    return 11
  }

  private graphNodeByKey(key: string): GraphNode {
    for (let i: number = 0; i < this.graphNodes.length; i++) {
      if (this.graphNodes[i].key === key) {
        return this.graphNodes[i]
      }
    }
    if (this.graphNodes.length > 0) {
      return this.graphNodes[0]
    }
    return new GraphNode('empty', '', '', 'micro', 0, 0, '')
  }

  private isGraphEdgeActive(edge: GraphEdge): boolean {
    return edge.fromKey === this.activeGraphNodeKey || edge.toKey === this.activeGraphNodeKey
  }

  private isGraphNodeRelated(node: GraphNode): boolean {
    if (node.key === this.activeGraphNodeKey) {
      return true
    }
    for (let i: number = 0; i < this.graphEdges.length; i++) {
      let edge: GraphEdge = this.graphEdges[i]
      if ((edge.fromKey === this.activeGraphNodeKey && edge.toKey === node.key) ||
        (edge.toKey === this.activeGraphNodeKey && edge.fromKey === node.key)) {
        return true
      }
    }
    return false
  }

  private graphNodeKeyword(node: GraphNode): string {
    if (node.name.length > 0) {
      return node.name
    }
    return '关联点'
  }

  private graphCanvasX(node: GraphNode, width: number): number {
    let usableWidth: number = width - 56
    return 28 + (node.x - this.graphSourceMinX) / (this.graphSourceMaxX - this.graphSourceMinX) * usableWidth
  }

  private graphCanvasY(node: GraphNode, height: number): number {
    let usableHeight: number = height - 74
    return 34 + (node.y - this.graphSourceMinY) / (this.graphSourceMaxY - this.graphSourceMinY) * usableHeight
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

  private drawGraphCanvas(): void {
    let width: number = this.graphCanvasContext.width
    let height: number = this.graphCanvasContext.height
    if (width <= 0 || height <= 0) {
      return
    }

    this.graphCanvasContext.clearRect(0, 0, width, height)
    this.drawGraphCanvasEdges(width, height)
    this.drawGraphCanvasNodes(width, height)
    this.drawGraphCanvasLabels(width, height)
  }

  private drawGraphCanvasEdges(width: number, height: number): void {
    for (let i: number = 0; i < this.graphEdges.length; i++) {
      let edge: GraphEdge = this.graphEdges[i]
      let from: GraphNode = this.graphNodeByKey(edge.fromKey)
      let to: GraphNode = this.graphNodeByKey(edge.toKey)
      let active: boolean = this.isGraphEdgeActive(edge)
      let fromX: number = this.graphCanvasX(from, width)
      let fromY: number = this.graphCanvasY(from, height)
      let toX: number = this.graphCanvasX(to, width)
      let toY: number = this.graphCanvasY(to, height)
      let dx: number = toX - fromX
      let dy: number = toY - fromY
      let controlX: number = (fromX + toX) / 2 - dy * 0.18
      let controlY: number = (fromY + toY) / 2 + dx * 0.18

      // Draw soft graph curves first; selected relations become darker and thicker.
      this.graphCanvasContext.beginPath()
      this.graphCanvasContext.moveTo(fromX, fromY)
      this.graphCanvasContext.quadraticCurveTo(controlX, controlY, toX, toY)
      this.graphCanvasContext.strokeStyle = active ? BoxStyle.GRAPH_ACTIVE : BoxStyle.GRAPH_IDLE
      this.graphCanvasContext.lineWidth = active ? 4 : 1.1
      this.graphCanvasContext.stroke()
    }
  }

  private drawGraphCanvasNodes(width: number, height: number): void {
    for (let i: number = 0; i < this.graphNodes.length; i++) {
      let node: GraphNode = this.graphNodes[i]
      let related: boolean = this.isGraphNodeRelated(node)
      this.graphCanvasContext.beginPath()
      this.graphCanvasContext.arc(this.graphCanvasX(node, width), this.graphCanvasY(node, height), this.graphNodeRadius, 0, Math.PI * 2)
      this.graphCanvasContext.fillStyle = node.key === this.activeGraphNodeKey ? '#3f4440' : this.getToneColor(node.tone)
      this.graphCanvasContext.globalAlpha = related ? 0.96 : 0.34
      this.graphCanvasContext.fill()
      this.graphCanvasContext.globalAlpha = 1
      if (related) {
        this.graphCanvasContext.beginPath()
        this.graphCanvasContext.arc(this.graphCanvasX(node, width), this.graphCanvasY(node, height), this.graphNodeRadius, 0, Math.PI * 2)
        this.graphCanvasContext.strokeStyle = node.key === this.activeGraphNodeKey ? 'rgba(49, 53, 50, 0.72)' : 'rgba(90, 98, 91, 0.42)'
        this.graphCanvasContext.lineWidth = node.key === this.activeGraphNodeKey ? 2.4 : 1.4
        this.graphCanvasContext.stroke()
      }
    }
  }

  private drawGraphCanvasLabels(width: number, height: number): void {
    this.graphCanvasContext.font = '13px sans-serif'
    this.graphCanvasContext.textAlign = 'center'
    this.graphCanvasContext.textBaseline = 'top'
    for (let i: number = 0; i < this.graphNodes.length; i++) {
      let node: GraphNode = this.graphNodes[i]
      this.graphCanvasContext.fillStyle = this.isGraphNodeRelated(node) ? BoxStyle.TEXT_SOFT : BoxStyle.TEXT_MUTED
      this.graphCanvasContext.fillText(this.graphNodeKeyword(node), this.graphCanvasX(node, width), this.graphCanvasY(node, height) + this.graphNodeRadius + 8, 76)
    }
  }

  private handleGraphCanvasTouch(event: TouchEvent): void {
    if (event.type !== TouchType.Down || event.touches.length === 0) {
      return
    }
    let touchX: number = event.touches[0].x
    let touchY: number = event.touches[0].y
    let width: number = this.graphCanvasContext.width
    let height: number = this.graphCanvasContext.height
    for (let i: number = 0; i < this.graphNodes.length; i++) {
      let node: GraphNode = this.graphNodes[i]
      let dx: number = touchX - this.graphCanvasX(node, width)
      let dy: number = touchY - this.graphCanvasY(node, height)
      if (Math.sqrt(dx * dx + dy * dy) <= BoxStyle.GRAPH_HIT_RADIUS) {
        this.selectGraphNode(node)
        return
      }
    }
  }

  private selectGraphNode(node: GraphNode): void {
    this.activeGraphNodeKey = node.key
    if (node.fragmentId.length > 0) {
      this.selectFragmentById(node.fragmentId)
    }
    this.drawGraphCanvas()
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
      Column() {
        this.EchoFragmentCard(this.fragments[this.echoFragmentIndex()])
        Text('今天先不看')
          .fontSize(11)
          .fontColor(BoxStyle.TEXT_MUTED)
          .height(30)
          .lineHeight(30)
          .padding({ left: 12, right: 12 })
          .margin({ top: 6 })
          .backgroundColor('rgba(255, 255, 255, 0.46)')
          .borderRadius(15)
          .onClick(() => {
            this.dismissEcho(this.fragments[this.echoFragmentIndex()].id)
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.End)
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
  EchoFragmentCard(item: FragmentItem) {
    Column({ space: 8 }) {
      Row() {
        Text('旧碎片回响')
          .fontSize(11)
          .fontColor(BoxStyle.TEXT_MUTED)
          .height(24)
          .lineHeight(24)
          .padding({ left: 10, right: 10 })
          .backgroundColor('rgba(239, 240, 235, 0.92)')
          .borderRadius(12)

        Blank()

        Text(this.fragmentDateLabel(item) + ' · ' + item.remind)
          .fontSize(11)
          .fontColor(BoxStyle.TEXT_MUTED)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(item.tag)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(BoxStyle.TEXT)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(item.text)
        .fontSize(12)
        .fontColor(BoxStyle.TEXT_SOFT)
        .lineHeight(18)
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.echoReason(item.id))
        .fontSize(11)
        .fontColor(BoxStyle.TEXT_MUTED)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 13, bottom: 13 })
    .margin({ top: 24 })
    .backgroundColor('rgba(255, 255, 255, 0.76)')
    .border({ width: 1, color: BoxStyle.HAIRLINE })
    .borderRadius(22)
    .shadow({ radius: 18, color: BoxStyle.SHADOW_SOFT, offsetX: 0, offsetY: 8 })
    .onClick(() => {
      this.openEchoFragment(item)
    })
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
                this.requestLifecycle('archive', item.id)
              })
              if (item.visibility === FragmentVisibility.COMMUNITY) {
                this.LifecycleTextButton('撤回共享', () => {
                  this.requestLifecycle('revoke', item.id)
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
    Column() {
      this.GraphHeader()
      this.GraphCard()
      this.RelationList()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 22, right: 22, top: 34, bottom: 74 })
  }

  @Builder
  GraphHeader() {
    Column() {
      Row() {
        Text('脑洞关系网')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222425')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()

        Button('返回碎片 +')
          .width(112)
          .height(38)
          .fontSize(13)
          .fontColor('#3d403d')
          .padding({ left: 0, right: 0 })
          .backgroundColor('rgba(255, 255, 255, 0.76)')
          .border({ width: 1, color: 'rgba(56, 58, 57, 0.08)' })
          .borderRadius(19)
          .shadow({ radius: 18, color: 'rgba(44, 46, 45, 0.10)', offsetX: 0, offsetY: 8 })
          .onClick(() => {
            this.graphMode = false
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Row() {
        Text('点击节点查看关系')
          .fontSize(12)
          .fontColor('#747873')
          .height(30)
          .lineHeight(30)
          .padding({ left: 12, right: 12 })
          .backgroundColor('rgba(255, 255, 255, 0.70)')
          .border({ width: 1, color: 'rgba(56, 58, 57, 0.08)' })
          .borderRadius(15)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
  }

  @Builder
  GraphCard() {
    Stack() {
      Canvas(this.graphCanvasContext)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.drawGraphCanvas()
      })
      .onTouch((event: TouchEvent) => {
        this.handleGraphCanvasTouch(event)
      })
    }
    .width('100%')
    .height(420)
    .margin({ top: 18 })
    .backgroundColor(BoxStyle.SOFT_PANEL)
    .border({ width: 1, color: 'rgba(55, 57, 56, 0.05)' })
    .borderRadius(26)
    .clip(true)
  }

  @Builder
  RelationList() {
    Column({ space: 8 }) {
      Text($r('app.string.relation_list_title'))
        .fontSize(12)
        .fontColor(BoxStyle.TEXT_MUTED)
        .width('100%')

      if (this.relatedFragments().length === 0) {
        Text('当前碎片还没有已保存的关系。')
          .fontSize(13)
          .fontColor(BoxStyle.TEXT_SOFT)
          .width('100%')
          .height(42)
          .lineHeight(42)
      } else {
        Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
          ForEach(this.relatedFragments().slice(0, 3), (item: FragmentItem) => {
            Text(item.displayCode + ' · ' + item.tag)
              .fontSize(12)
              .fontColor(BoxStyle.TEXT_SOFT)
              .height(34)
              .lineHeight(34)
              .padding({ left: 12, right: 12 })
              .margin({ right: 8, bottom: 6 })
              .backgroundColor('rgba(255, 255, 255, 0.68)')
              .border({ width: 1, color: BoxStyle.HAIRLINE })
              .borderRadius(17)
              .onClick(() => {
                this.selectFragmentById(item.id)
                this.drawGraphCanvas()
              })
          }, (item: FragmentItem) => item.id)
        }
        .width('100%')
      }
    }
    .width('100%')
    .height(88)
    .margin({ top: 12 })
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
    Scroll() {
      Column({ space: 0 }) {
        ForEach(this.getNodesByLevel(), (levelNodes: CommunityNode[], levelIndex: number) => {
          if (levelIndex > 0) {
            this.TreeConnector(levelNodes.length)
          }
          Row({ space: 6 }) {
            ForEach(levelNodes, (node: CommunityNode) => {
              this.TreeNodeCard(node, levelIndex, this.getTreeMaxDepth(), levelNodes.length)
            }, (node: CommunityNode) => node.key)
          }
          .width('100%')
          .height(levelIndex === 0 ? 78 : this.treeNodeHeight(levelIndex) + 12)
          .justifyContent(levelNodes.length <= 1 ? FlexAlign.Center : FlexAlign.SpaceEvenly)
          .alignItems(VerticalAlign.Center)
        }, (levelNodes: CommunityNode[], levelIndex: number) => levelIndex.toString())

        Text('点击末端节点，继续展开新的共享碎片')
          .fontSize(12)
          .fontColor(BoxStyle.TEXT_MUTED)
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(42)
          .lineHeight(42)
          .margin({ top: 12 })
          .backgroundColor('rgba(255, 255, 255, 0.56)')
          .border({ width: 1, color: 'rgba(55, 57, 55, 0.05)' })
          .borderRadius(21)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: 0, right: 0, top: 26, bottom: 28 })
    }
    .width('100%')
    .layoutWeight(1)
    .margin({ top: 12 })
    .backgroundColor('rgba(241, 242, 237, 0.90)')
    .border({ width: 1, color: 'rgba(55, 57, 55, 0.07)' })
    .borderRadius(28)
    .scrollBar(BarState.Off)
    .clip(true)
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
        this.activeCommunityKey = 'root'
        this.expandedCommunityKeys = ['root']
      })
  }

  // Returns the max depth (0-indexed) of the visible tree
  private getTreeMaxDepth(): number {
    let levels: CommunityNode[][] = this.getNodesByLevel()
    return levels.length - 1
  }

  @Builder
  TreeConnector(count: number) {
    Column() {
      Rect()
        .width(1.2)
        .height(24)
        .radius(1)
        .fill('rgba(118, 123, 116, 0.22)')

      Row() {
        Blank()
        Rect()
          .width(count <= 1 ? 1.2 : '58%')
          .height(1.2)
          .radius(1)
          .fill('rgba(118, 123, 116, 0.18)')
        Blank()
      }
      .width('100%')

      Rect()
        .width(1.2)
        .height(22)
        .radius(1)
        .fill('rgba(118, 123, 116, 0.18)')
    }
    .width('100%')
    .height(52)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  TreeNodeCard(node: CommunityNode, depth: number, maxDepth: number, count: number) {
    Column() {
      Text(node.key === 'root' ? this.currentFragment().tag : node.title)
        .fontSize(this.treeTitleSize(depth))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.activeCommunityKey === node.key ? BoxStyle.TEXT : '#686D66')
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(node.key === 'root' ? '当前碎片' : (this.childrenOf(node.key).length > 0 ? '已展开' : '继续展开'))
        .fontSize(depth >= 3 ? 8 : 9)
        .fontColor(BoxStyle.TEXT_MUTED)
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
    }
    .width(this.treeNodeWidth(depth, count))
    .height(this.treeNodeHeight(depth))
    .padding({ left: depth >= 2 ? 6 : 10, right: depth >= 2 ? 6 : 10, top: depth >= 2 ? 8 : 11, bottom: depth >= 2 ? 8 : 10 })
    .backgroundColor(this.activeCommunityKey === node.key ? '#FFFFFF' : 'rgba(250, 250, 246, 0.74)')
    .borderRadius(18)
    .border({ width: 1, color: this.activeCommunityKey === node.key ? 'rgba(64, 68, 64, 0.20)' : 'rgba(55, 57, 55, 0.06)' })
    .shadow({ radius: this.activeCommunityKey === node.key ? 18 : 4, color: this.activeCommunityKey === node.key ? 'rgba(43, 45, 44, 0.11)' : 'rgba(43, 45, 44, 0.035)', offsetX: 0, offsetY: 6 })
    .animation({ duration: BoxStyle.MOTION_FAST, curve: Curve.EaseOut })
    .onClick(() => {
      this.selectCommunityNode(node.key)
    })
  }

  private communityNodeBg(tone: string): string {
    if (tone === 'blue') {
      return 'rgba(141, 159, 178, 0.18)'
    }
    if (tone === 'green') {
      return 'rgba(150, 164, 143, 0.18)'
    }
    if (tone === 'rose') {
      return 'rgba(170, 150, 153, 0.18)'
    }
    if (tone === 'slate') {
      return 'rgba(152, 155, 155, 0.18)'
    }
    return 'rgba(255, 255, 255, 0.82)'
  }

  private getNodesByLevel(): CommunityNode[][] {
    let levels: CommunityNode[][] = []
    if (this.communityNodes.length === 0) {
      return levels
    }
    let root: CommunityNode = this.communityNodes[0]
    let currentLevel: CommunityNode[] = [root]
    while (currentLevel.length > 0) {
      levels.push(currentLevel)
      let nextLevel: CommunityNode[] = []
      for (let node of currentLevel) {
        if (this.isExpanded(node.key)) {
          let children: CommunityNode[] = this.childrenOf(node.key)
          for (let child of children) {
            nextLevel.push(child)
          }
        }
      }
      currentLevel = nextLevel
    }
    return levels
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
  InputSheet() {
    Scroll() {
      Column({ space: 20 }) {
      // 原生半模态内容：只承载输入、Tag、提醒偏好和完成动作。
      Row() {
        Text('记录碎片')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(BoxStyle.TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('×')
          .width(42)
          .height(42)
          .fontSize(25)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6C706A')
          .textAlign(TextAlign.Center)
          .backgroundColor('rgba(241, 241, 238, 0.86)')
          .border({ width: 1, color: BoxStyle.HAIRLINE })
          .borderRadius(21)
          .onClick(() => {
            this.closeInputSheet()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      TextArea({ placeholder: '写下刚刚想到的内容...', text: this.draftContent })
        .width('100%')
        .height(138)
        .fontSize(16)
        .fontColor(BoxStyle.TEXT)
        .placeholderColor('#A4A7A1')
        .backgroundColor('rgba(243, 243, 240, 0.92)')
        .border({ width: 1, color: 'rgba(55, 57, 55, 0.05)' })
        .borderRadius(18)
        .padding({ left: 18, right: 18, top: 16, bottom: 16 })
        .onChange((value: string) => {
          this.draftContent = value
        })

      Column({ space: 8 }) {
        Text('标签')
          .fontSize(13)
          .fontColor(BoxStyle.TEXT_MUTED)
          .fontWeight(FontWeight.Medium)
          .width('100%')

        TextInput({ placeholder: '例如：通勤观察、情绪或灵感', text: this.draftTag })
          .width('100%')
          .height(50)
          .fontSize(15)
          .fontColor(BoxStyle.TEXT)
          .placeholderColor('#A4A7A1')
          .backgroundColor('rgba(243, 243, 240, 0.92)')
          .border({ width: 1, color: 'rgba(55, 57, 55, 0.05)' })
          .borderRadius(18)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.draftTag = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 12 }) {
        Text('何时提醒')
          .fontSize(13)
          .fontColor(BoxStyle.TEXT_MUTED)
          .fontWeight(FontWeight.Medium)
          .width('100%')

        Row({ space: 12 }) {
          ForEach([
            ReminderPreference.COMMUTE,
            ReminderPreference.BEDTIME,
            ReminderPreference.WEEKEND,
            ReminderPreference.NONE,
            ReminderPreference.RANDOM
          ], (item: ReminderPreference) => {
            this.RemindPill(item)
          }, (item: ReminderPreference) => item)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 10 }) {
        Row() {
          Text('幕后整理')
            .fontSize(13)
            .fontColor(BoxStyle.TEXT_MUTED)
            .fontWeight(FontWeight.Medium)

          Blank()

          Text('每张单独授权')
            .fontSize(11)
            .fontColor('#7C817A')
        }
        .width('100%')

        Row({ space: 12 }) {
          this.AiChoicePill('允许 AI 整理', true)
          this.AiChoicePill('仅保存在本机', false)
        }
        .width('100%')

        Text(this.aiProcessingEnabled ?
          '将把本张内容、标签和提醒偏好发送到你的加密网关；不会上传其他碎片。' :
          '本张内容不会发送给 AI 服务。')
          .fontSize(11)
          .lineHeight(18)
          .fontColor(BoxStyle.TEXT_MUTED)
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 12 }) {
        Row() {
          Text('可见范围')
            .fontSize(13)
            .fontColor(BoxStyle.TEXT_MUTED)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('请选择')
            .fontSize(11)
            .fontColor('#7C817A')
            .textAlign(TextAlign.Center)
            .height(24)
            .lineHeight(24)
            .padding({ left: 9, right: 9 })
            .backgroundColor('rgba(232, 233, 228, 0.82)')
            .borderRadius(12)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)

        Row({ space: 12 }) {
          this.ShareChoicePill('匿名加入社区', true)
          this.ShareChoicePill('仅自己可见', false)
        }
        .width('100%')

        if (this.inputErrorText.length > 0) {
          Text(this.inputErrorText)
            .fontSize(12)
            .fontColor('#8F6258')
            .height(24)
            .lineHeight(24)
            .padding({ left: 12, right: 12 })
            .backgroundColor('rgba(143, 98, 88, 0.08)')
            .borderRadius(12)
            .margin({ top: 2 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Button(this.shareChoiceMade ? '保存碎片' : '先选择可见范围')
        .width('100%')
        .height(56)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .padding({ left: 0, right: 0 })
        .backgroundColor(this.shareChoiceMade ? '#262826' : '#C2C4BE')
        .borderRadius(28)
        .shadow({ radius: this.shareChoiceMade ? 14 : 0, color: 'rgba(38, 40, 38, 0.12)', offsetX: 0, offsetY: 7 })
        .onClick(() => {
          this.saveDraftFragment()
        })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 24, bottom: 34 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 30, topRight: 30 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
  @Builder
  RemindPill(item: ReminderPreference) {
    Text(item)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.draftRemind === item ? BoxStyle.SELECTED_TEXT : '#8F928C')
      .textAlign(TextAlign.Center)
      .height(44)
      .lineHeight(44)
      .layoutWeight(1)
      .backgroundColor(this.draftRemind === item ? BoxStyle.SELECTED_SOFT : '#F1F1EE')
      .borderRadius(22)
      .border({ width: 0, color: '#00000000' })
      .onClick(() => {
        this.draftRemind = item
      })
  }

  @Builder
  ShareChoicePill(label: string, value: boolean) {
    Text(label)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.isShareChoiceSelected(value) ? '#2F322F' : '#8F928C')
      .textAlign(TextAlign.Center)
      .height(44)
      .lineHeight(44)
      .layoutWeight(1)
      .backgroundColor(this.isShareChoiceSelected(value) ? 'rgba(226, 228, 222, 0.96)' : '#F1F1EE')
      .border({ width: 1, color: this.isShareChoiceSelected(value) ? 'rgba(68, 72, 67, 0.16)' : 'rgba(55, 57, 55, 0.04)' })
      .borderRadius(22)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .onClick(() => {
        this.shareEnabled = value
        this.shareChoiceMade = true
        this.inputErrorText = ''
      })
  }

  @Builder
  AiChoicePill(label: string, value: boolean) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.aiProcessingEnabled === value ? '#2F322F' : '#8F928C')
      .textAlign(TextAlign.Center)
      .height(42)
      .lineHeight(42)
      .layoutWeight(1)
      .backgroundColor(this.aiProcessingEnabled === value ?
        'rgba(226, 228, 222, 0.96)' : '#F1F1EE')
      .border({
        width: 1,
        color: this.aiProcessingEnabled === value ?
          'rgba(68, 72, 67, 0.16)' : 'rgba(55, 57, 55, 0.04)'
      })
      .borderRadius(21)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .onClick(() => {
        this.aiProcessingEnabled = value
        this.inputErrorText = ''
      })
  }

  @Builder
  ShareSwitch() {
    Stack() {
      Rect()
        .width(48)
        .height(28)
        .radius(14)
        .fill(this.shareEnabled ? '#393b3a' : '#d9dad4')

      Circle()
        .width(22)
        .height(22)
        .fill('#ffffff')
        .shadow({ radius: 8, color: 'rgba(35, 36, 35, 0.12)', offsetX: 0, offsetY: 3 })
        .position({ x: this.shareEnabled ? 23 : 3, y: 3 })
    }
    .width(48)
    .height(28)
    .onClick(() => {
      this.shareEnabled = !this.shareEnabled
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
            this.requestLifecycle('restore', item.id)
          })

        Button('永久删除')
          .height(34)
          .fontSize(12)
          .fontColor('#8F6258')
          .backgroundColor('rgba(143, 98, 88, 0.08)')
          .borderRadius(17)
          .onClick(() => {
            this.requestLifecycle('delete', item.id)
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
  PrivacyExplainer() {
    Stack() {
      Rect()
        .width('100%')
        .height('100%')
        .fill('rgba(30, 32, 29, 0.34)')

      Column({ space: 16 }) {
        Text($r('app.string.privacy_explainer_title'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(BoxStyle.TEXT)
          .width('100%')

        Text('碎片默认仅保存在本机并仅自己可见。只有你明确选择“匿名加入社区”时，才会写入共享授权；撤回后它会立即退出社区入口。')
          .fontSize(15)
          .lineHeight(24)
          .fontColor(BoxStyle.TEXT_SOFT)
          .width('100%')

        Text('“幕后整理”也按每张碎片单独授权：仅发送当前内容、标签和提醒偏好到你配置的加密网关。其他碎片仍留在本机，社区内容仍为本地演示数据。')
          .fontSize(13)
          .lineHeight(21)
          .fontColor(BoxStyle.TEXT_MUTED)
          .width('100%')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .backgroundColor(BoxStyle.SOFT_PANEL)
          .borderRadius(16)

        Button('知道了，继续')
          .width('100%')
          .height(52)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(BoxStyle.BUTTON_BG)
          .borderRadius(26)
          .onClick(() => {
            this.acknowledgePrivacyExplainer()
          })
      }
      .width('86%')
      .padding({ left: 24, right: 24, top: 26, bottom: 24 })
      .backgroundColor('#FBFAF6')
      .borderRadius(28)
      .shadow({ radius: 24, color: BoxStyle.SHADOW, offsetX: 0, offsetY: 12 })
    }
    .width('100%')
    .height('100%')
    .zIndex(200)
  }

  @Builder
  LifecycleConfirm() {
    Stack() {
      Rect()
        .width('100%')
        .height('100%')
        .fill('rgba(30, 32, 29, 0.28)')
        .onClick(() => {
          this.showLifecycleConfirm = false
        })

      Column({ space: 18 }) {
        Text(this.lifecycleConfirmTitle())
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(BoxStyle.TEXT)
          .width('100%')
          .textAlign(TextAlign.Center)

        Text(this.pendingLifecycleAction === 'delete' ?
          '永久删除后无法恢复，相关关系、回响与授权记录也会一并清理。' :
          '操作会立即写入本地数据库，你之后仍可在归档箱或隐私设置中继续管理。')
          .fontSize(13)
          .lineHeight(21)
          .fontColor(BoxStyle.TEXT_MUTED)
          .width('100%')
          .textAlign(TextAlign.Center)

        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .fontSize(14)
            .fontColor(BoxStyle.TEXT_SOFT)
            .backgroundColor(BoxStyle.INPUT_BG)
            .borderRadius(22)
            .onClick(() => {
              this.showLifecycleConfirm = false
            })

          Button('确认')
            .layoutWeight(1)
            .height(44)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor(this.pendingLifecycleAction === 'delete' ? '#8F6258' : BoxStyle.BUTTON_BG)
            .borderRadius(22)
            .onClick(() => {
              this.confirmLifecycleAction()
            })
        }
        .width('100%')
      }
      .width('82%')
      .padding({ left: 22, right: 22, top: 24, bottom: 22 })
      .backgroundColor('#FBFAF6')
      .borderRadius(26)
      .shadow({ radius: 22, color: BoxStyle.SHADOW, offsetX: 0, offsetY: 10 })
    }
    .width('100%')
    .height('100%')
    .zIndex(210)
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
