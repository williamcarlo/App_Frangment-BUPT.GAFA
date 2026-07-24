# Fragment｜碎片

**2026 中国高校计算机大赛人工智能创意赛鸿蒙赛道｜应用创新项目**

Fragment 是一款帮助用户接住零散想法、在未来重新遇见它们，并沿着个人与社区关系继续延申的 HarmonyOS 应用。

> 把差一点消失的想法，留给未来的自己。

## 核心闭环

放入 Box → 等待变化 → 被重新打开 → 产生延申 → 继续放入新碎片。

## 当前交互版本

本分支已经搭建 HarmonyOS Stage 模型工程，并按照交互文档、完整流程图和前端 Demo 实现三屏 MVP：

- **Box**：点击盒子记录碎片，设置 Tag、提醒偏好与匿名共享；
- **低频回响**：按照通勤、睡前、周末窗口，只在合适时刻重新展示一张旧碎片；
- **个人碎片轨道**：上下浏览、关键词/Tag 搜索，并缩小为个人脑洞关系图；
- **脑洞网生长**：新写或从社区收存的碎片会生成新节点，并连接到写作前的中心碎片；
- **社区延申树**：从当前碎片逐层展开相似、相反与行动分支；
- **再生成闭环**：把社区节点收进 Box，或基于节点继续写一张新碎片；
- **输入规则**：碎片内容必填，并且必须明确选择匿名共享或仅自己可见；仅公开碎片可以作为社区延申起点。

## 工程结构

```text
AppScope/                          应用级配置与资源
entry/src/main/ets/
├── entryability/EntryAbility.ets  Stage 模型入口
└── pages/Index.ets                三屏交互、内存数据与关系规则原型
```

详细架构见 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)，迭代计划见 [`docs/ROADMAP.md`](docs/ROADMAP.md)。

## 打开方式

1. 使用支持 HarmonyOS Stage 模型的 DevEco Studio 打开仓库根目录；
2. 等待 hvigor 与依赖同步；
3. 配置本机签名；
4. 选择 phone、tablet 或 2in1 模拟器运行 `entry` 模块。

## 命令行构建

仓库包含 Windows 与 macOS/Linux 的 Hvigor 启动脚本。运行前需安装 DevEco Studio 或 HarmonyOS 命令行工具，并配置 HarmonyOS SDK。

```powershell
# Windows
.\hvigorw.bat clean --mode module -p product=default assembleHap
```

```bash
# macOS / Linux
./hvigorw clean --mode module -p product=default assembleHap
```

脚本会优先使用 DevEco Studio 自带的 Hvigor。非默认安装位置可设置 `DEVECO_STUDIO_HOME`，或通过 `HVIGORW_JS` 直接指定 `tools/hvigor/bin/hvigorw.js` 的绝对路径。

工程采用 Hvigor `modelVersion: 5.0.0`。`hvigorfile.ts` 中使用的 `@ohos/hvigor-ohos-plugin` 是该版本 Hvigor 提供的内置系统插件，因此不需要写入 `hvigor/hvigor-config.json5` 的 `dependencies`；该字段仅用于项目额外引入的自定义 Hvigor 插件。

> 当前版本聚焦可走通的交互闭环。ArkData 持久化、系统卡片、通知调度、端侧语义关联和真实社区服务将在后续迭代接入。
