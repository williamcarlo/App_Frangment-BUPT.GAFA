import common from '@ohos.app.ability.common'
import relationalStore from '@ohos.data.relationalStore'

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'fragment_box.db',
  securityLevel: relationalStore.SecurityLevel.S1
}

export class DatabaseManager {
  static readonly DATABASE_VERSION: number = 2
  private store: relationalStore.RdbStore | null = null

  async initialize(context: common.UIAbilityContext): Promise<void> {
    if (this.store !== null) {
      return
    }
    let openedStore: relationalStore.RdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG)
    await this.migrate(openedStore)
    this.store = openedStore
  }

  getStore(): relationalStore.RdbStore {
    if (this.store === null) {
      throw new Error('数据库尚未初始化')
    }
    return this.store
  }

  private async migrate(store: relationalStore.RdbStore): Promise<void> {
    if (store.version === 0) {
      await this.createVersionOne(store)
      store.version = 1
    }
    if (store.version === 1) {
      await this.migrateVersionOneToTwo(store)
      store.version = 2
    }
    if (store.version > DatabaseManager.DATABASE_VERSION) {
      throw new Error('数据库版本高于当前应用支持版本')
    }
  }

  private async createVersionOne(store: relationalStore.RdbStore): Promise<void> {
    let statements: string[] = [
      `CREATE TABLE IF NOT EXISTS fragments (
        id TEXT PRIMARY KEY,
        display_code TEXT NOT NULL,
        tag TEXT NOT NULL,
        content TEXT NOT NULL,
        tone TEXT NOT NULL,
        reminder TEXT NOT NULL,
        visibility TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        archived_at INTEGER NOT NULL DEFAULT 0
      )`,
      `CREATE TABLE IF NOT EXISTS fragment_relations (
        id TEXT PRIMARY KEY,
        from_fragment_id TEXT NOT NULL,
        to_fragment_id TEXT NOT NULL,
        relation_type TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )`,
      `CREATE TABLE IF NOT EXISTS echo_records (
        id TEXT PRIMARY KEY,
        fragment_id TEXT NOT NULL,
        surfaced_at INTEGER NOT NULL DEFAULT 0,
        opened_at INTEGER NOT NULL DEFAULT 0,
        dismissed_until INTEGER NOT NULL DEFAULT 0,
        reason TEXT NOT NULL
      )`,
      `CREATE TABLE IF NOT EXISTS sharing_consents (
        id TEXT PRIMARY KEY,
        fragment_id TEXT NOT NULL,
        visibility TEXT NOT NULL,
        specific_people TEXT NOT NULL DEFAULT '',
        consented_at INTEGER NOT NULL,
        revoked_at INTEGER NOT NULL DEFAULT 0
      )`,
      `CREATE TABLE IF NOT EXISTS app_metadata (
        meta_key TEXT PRIMARY KEY,
        meta_value TEXT NOT NULL
      )`,
      'CREATE INDEX IF NOT EXISTS idx_fragments_archived_at ON fragments(archived_at)',
      'CREATE INDEX IF NOT EXISTS idx_relations_from ON fragment_relations(from_fragment_id)',
      'CREATE INDEX IF NOT EXISTS idx_relations_to ON fragment_relations(to_fragment_id)',
      'CREATE INDEX IF NOT EXISTS idx_echo_fragment ON echo_records(fragment_id)',
      'CREATE INDEX IF NOT EXISTS idx_consent_fragment ON sharing_consents(fragment_id)'
    ]
    for (let i: number = 0; i < statements.length; i++) {
      await store.executeSql(statements[i])
    }
  }

  private async migrateVersionOneToTwo(store: relationalStore.RdbStore): Promise<void> {
    await store.executeSql(
      "ALTER TABLE fragments ADD COLUMN source_community_node_id TEXT NOT NULL DEFAULT ''"
    )
    await store.executeSql(
      "ALTER TABLE fragments ADD COLUMN moderation_status TEXT NOT NULL DEFAULT 'LOCAL_ONLY'"
    )
    await store.executeSql(
      `CREATE TABLE IF NOT EXISTS community_saves (
        source_community_node_id TEXT PRIMARY KEY,
        saved_fragment_id TEXT NOT NULL UNIQUE,
        saved_at INTEGER NOT NULL
      )`
    )
    await store.executeSql(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_community_saved_fragment ON community_saves(saved_fragment_id)'
    )
  }
}
