# Fragment｜碎片

**2026 中国高校计算机大赛人工智能创意赛鸿蒙赛道｜应用创新项目**

Fragment 是一款帮助用户接住零散想法、在未来重新遇见它们，并沿着个人与社区关系继续延申的 HarmonyOS 应用。

> 把差一点消失的想法，留给未来的自己。

## 核心闭环

记录碎片 → 设置提醒偏好 → 未来回响 → 发现关联 → 自我/他人/方向延申。

## 当前基础版本

本分支已经搭建 HarmonyOS Stage 模型工程，并实现以下 MVP 骨架：

- 快速记录灵感、观察、复盘、情绪与冲动；
- 设置通勤、睡前、周末、随机等提醒偏好；
- 选择仅自己或加入社区图谱；
- 根据标签生成个人旧碎片关联；
- 展示自我延申、他人延申和方向延申；
- 使用内存仓库保存示例数据，后续替换为 ArkData 持久化。

## 工程结构

```text
AppScope/                          应用级配置与资源
entry/src/main/ets/
├── entryability/                  Stage 模型入口
├── pages/                         页面入口
├── components/                    首页、捕捉、网络等组件
├── model/                         碎片与延申数据模型
├── data/                          数据仓库
└── service/                       关联与回响服务
```

详细架构见 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)，迭代计划见 [`docs/ROADMAP.md`](docs/ROADMAP.md)。

## 打开方式

1. 使用支持 HarmonyOS Stage 模型的 DevEco Studio 打开仓库根目录；
2. 等待 hvigor 与依赖同步；
3. 配置本机签名；
4. 选择 phone、tablet 或 2in1 模拟器运行 `entry` 模块。

> 当前版本聚焦产品骨架。ArkData 持久化、系统卡片、通知调度、端侧语义关联和真实社区服务将在后续迭代接入。
