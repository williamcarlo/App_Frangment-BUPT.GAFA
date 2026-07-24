# 数据模型

数据库：`fragment_box.db`，当前版本 `4`。

## 表

### `fragments`

碎片主体。关键字段：`id`、`display_code`、`tag`、`content`、`reminder`、`visibility`、`created_at`、`updated_at`、`archived_at`、`source_community_node_id`、`moderation_status`。

### `fragment_relations`

有向关系。字段：`id`、`from_fragment_id`、`to_fragment_id`、`relation_type`、`created_at`。永久删除任一端点时清理相关记录。

### `echo_records`

回响历史。字段：`id`、`fragment_id`、`surfaced_at`、`opened_at`、`dismissed_until`、`reason`。

### `sharing_consents`

可见性授权事件审计。字段：`id`、`fragment_id`、`visibility`、`specific_people`、`consented_at`、`revoked_at`、`superseded_at`、`is_active`。

可见性变化与 `fragments.visibility` 更新处于同一个事务：旧 active 事件被关闭并写入 `superseded_at`，随后插入带当前操作时间的新事件。`PRIVATE` 与 `REVOKED` 都是明确事件，而不是“没有授权记录”。普通索引覆盖 `fragment_id`、`fragment_id + is_active`、`consented_at`，部分唯一索引约束每个碎片最多一条 active 事件。

### `community_saves`

社区收存幂等索引。`source_community_node_id` 为主键，另有唯一的 `saved_fragment_id` 和 `saved_at`。字段对应业务名 `sourceCommunityNodeId`、`savedFragmentId`、`savedAt`。

### `app_metadata`

小型应用状态，例如 `privacy_explainer_v1=acknowledged`、`seed_data_initialized_v1=true`、`next_display_code` 和公开的 AI 网关 URL。网关访问口令不会写入此表。

### `fragment_embeddings`

用户授权 AI 处理后保存的本地向量。字段为 `fragment_id`、`model`、`dimension`、`vector_json` 和 `updated_at`。相似度计算只比较 `model` 与 `dimension` 相同的记录。

### `ai_analyses`

结构化 AI 整理结果。字段为 `fragment_id`、`provider`、`model`、`normalized_tag`、`tone`、`reminder`、`summary` 和 `created_at`。

### `ai_processing_consents`

逐碎片 AI 授权审计。字段为 `fragment_id`、`provider_scope`、`consented_at` 和 `revoked_at`。该授权与社区共享授权完全独立。

## 迁移

- v1：创建碎片、关系、回响、授权和元数据表；
- v2：为碎片增加社区来源和审核状态，并创建 `community_saves`；
- v3：创建 AI 分析、向量和逐碎片 AI 授权表；
- v4：把共享授权升级为事件审计，增加相关索引，并初始化 Seed 标记和单调展示编号；
- 新库也按 v1→v2→v3→v4 顺序执行，确保迁移路径真实可运行；
- 每一步迁移均在事务内执行；通过 `PRAGMA table_info` 和 `sqlite_master` 检查字段、表与索引，可从半完成迁移恢复；
- 只有迁移事务完全成功后才更新 `store.version`；高于当前应用支持版本的数据库会明确拒绝打开；
- 示例数据只在永久初始化标记不存在时写入一次。用户删除全部碎片后，重启保持空库；设置页提供显式“恢复演示数据”。

展示编号在创建碎片和收存社区副本的写事务中从 `next_display_code` 分配，永久删除不回收编号。SeedData 只负责首次导入碎片和关系；运行时个人图谱由 `GraphBuilderService` 从 RDB Snapshot 重建。

当前没有外键约束，跨表清理由 ViewModel 事务保证，并由启动完整性检查安全清理孤儿关系、回响、授权和收存索引。永久删除会在同一事务中清除对应 AI 分析、向量与授权。后续仍应增加可恢复的迁移备份、数据导出和数据库加密。
