import common from '@ohos.app.ability.common'
import relationalStore from '@ohos.data.relationalStore'
import { SchemaInspector } from './SchemaInspector'

export class DatabaseOptions {
  databaseName: string = 'fragment_box.db'
  targetVersion: number = DatabaseManager.DATABASE_VERSION
  seedEnabled: boolean = true

  constructor(
    databaseName: string = 'fragment_box.db',
    targetVersion: number = DatabaseManager.DATABASE_VERSION,
    seedEnabled: boolean = true
  ) {
    this.databaseName = databaseName
    this.targetVersion = targetVersion
    this.seedEnabled = seedEnabled
  }
}

export class DatabaseManager {
  static readonly DATABASE_VERSION: number = 4
  private store: relationalStore.RdbStore | null = null
  private options: DatabaseOptions

  constructor(options: DatabaseOptions = new DatabaseOptions()) {
    this.options = options
  }

  async initialize(context: common.Context): Promise<void> {
    if (this.store !== null) {
      return
    }
    let storeConfig: relationalStore.StoreConfig = {
      name: this.options.databaseName,
      securityLevel: relationalStore.SecurityLevel.S1
    }
    let openedStore: relationalStore.RdbStore =
      await relationalStore.getRdbStore(context, storeConfig)
    try {
      await this.migrate(openedStore)
    } catch (error) {
      openedStore.close()
      throw new Error('数据库初始化迁移失败')
    }
    this.store = openedStore
  }

  getStore(): relationalStore.RdbStore {
    if (this.store === null) {
      throw new Error('数据库尚未初始化')
    }
    return this.store
  }

  isSeedEnabled(): boolean {
    return this.options.seedEnabled
  }

  close(): void {
    if (this.store !== null) {
      this.store.close()
      this.store = null
    }
  }

  async deleteForTesting(context: common.Context): Promise<void> {
    this.close()
    await relationalStore.deleteRdbStore(context, this.options.databaseName)
  }

  private async migrate(store: relationalStore.RdbStore): Promise<void> {
    if (this.options.targetVersion < 1 ||
      this.options.targetVersion > DatabaseManager.DATABASE_VERSION) {
      throw new Error('数据库目标版本不受支持')
    }
    if (store.version > this.options.targetVersion) {
      throw new Error('数据库版本高于当前应用支持版本')
    }
    let openingVersion: number = store.version
    while (store.version < this.options.targetVersion) {
      let sourceVersion: number = store.version
      let targetVersion: number = sourceVersion + 1
      store.beginTransaction()
      try {
        if (targetVersion === 1) {
          await this.createVersionOne(store)
        } else if (targetVersion === 2) {
          await this.migrateVersionOneToTwo(store)
        } else if (targetVersion === 3) {
          await this.migrateVersionTwoToThree(store)
        } else if (targetVersion === 4) {
          await this.migrateVersionThreeToFour(store, openingVersion > 0)
        }
        store.version = targetVersion
        store.commit()
      } catch (error) {
        store.rollBack()
        throw new Error(
          '数据库迁移失败：v' + sourceVersion.toString() + ' → v' + targetVersion.toString()
        )
      }
    }
  }

  private async createVersionOne(store: relationalStore.RdbStore): Promise<void> {
    if (!await SchemaInspector.hasTable(store, 'fragments')) {
      await store.executeSql(
        `CREATE TABLE fragments (
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
        )`
      )
    }
    if (!await SchemaInspector.hasTable(store, 'fragment_relations')) {
      await store.executeSql(
        `CREATE TABLE fragment_relations (
          id TEXT PRIMARY KEY,
          from_fragment_id TEXT NOT NULL,
          to_fragment_id TEXT NOT NULL,
          relation_type TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )`
      )
    }
    if (!await SchemaInspector.hasTable(store, 'echo_records')) {
      await store.executeSql(
        `CREATE TABLE echo_records (
          id TEXT PRIMARY KEY,
          fragment_id TEXT NOT NULL,
          surfaced_at INTEGER NOT NULL DEFAULT 0,
          opened_at INTEGER NOT NULL DEFAULT 0,
          dismissed_until INTEGER NOT NULL DEFAULT 0,
          reason TEXT NOT NULL
        )`
      )
    }
    if (!await SchemaInspector.hasTable(store, 'sharing_consents')) {
      await store.executeSql(
        `CREATE TABLE sharing_consents (
          id TEXT PRIMARY KEY,
          fragment_id TEXT NOT NULL,
          visibility TEXT NOT NULL,
          specific_people TEXT NOT NULL DEFAULT '',
          consented_at INTEGER NOT NULL,
          revoked_at INTEGER NOT NULL DEFAULT 0
        )`
      )
    }
    if (!await SchemaInspector.hasTable(store, 'app_metadata')) {
      await store.executeSql(
        `CREATE TABLE app_metadata (
          meta_key TEXT PRIMARY KEY,
          meta_value TEXT NOT NULL
        )`
      )
    }
    await this.createIndexIfMissing(
      store,
      'idx_fragments_archived_at',
      'CREATE INDEX idx_fragments_archived_at ON fragments(archived_at)'
    )
    await this.createIndexIfMissing(
      store,
      'idx_relations_from',
      'CREATE INDEX idx_relations_from ON fragment_relations(from_fragment_id)'
    )
    await this.createIndexIfMissing(
      store,
      'idx_relations_to',
      'CREATE INDEX idx_relations_to ON fragment_relations(to_fragment_id)'
    )
    await this.createIndexIfMissing(
      store,
      'idx_echo_fragment',
      'CREATE INDEX idx_echo_fragment ON echo_records(fragment_id)'
    )
    await this.createIndexIfMissing(
      store,
      'idx_consent_fragment',
      'CREATE INDEX idx_consent_fragment ON sharing_consents(fragment_id)'
    )
  }

