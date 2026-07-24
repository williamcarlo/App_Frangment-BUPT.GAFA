# Fragment 架构

## 目标

当前架构优先保证本地数据可靠、隐私边界清楚、业务规则可测试，并保留 Box、个人关系图和社区延申树的现有交互。

## 分层

| 目录 | 职责 |
| --- | --- |
| `model/` | 纯数据对象与枚举，不依赖 UI 或数据库 |
| `data/` | RDB 建库/迁移、种子和 SQL Repository |
| `service/` | 回响、社区收存、关系、本地向量匹配与 AI 网关客户端 |
| `viewmodel/` | 事务、Repository 编排、失败结果 |
| `theme/` | 颜色、圆角、动效、图谱尺寸与命中范围 |
| `utils/` | 本地日历日期和稳定 ID |
| `components/` | 图谱、社区树、输入 Sheet、回响卡片与弹窗 |
| `pages/` | 顶层状态机、页面组合和共享状态注入 |

依赖方向为 `Page → ViewModel → Repository → ArkData`，以及 `Page/ViewModel → Service → Model`。Repository 独占 SQL；Service 不访问数据库；Model 不依赖 ArkUI。外部 AI 只能通过 `ai-gateway/` 的 Cloudflare Worker 访问，客户端不持有提供商密钥。

## 数据启动流程

1. `Index.aboutToAppear()` 获取 UIAbilityContext；
2. `DatabaseManager` 打开 `fragment_box.db`；
3. 按 `store.version` 在逐版本事务中执行 v1→v4 迁移；字段、表和索引先由 `SchemaInspector` 检查，允许中断后重试；
4. 仅当永久标记 `seed_data_initialized_v1` 不存在时，在一个事务中导入 SeedData、关系、授权、展示编号和标记；
5. `DataIntegrityService` 在 Snapshot 之前清理安全可判定的孤儿记录，并修正展示编号元数据；
6. ViewModel 返回 active/archived fragments、relations、echo records、community saves、AI 向量和网关 URL；
7. `GraphBuilderService` 只从当前 RDB Snapshot 重建所有活动节点和有效边；空库返回空图；
8. 页面按稳定碎片 ID 恢复选中状态。

迁移只在全部步骤成功后更新 `store.version`，失败会回滚并保留原版本。数据库启动失败会向用户显示提示，不会把运行时 SeedData 当作后备事实源；多步写入使用 RDB 事务，避免半条碎片、半条关系或半条授权。

## 关键不变量

- 持久 ID 由 `IdService` 生成，展示编号与数据库 ID 分离；
- 展示编号由 `app_metadata.next_display_code` 在写事务内单调分配，永久删除不回收；
- 每个碎片最多一条 active sharing consent，历史事件只被 supersede，不被覆盖；
- 私密或已撤回碎片不能作为社区根；
- 社区副本永远创建为 `PRIVATE`；
- `community_saves.source_community_node_id` 唯一，阻止重复收存；
- 社区演示节点 ID 由根碎片、父节点、分支类型、规范化内容和来源身份稳定生成；
- 归档碎片不进入回响；
- 永久删除同时清理关系、回响、授权和社区收存索引；
- 未取得本张 AI 授权前不发送碎片内容；
- 只在本机比较模型与维度一致的向量；
- 提供商密钥只存在于 Worker Secret，网关口令不写入应用数据库；
- 每个本地日最多 surface 一张回响。

## 当前边界

- 仅声明 phone；
- 社区树是本地规则和演示内容；
- 没有 Supabase、真实社区后端、账号/登录、审核、举报、通知调度、媒体或跨设备同步；
- AI 网关已实现，但需要项目维护者独立部署并配置有效 Secret；
- Notification Kit 与 Form Kit 尚未接入；
- `ohosTest` RDB 套件必须在 HarmonyOS 设备或模拟器上执行，普通宿主机单元测试不会假装覆盖 ArkData。
