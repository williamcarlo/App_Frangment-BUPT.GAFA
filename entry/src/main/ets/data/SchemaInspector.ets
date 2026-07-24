import relationalStore from '@ohos.data.relationalStore'

export class SchemaInspector {
  static async hasTable(store: relationalStore.RdbStore, tableName: string): Promise<boolean> {
    return SchemaInspector.hasSchemaObject(store, 'table', tableName)
  }

  static async hasIndex(store: relationalStore.RdbStore, indexName: string): Promise<boolean> {
    return SchemaInspector.hasSchemaObject(store, 'index', indexName)
  }

  static async hasColumn(
    store: relationalStore.RdbStore,
    tableName: string,
    columnName: string
  ): Promise<boolean> {
    let resultSet: relationalStore.ResultSet =
      await store.querySql('PRAGMA table_info(' + tableName + ')')
    try {
      while (resultSet.goToNextRow()) {
        if (resultSet.getString(resultSet.getColumnIndex('name')) === columnName) {
          return true
        }
      }
      return false
    } finally {
      resultSet.close()
    }
  }

  private static async hasSchemaObject(
    store: relationalStore.RdbStore,
    type: string,
    name: string
  ): Promise<boolean> {
    let resultSet: relationalStore.ResultSet = await store.querySql(
      'SELECT 1 AS present FROM sqlite_master WHERE type = ? AND name = ? LIMIT 1',
      [type, name]
    )
    try {
      return resultSet.goToNextRow()
    } finally {
      resultSet.close()
    }
  }
}
