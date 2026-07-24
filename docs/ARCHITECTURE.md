# Fragment 架构

## 目标

当前架构优先保证本地数据可靠、隐私边界清楚、业务规则可测试，并保留 Box、个人关系图和社区延申树的现有交互。

## 分层

| 目录 | 职责 |
| --- | --- |
| `model/` | 纯数据对象与枚举，不依赖 UI 或数据库 |
| `data/` | RDB 建库/迁移、种子和 SQL Repository |
| `service/` | 回响、社区收存、关系等纯业务规则 |
| `viewmodel/` | 事务、Repository 编排、失败结果 |
| `theme/` | 颜色、圆角、动效、图谱尺寸与命中范围 |
| `utils/` | 本地日历日期和稳定 ID |
| `pages/` | 顶层页面、Sheet、弹窗和共享状态注入 |

依赖方向为 `Page → ViewModel → Repository → ArkData`，以及 `Page/ViewModel → Service → Model`。Repository 独占 SQL；Service 不访问数据库；Model 不依赖 ArkUI。

## 数据启动流程

1. `Index.aboutToAppear()` 获取 UIAbilityContext；
2. `DatabaseManager` 打开 `fragment_box.db`；
3. 按 `store.version` 执行 v1 建表和 v1→v2 迁移；
4. 仅当 `fragments` 为空时写入 SeedData；
5. ViewModel 返回 active/archived fragments、relations、echo records 和 community saves；
6. 页面按稳定碎片 ID 恢复选中状态并重建动态图节点。

数据库失败会保留内存中的演示数据，并向用户显示提示；多步写入使用 RDB 事务，避免半条碎片或半条授权。

## 关键不变量

- 持久 ID 由 `IdService` 生成，展示编号与数据库 ID 分离；
- 私密或已撤回碎片不能作为社区根；
- 社区副本永远创建为 `PRIVATE`；
- `community_saves.source_community_node_id` 唯一，阻止重复收存；
- 归档碎片不进入回响；
- 永久删除同时清理关系、回响、授权和社区收存索引；
- 每个本地日最多 surface 一张回响。

## 当前边界

- 仅声明 phone；
- 社区树是本地规则和演示内容；
- 没有真实后端、登录、审核、通知调度、媒体或 AI；
- UI 主页面仍包含较多 ArkUI Builder，后续可继续拆分为独立组件，但业务与数据职责已离开页面。
