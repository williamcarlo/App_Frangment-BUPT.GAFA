import common from '@ohos.app.ability.common'
import relationalStore from '@ohos.data.relationalStore'
import { abilityDelegatorRegistry } from '@kit.TestKit'
import { describe, expect, it } from '@ohos/hypium'
import {
  DatabaseManager,
  DatabaseOptions
} from '../../../main/ets/data/DatabaseManager'
import { ConsentRepository } from '../../../main/ets/data/ConsentRepository'
import { MetadataRepository } from '../../../main/ets/data/MetadataRepository'
import { SchemaInspector } from '../../../main/ets/data/SchemaInspector'
import { SeedData } from '../../../main/ets/data/SeedData'
import { CommunitySaveRecord } from '../../../main/ets/model/CommunityModel'
import { EchoRecord } from '../../../main/ets/model/EchoModel'
import {
  FragmentItem,
  FragmentRelation,
  FragmentVisibility,
  ReminderPreference
} from '../../../main/ets/model/FragmentModel'
import {
  AppDataSnapshot,
  FragmentAppViewModel,
  OperationResult
} from '../../../main/ets/viewmodel/FragmentAppViewModel'

function testContext(): common.Context {
  return abilityDelegatorRegistry.getAbilityDelegator().getAppContext()
}

function testFragment(id: string, visibility: FragmentVisibility): FragmentItem {
  return new FragmentItem({
    id: id,
    displayCode: '',
    tag: 'RDB 测试',
    text: '只写入隔离测试数据库',
    tone: 'self',
    remind: ReminderPreference.NONE,
    visibility: visibility,
    createdAtTimestamp: Date.now()
  })
}

async function count(store: relationalStore.RdbStore, tableName: string): Promise<number> {
  let resultSet: relationalStore.ResultSet =
    await store.querySql('SELECT COUNT(*) AS total FROM ' + tableName)
  try {
    if (resultSet.goToNextRow()) {
      return resultSet.getLong(resultSet.getColumnIndex('total'))
    }
    return 0
  } finally {
    resultSet.close()
  }
}

async function countForFragment(
  store: relationalStore.RdbStore,
  tableName: string,
  columnName: string,
  fragmentId: string
): Promise<number> {
  let resultSet: relationalStore.ResultSet = await store.querySql(
    'SELECT COUNT(*) AS total FROM ' + tableName + ' WHERE ' + columnName + ' = ?',
    [fragmentId]
  )
  try {
    if (resultSet.goToNextRow()) {
      return resultSet.getLong(resultSet.getColumnIndex('total'))
    }
    return 0
  } finally {
    resultSet.close()
  }
}

