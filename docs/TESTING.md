# 测试与验证

## 本地单元测试

```powershell
.\hvigorw.bat test --mode module -p product=default
```

纯函数测试位于 `entry/src/test/`，由 `List.test.ets` 汇总：

- `DateUtils`：午夜跨日和未来时间；
- `IdService`：同毫秒唯一实体 ID；
- `EchoService`：确定性每日随机、日期轮换、冷却与稍后提醒；
- `CommunityService`：私密副本、来源记录和重复保存查找；
- `StableCommunityNodeIdService`：不同展开顺序得到相同业务 ID；
- `GraphBuilderService`：所有有效关系、孤儿诊断、空图和稳定坐标；
- `AiSimilarityService`：余弦相似度与向量空间隔离；
- Seed contract：首次导入数据的 ID 唯一和关系端点完整。

这些宿主机测试不宣称操作 ArkData RDB。

## 设备端 RDB 集成测试

`entry/src/ohosTest/` 是独立的设备/模拟器测试目标。它为每个用例创建唯一测试数据库，结束时关闭并删除，覆盖：

- v0、v1、v2 与半完成 v1 迁移到当前 v4；
- 首条/第二条碎片关系规则、CRUD、归档、恢复和永久删除；
- 授权事件历史与单一 active 状态；
- 单调展示编号、事务回滚和重启持久化；
- Seed 只初始化一次。

在 DevEco Studio 中选择 `entry@ohosTest` 并在 HarmonyOS 设备或模拟器运行。命令行能编译测试 HAP，但真正执行需要已连接的目标设备；未实际执行时必须在验收报告中明确说明。

```powershell
.\hvigorw.bat assembleHap --mode module -p module=entry@ohosTest -p product=default
```

## AI 网关测试

```powershell
cd ai-gateway
pnpm install --frozen-lockfile
pnpm run check
```

网关测试覆盖：

- 非法请求与缺失 AI 授权；
- 网关访问口令拒绝；
- 提供商调用前的限流；
- DeepSeek 约束 JSON 解析；
- DashScope 1024 维向量校验；
- 完整 Worker handler 的成功路径。

## HAP 构建

```powershell
.\hvigorw.bat clean --mode module -p product=default assembleHap
```

验收标准：

1. ArkTS 编译成功；
2. `PackageHap` 成功；
3. 未配置签名时只允许“skip sign”警告；
4. `git diff --check` 无错误；
5. 仓库不包含 `.hvigor`、`build`、`oh_modules`、签名文件或用户数据库。

## 手工回归

1. 首次启动只出现一次隐私说明；
2. 重启后新增碎片仍存在；
3. 同一社区节点只能收存一次，成功后回到个人页；
4. 私密/撤回碎片不能进入社区；
5. 编辑、归档、恢复和永久删除均有正确结果；
6. 上下列表滚动与左右页面切换不会互相吞手势；
7. 画布节点易点中，文字关系列表可完成同等导航。
8. 未选择“允许 AI 整理”时，保存不会产生网络请求；
9. AI 网关不可用时，碎片仍已保存在本机；
10. 网关可用时，未命名标签和默认提醒可被建议更新，并生成本地语义关系；
11. 退出并重启应用后网关 URL 保留，但访问口令需要重新输入；
12. 永久删除 AI 处理过的碎片后，分析、向量和授权记录一并消失。
13. 删除全部碎片并重启后保持真实空状态，只有显式点击“恢复演示数据”才重新导入；
14. 删除中间展示编号后，新碎片继续使用更大的编号；
15. 社区节点展开顺序变化或重启后，已收存状态仍能恢复。