  private async migrateVersionOneToTwo(store: relationalStore.RdbStore): Promise<void> {
    if (!await SchemaInspector.hasColumn(store, 'fragments', 'source_community_node_id')) {
      await store.executeSql(
        "ALTER TABLE fragments ADD COLUMN source_community_node_id TEXT NOT NULL DEFAULT ''"
      )
    }
    if (!await SchemaInspector.hasColumn(store, 'fragments', 'moderation_status')) {
      await store.executeSql(
        "ALTER TABLE fragments ADD COLUMN moderation_status TEXT NOT NULL DEFAULT 'LOCAL_ONLY'"
      )
    }
    if (!await SchemaInspector.hasTable(store, 'community_saves')) {
      await store.executeSql(
        `CREATE TABLE community_saves (
          source_community_node_id TEXT PRIMARY KEY,
          saved_fragment_id TEXT NOT NULL UNIQUE,
          saved_at INTEGER NOT NULL
        )`
      )
    }
    await this.createIndexIfMissing(
      store,
      'idx_community_saved_fragment',
      'CREATE UNIQUE INDEX idx_community_saved_fragment ON community_saves(saved_fragment_id)'
    )
  }

  private async migrateVersionTwoToThree(store: relationalStore.RdbStore): Promise<void> {
    if (!await SchemaInspector.hasTable(store, 'fragment_embeddings')) {
      await store.executeSql(
        `CREATE TABLE fragment_embeddings (
          fragment_id TEXT PRIMARY KEY,
          model TEXT NOT NULL,
          dimension INTEGER NOT NULL,
          vector_json TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )`
      )
    }
    if (!await SchemaInspector.hasTable(store, 'ai_analyses')) {
      await store.executeSql(
        `CREATE TABLE ai_analyses (
          fragment_id TEXT PRIMARY KEY,
          provider TEXT NOT NULL,
          model TEXT NOT NULL,
          normalized_tag TEXT NOT NULL,
          tone TEXT NOT NULL,
          reminder TEXT NOT NULL,
          summary TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )`
      )
    }
    if (!await SchemaInspector.hasTable(store, 'ai_processing_consents')) {
      await store.executeSql(
        `CREATE TABLE ai_processing_consents (
          fragment_id TEXT PRIMARY KEY,
          provider_scope TEXT NOT NULL,
          consented_at INTEGER NOT NULL,
          revoked_at INTEGER NOT NULL DEFAULT 0
        )`
      )
    }
    await this.createIndexIfMissing(
      store,
      'idx_embedding_updated_at',
      'CREATE INDEX idx_embedding_updated_at ON fragment_embeddings(updated_at)'
    )
    await this.createIndexIfMissing(
      store,
      'idx_ai_consent_active',
      'CREATE INDEX idx_ai_consent_active ON ai_processing_consents(revoked_at)'
    )
  }

  private async migrateVersionThreeToFour(
    store: relationalStore.RdbStore,
    existingDatabase: boolean
  ): Promise<void> {
    if (!await SchemaInspector.hasColumn(store, 'sharing_consents', 'superseded_at')) {
      await store.executeSql(
        'ALTER TABLE sharing_consents ADD COLUMN superseded_at INTEGER NOT NULL DEFAULT 0'
      )
    }
    if (!await SchemaInspector.hasColumn(store, 'sharing_consents', 'is_active')) {
      await store.executeSql(
        'ALTER TABLE sharing_consents ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1'
      )
    }
    await store.executeSql(
      `UPDATE sharing_consents
       SET is_active = 0,
           superseded_at = CASE
             WHEN superseded_at = 0 THEN consented_at
             ELSE superseded_at
           END
       WHERE rowid NOT IN (
         SELECT MAX(rowid) FROM sharing_consents GROUP BY fragment_id
       )`
    )
    await store.executeSql(
      `UPDATE sharing_consents
       SET is_active = 1, superseded_at = 0
       WHERE rowid IN (
         SELECT MAX(rowid) FROM sharing_consents GROUP BY fragment_id
       )`
    )
    await this.createIndexIfMissing(
      store,
      'idx_consent_fragment_active',
      'CREATE INDEX idx_consent_fragment_active ON sharing_consents(fragment_id, is_active)'
    )
    await this.createIndexIfMissing(
      store,
      'idx_consent_created_at',
      'CREATE INDEX idx_consent_created_at ON sharing_consents(consented_at)'
    )
    await this.createIndexIfMissing(
      store,
      'idx_consent_one_active',
      'CREATE UNIQUE INDEX idx_consent_one_active ON sharing_consents(fragment_id) WHERE is_active = 1'
    )
    await store.executeSql(
      `INSERT OR IGNORE INTO app_metadata(meta_key, meta_value)
       SELECT 'next_display_code',
              CAST(COALESCE(MAX(CAST(display_code AS INTEGER)), 0) + 1 AS TEXT)
       FROM fragments`
    )
    if (existingDatabase) {
      await store.executeSql(
        `INSERT OR IGNORE INTO app_metadata(meta_key, meta_value)
         VALUES('seed_data_initialized_v1', 'true')`
      )
    }
  }

  private async createIndexIfMissing(
    store: relationalStore.RdbStore,
    indexName: string,
    sql: string
  ): Promise<void> {
    if (!await SchemaInspector.hasIndex(store, indexName)) {
      await store.executeSql(sql)
    }
  }
}