export default function databaseIntegrationTest() {
  describe('ArkData RDB device integration', () => {
    it('migrates v0, v1, v2 and a partially completed v1 migration', 0, async () => {
      let context: common.Context = testContext()
      let freshName: string = 'fragment_rdb_fresh_' + Date.now().toString() + '.db'
      let fresh: DatabaseManager = new DatabaseManager(
        new DatabaseOptions(freshName, DatabaseManager.DATABASE_VERSION, false)
      )
      try {
        await fresh.initialize(context)
        expect(fresh.getStore().version).assertEqual(DatabaseManager.DATABASE_VERSION)
        expect(await SchemaInspector.hasColumn(
          fresh.getStore(),
          'sharing_consents',
          'is_active'
        )).assertEqual(true)
      } finally {
        await fresh.deleteForTesting(context)
      }

      let partialName: string = 'fragment_rdb_partial_' + Date.now().toString() + '.db'
      let versionOne: DatabaseManager =
        new DatabaseManager(new DatabaseOptions(partialName, 1, false))
      try {
        await versionOne.initialize(context)
        await versionOne.getStore().executeSql(
          "ALTER TABLE fragments ADD COLUMN source_community_node_id TEXT NOT NULL DEFAULT ''"
        )
        versionOne.close()
        let recovered: DatabaseManager = new DatabaseManager(
          new DatabaseOptions(partialName, DatabaseManager.DATABASE_VERSION, false)
        )
        await recovered.initialize(context)
        expect(recovered.getStore().version).assertEqual(DatabaseManager.DATABASE_VERSION)
        expect(await SchemaInspector.hasColumn(
          recovered.getStore(),
          'fragments',
          'moderation_status'
        )).assertEqual(true)
        recovered.close()
      } finally {
        await versionOne.deleteForTesting(context)
      }

      let versionTwoName: string = 'fragment_rdb_v2_' + Date.now().toString() + '.db'
      let versionTwo: DatabaseManager =
        new DatabaseManager(new DatabaseOptions(versionTwoName, 2, false))
      try {
        await versionTwo.initialize(context)
        versionTwo.close()
        let upgraded: DatabaseManager = new DatabaseManager(
          new DatabaseOptions(versionTwoName, DatabaseManager.DATABASE_VERSION, false)
        )
        await upgraded.initialize(context)
        expect(upgraded.getStore().version).assertEqual(DatabaseManager.DATABASE_VERSION)
        upgraded.close()
      } finally {
        await versionTwo.deleteForTesting(context)
      }

      let futureName: string = 'fragment_rdb_future_' + Date.now().toString() + '.db'
      let futureConfig: relationalStore.StoreConfig = {
        name: futureName,
        securityLevel: relationalStore.SecurityLevel.S1
      }
      let futureStore: relationalStore.RdbStore =
        await relationalStore.getRdbStore(context, futureConfig)
      futureStore.version = DatabaseManager.DATABASE_VERSION + 1
      futureStore.close()
      let rejectedFutureVersion: boolean = false
      try {
        let futureDatabase: DatabaseManager = new DatabaseManager(
          new DatabaseOptions(futureName, DatabaseManager.DATABASE_VERSION, false)
        )
        await futureDatabase.initialize(context)
      } catch (error) {
        rejectedFutureVersion = true
      } finally {
        await relationalStore.deleteRdbStore(context, futureName)
      }
      expect(rejectedFutureVersion).assertEqual(true)
    })

    it('persists CRUD, consent history, relation rules and display codes', 0, async () => {
      let context: common.Context = testContext()
      let databaseName: string = 'fragment_rdb_crud_' + Date.now().toString() + '.db'
      let database: DatabaseManager = new DatabaseManager(
        new DatabaseOptions(databaseName, DatabaseManager.DATABASE_VERSION, false)
      )
      let viewModel: FragmentAppViewModel = new FragmentAppViewModel(database)
      try {
        await viewModel.initialize(context, [], [])
        let invalid: FragmentItem = testFragment('invalid', FragmentVisibility.PRIVATE)
        let invalidRelation: FragmentRelation =
          new FragmentRelation('invalid-relation', 'empty', invalid.id, 'created_after')
        expect((await viewModel.createFragment(invalid, invalidRelation)).success)
          .assertEqual(false)
        expect(await count(database.getStore(), 'fragments')).assertEqual(0)

        let first: FragmentItem = testFragment('first', FragmentVisibility.PRIVATE)
        let firstResult: OperationResult = await viewModel.createFragment(first, null)
        expect(firstResult.success).assertEqual(true)
        expect(first.displayCode).assertEqual('01')
        expect(await count(database.getStore(), 'fragment_relations')).assertEqual(0)

        let second: FragmentItem = testFragment('second', FragmentVisibility.COMMUNITY)
        let relation: FragmentRelation =
          new FragmentRelation('first-second', first.id, second.id, 'created_after')
        expect((await viewModel.createFragment(second, relation)).success).assertEqual(true)
        expect(second.displayCode).assertEqual('02')
        expect(await count(database.getStore(), 'fragment_relations')).assertEqual(1)

        second.visibility = FragmentVisibility.PRIVATE
        expect((await viewModel.updateFragment(second)).success).assertEqual(true)
        let consentRepository: ConsentRepository = new ConsentRepository(database)
        let history = await consentRepository.loadForFragment(second.id)
        expect(history.length).assertEqual(2)
        expect(history[0].isActive).assertEqual(false)
        expect(history[1].isActive).assertEqual(true)
        expect(history[1].consentedAtTimestamp >= history[0].consentedAtTimestamp)
          .assertEqual(true)

        expect((await viewModel.archiveFragment(first.id)).success).assertEqual(true)
        expect((await viewModel.restoreFragment(first.id)).success).assertEqual(true)

        let saved: FragmentItem = testFragment('saved-community-copy', FragmentVisibility.PRIVATE)
        saved.sourceCommunityNodeId = 'community_stable_source'
        let savedRelation: FragmentRelation = new FragmentRelation(
          'second-saved',
          second.id,
          saved.id,
          'saved_from_community'
        )
        let savedRecord: CommunitySaveRecord = new CommunitySaveRecord(
          saved.sourceCommunityNodeId,
          saved.id,
          Date.now()
        )
        expect((await viewModel.saveCommunityCopy(
          saved,
          savedRelation,
          savedRecord
        )).success).assertEqual(true)
        expect(saved.displayCode).assertEqual('03')

        let duplicate: FragmentItem =
          testFragment('duplicate-community-copy', FragmentVisibility.PRIVATE)
        let duplicateRecord: CommunitySaveRecord = new CommunitySaveRecord(
          saved.sourceCommunityNodeId,
          duplicate.id,
          Date.now()
        )
        expect((await viewModel.saveCommunityCopy(
          duplicate,
          new FragmentRelation(
            'second-duplicate',
            second.id,
            duplicate.id,
            'saved_from_community'
          ),
          duplicateRecord
        )).success).assertEqual(false)
        expect(await countForFragment(
          database.getStore(),
          'fragments',
          'id',
          duplicate.id
        )).assertEqual(0)

        expect((await viewModel.surfaceEcho(new EchoRecord(
          'saved-echo',
          saved.id,
          Date.now(),
          0,
          0,
          'device-test'
        ))).success).assertEqual(true)
        expect(await countForFragment(
          database.getStore(),
          'sharing_consents',
          'fragment_id',
          saved.id
        )).assertEqual(1)
        expect((await viewModel.deleteFragment(saved.id)).success).assertEqual(true)
        expect(await countForFragment(
          database.getStore(),
          'fragment_relations',
          'to_fragment_id',
          saved.id
        )).assertEqual(0)
        expect(await countForFragment(
          database.getStore(),
          'echo_records',
          'fragment_id',
          saved.id
        )).assertEqual(0)
        expect(await countForFragment(
          database.getStore(),
          'sharing_consents',
          'fragment_id',
          saved.id
        )).assertEqual(0)
        expect(await countForFragment(
          database.getStore(),
          'community_saves',
          'saved_fragment_id',
          saved.id
        )).assertEqual(0)

        let nextAfterDeletedGap: FragmentItem =
          testFragment('next-after-gap', FragmentVisibility.PRIVATE)
        expect((await viewModel.createFragment(nextAfterDeletedGap, null)).success)
          .assertEqual(true)
        expect(nextAfterDeletedGap.displayCode).assertEqual('04')

        expect((await viewModel.deleteFragment(first.id)).success).assertEqual(true)
        expect(await count(database.getStore(), 'fragment_relations')).assertEqual(0)

        database.close()
        let reopenedDatabase: DatabaseManager = new DatabaseManager(
          new DatabaseOptions(databaseName, DatabaseManager.DATABASE_VERSION, false)
        )
        let reopenedViewModel: FragmentAppViewModel =
          new FragmentAppViewModel(reopenedDatabase)
        let snapshot: AppDataSnapshot = await reopenedViewModel.initialize(context, [], [])
        expect(snapshot.fragments.length).assertEqual(2)
        reopenedDatabase.close()
      } finally {
        await database.deleteForTesting(context)
      }
    })

    it('never restores seed data implicitly after the user deletes everything', 0, async () => {
      let context: common.Context = testContext()
      let databaseName: string = 'fragment_rdb_seed_' + Date.now().toString() + '.db'
      let database: DatabaseManager = new DatabaseManager(
        new DatabaseOptions(databaseName, DatabaseManager.DATABASE_VERSION, true)
      )
      let viewModel: FragmentAppViewModel = new FragmentAppViewModel(database)
      try {
        let snapshot: AppDataSnapshot = await viewModel.initialize(
          context,
          SeedData.fragments(1000000),
          SeedData.relations(1000000)
        )
        for (let i: number = 0; i < snapshot.fragments.length; i++) {
          expect((await viewModel.deleteFragment(snapshot.fragments[i].id)).success)
            .assertEqual(true)
        }
        database.close()

        let reopenedDatabase: DatabaseManager = new DatabaseManager(
          new DatabaseOptions(databaseName, DatabaseManager.DATABASE_VERSION, true)
        )
        let reopenedViewModel: FragmentAppViewModel =
          new FragmentAppViewModel(reopenedDatabase)
        let reopened: AppDataSnapshot = await reopenedViewModel.initialize(
          context,
          SeedData.fragments(2000000),
          SeedData.relations(2000000)
        )
        expect(reopened.fragments.length).assertEqual(0)
        reopenedDatabase.close()
      } finally {
        await database.deleteForTesting(context)
      }
    })

    it('rolls back every seed row and the marker when seed initialization fails', 0, async () => {
      let context: common.Context = testContext()
      let databaseName: string = 'fragment_rdb_seed_rollback_' +
        Date.now().toString() + '.db'
      let database: DatabaseManager = new DatabaseManager(
        new DatabaseOptions(databaseName, DatabaseManager.DATABASE_VERSION, true)
      )
      let viewModel: FragmentAppViewModel = new FragmentAppViewModel(database)
      let failed: boolean = false
      try {
        let seed: FragmentItem = testFragment(
          'seed-that-must-roll-back',
          FragmentVisibility.PRIVATE
        )
        let invalidRelation: FragmentRelation = new FragmentRelation(
          'invalid-seed-relation',
          'empty',
          seed.id,
          'created_after'
        )
        try {
          await viewModel.initialize(context, [seed], [invalidRelation])
        } catch (error) {
          failed = true
        }
        expect(failed).assertEqual(true)
        expect(await count(database.getStore(), 'fragments')).assertEqual(0)
        let metadata: MetadataRepository = new MetadataRepository(database)
        expect(await metadata.getValue('seed_data_initialized_v1')).assertEqual('')
      } finally {
        await database.deleteForTesting(context)
      }
    })
  })
}
