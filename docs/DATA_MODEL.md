# 数据模型

数据库：`fragment_box.db`，当前版本 `3`。

## 表

### `fragments`

碎片主体。关键字段：`id`、`display_code`、`tag`、`content`、`reminder`、`visibility`、`created_at`、`updated_at`、`archived_at`、`source_community_node_id`、`moderation_status`。

### `fragment_relations`

有向关系。字段：`id`、`from_fragment_id`、`to_fragment_id`、`relation_type`、`created_at`。永久删除任一端点时清理相关记录。

### `echo_records`

回响历史。字段：`id`、`fragment_id`、`surfaced_at`、`opened_at`、`dismissed_until`、`reason`。

### `sharing_consents`

可见性授权审计。字段：`id`、`fragment_id`、`visibility`、`specific_people`、`consented_at`、`revoked_at`。每次保存或编辑可见性都会新增记录，撤回会标记仍有效的记录。

### `community_saves`

社区收存幂等索引。`source_community_node_id` 为主键，另有唯一的 `saved_fragment_id` 和 `saved_at`。字段对应业务名 `sourceCommunityNodeId`、`savedFragmentId`、`savedAt`。

### `app_metadata`

小型应用状态，例如 `privacy_explainer_v1=acknowledged` 和公开的 AI 网关 URL。网关访问口令不会写入此表。

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
- 新库也按 v1→v2→v3 顺序执行，确保迁移路径真实可运行；
- 仅在 `fragments` 数量为 0 时写入示例数据。

当前没有外键约束，跨表清理由 ViewModel 事务保证。永久删除会在同一事务中清除对应 AI 分析、向量与授权。后续应增加可恢复的迁移备份与数据导出。
