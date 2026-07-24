# Fragment｜碎片

**2026 中国高校计算机大赛人工智能创意赛鸿蒙赛道｜应用创新项目**

Fragment 是一款帮助用户接住零散想法、在未来重新遇见它们，并沿个人与社区关系继续延申的 HarmonyOS 应用。

> 把差一点消失的想法，留给未来的自己。

## 当前版本

当前 `0.3.0` 是可编译的本地稳定性基础版，已实现：

- Box 记录、Tag、五种回响偏好与显式可见范围选择；
- Box → 个人碎片 → 社区树三屏横向导航；
- 个人瀑布浏览、搜索、稳定 ID 选中、Canvas 关系图和文字关系列表；
- ArkData RDB 持久化、数据库版本迁移与空库种子；
- 碎片编辑、归档、恢复、永久删除，以及关系/回响/授权清理；
- 通勤、睡前、周末、随机与沉睡模式；最短年龄、冷却、每日上限和稍后提醒；
- 私密、社区、指定对象、已撤回四级可见性模型与授权审计记录；
- 社区节点收存为私密副本，稳定记录来源并阻止重复收存；
- 首次隐私说明、共享撤回和失败提示；
- Hypium 本地单元测试。

社区节点仍是本地演示数据；当前没有真实账号、服务端社区、内容审核、跨设备同步、系统通知或大模型调用。界面不会把这些能力冒充成已完成。

## 支持设备

当前工程配置为 **HarmonyOS phone-only**。页面尚未完成 tablet / 2in1 的响应式验收，因此没有在 `deviceTypes` 中声明这些设备。

## 工程结构

```text
entry/src/main/ets/
├── data/        ArkData 建库、迁移、种子与 Repository
├── model/       碎片、关系、社区、回响与授权模型
├── service/     社区、回响和关系规则
├── theme/       颜色、圆角、动效与图谱尺寸
├── utils/       日期与稳定 ID
├── viewmodel/   页面业务编排、事务和错误结果
├── pages/       顶层页面与 ArkUI 组合
└── entryability/
```

详细说明见：

- [架构](docs/ARCHITECTURE.md)
- [数据模型](docs/DATA_MODEL.md)
- [隐私设计](docs/PRIVACY.md)
- [交互规格](docs/INTERACTION_SPEC.md)
- [测试说明](docs/TESTING.md)
- [路线图](docs/ROADMAP.md)

## 构建

使用支持 HarmonyOS Stage 模型的 DevEco Studio 打开仓库根目录，等待 OHPM 同步后选择 phone 运行 `entry`。

Windows 命令行：

```powershell
.\hvigorw.bat test --mode module -p product=default
.\hvigorw.bat clean --mode module -p product=default assembleHap
```

macOS / Linux：

```bash
./hvigorw test --mode module -p product=default
./hvigorw clean --mode module -p product=default assembleHap
```

非默认 DevEco 安装位置可设置 `DEVECO_STUDIO_HOME`。工程未提交签名文件；本地未配置 `signingConfigs` 时会生成 unsigned HAP，这是预期行为。

## 数据与隐私

本地数据库名为 `fragment_box.db`，使用 ArkData RDB。新碎片只有在用户明确选择“匿名加入社区”后才获得社区可见性；默认状态为私密。撤回共享会把可见性改为 `REVOKED`，社区入口立即过滤该碎片。永久删除会清理本地关系、回响、授权和社区收存索引。

更多细节见 [PRIVACY.md](docs/PRIVACY.md)。项目采用 [Apache-2.0](LICENSE) 许可证。
