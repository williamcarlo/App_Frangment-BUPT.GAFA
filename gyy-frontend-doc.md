# 碎片 Box (FragmentBox) — 前端说明文档

## 快速开始（队友克隆后即可预览）

```bash
# 1. 克隆仓库
git clone https://github.com/williamcarlo/App_Frangment-BUPT.GAFA.git

# 2. 用 DevEco Studio 打开项目
#    File → Open → 选择克隆下来的 App_Frangment-BUPT.GAFA 文件夹
#    DevEco Studio 会自动识别为 HarmonyOS Stage 模型工程

# 3. 预览运行
#    点击右上角 Previewer 即可在模拟器中查看完整前端效果
#    或连接真机/模拟器运行 HAP
```

> **核心代码位置**：`entry/src/main/ets/pages/Index.ets`（全部页面逻辑在一个文件中）

## 1. 项目概述

**碎片 Box** 是一个基于 HarmonyOS ArkUI 的移动端应用 Demo，围绕"想法碎片化管理"这一核心概念，提供三个维度的交互体验：

- **放入碎片**：将灵感、观察、情绪等碎片化想法投入虚拟盲盒
- **个人碎片集合**：以瀑布流浏览已存档的碎片，或以关系图查看碎片之间的关联
- **碎片延伸树**：以层级树状结构展开社区共享的相似/相反经验，逐层深入探索

## 2. 技术栈

| 层面 | 技术选型 |
|------|----------|
| 运行环境 | HarmonyOS 5.0 (API 12) |
| 开发语言 | ArkTS |
| UI 框架 | ArkUI 声明式范式 ( `@Entry` / `@Component` / `@Builder` ) |
| 包名 | `com.example.fragmentbox` |
| 设备类型 | Phone |

## 3. 项目结构

```
FragmentBoxArkUIDemo/
├── AppScope/
│   └── app.json5                          # 应用级配置 (bundleName/icon/label)
├── build-profile.json5                    # 构建配置 (API 12, HarmonyOS)
├── entry/
│   ├── build-profile.json5
│   └── src/main/
│       ├── module.json5                   # 模块配置 (abilities/pages)
│       ├── ets/
│       │   ├── entryability/
│       │   │   └── EntryAbility.ets       # UIAbility 入口
│       │   └── pages/
│       │       └── Index.ets              # ★ 全部页面逻辑 (单页面架构)
│       ├── resources/base/
│       │   ├── element/
│       │   │   ├── color.json
│       │   │   └── string.json
│       │   ├── media/
│       │   │   └── app_icon.svg
│       │   └── profile/
│       │       └── main_pages.json        # 页面路由配置
│       └── module.json5
└── README.md
```

> **架构说明**：当前采用单页面架构，全部 3 个 Tab 页面、底部弹窗、Toast 等均定义在 `Index.ets` 的同一个 `@Entry @Component struct Index` 中，通过 `@State currentPage` 切换显示。

## 4. 数据模型

### 4.1 FragmentItem — 碎片数据

```typescript
class FragmentItem {
  id: string         // 编号 (01-06)
  tag: string        // 标签 (通勤观察 / 复盘经验 / 灵感脑洞 ...)
  text: string       // 碎片正文
  tone: string       // 情绪色调 (memory / self / idea)
  remind: string     // 提醒偏好 (通勤 / 睡前 / 周末)
  shared: boolean    // 是否匿名共享
  createdAt: string  // 创建日期
}
```

### 4.2 GraphNode / GraphEdge — 个人关系图

```typescript
class GraphNode {
  key: string           // 节点唯一标识
  label / name / tone   // 显示属性
  x / y                 // 坐标
  fragmentIndex: number // 关联的碎片索引
}

class GraphEdge {
  key / fromKey / toKey / color
}
```

### 4.3 CommunityNode — 社区延伸树节点

```typescript
class CommunityNode {
  key: string        // root / similar / opposite / action / metaphor / city / reply / silence
  parent: string     // 父节点 key
  title / tag / author / match / text / tone
  x / y / w / h      // (布局重构后不再使用绝对坐标)
}
```

### 4.4 辅助类

```typescript
class NodePosition { x, y, w, h }         // onAreaChange 动态位置追踪
class ChildLineInfo { cx, top }           // Canvas 连线子节点坐标
```

## 5. 页面体系与交互

### 5.1 全局状态

| 状态变量 | 类型 | 说明 |
|----------|------|------|
| `currentPage` | `AppPage` 枚举 | 当前 Tab: BOX / COLLECTION / COMMUNITY |
| `showInputSheet` | `boolean` | 是否显示底部"放入碎片"弹窗 |
| `activeIndex` | `number` | 当前高亮的碎片索引 |
| `graphMode` | `boolean` | 个人碎片集合是否处于关系图模式 |
| `expandedCommunityKeys` | `string[]` | 社区树中已展开的节点 key 列表 |
| `activeCommunityKey` | `string` | 社区树中当前选中节点 |
| `draftContent / draftTag / draftRemind` | `string` | 输入弹窗中的草稿状态 |
| `showToast / toastText` | — | 全局轻提示 |

页面切换通过 `PanGesture` 横向滑动实现，纵向滑动在 Box 页面无效（预留，由 List 组件内部处理滚动）。

### 5.2 Box 页面（首页）

- **视觉元素**：品牌徽标 "BOX" + 立体盲盒插图 + 标题"放入碎片"
- **盲盒插图**：`Image($r('app.media.app_icon'))` + 底部椭圆阴影 + 上下浮动动画 ( `setInterval` 切换 `translate.y` → `.animation()` 平滑过渡)
- **点击行为**：点击页面任意位置 → 弹出 `bindSheet` 半模态弹窗
- **交互提示**：副标题 "Drop a fragment"

```
┌─────────────────────┐
│  [BOX]              │  ← 品牌徽标
│                     │
│       🎁           │  ← 立体盲盒 (浮动动画)
│     ~阴影~          │  ← 椭圆阴影
│                     │
│    放入碎片          │  ← 主标题
│  Drop a fragment    │  ← 副标题
└─────────────────────┘
```

### 5.3 Collection 页面（个人碎片集合）

**模式一：瀑布流浏览**

| 组件 | 说明 |
|------|------|
| `WaterfallHeader` | 标题"个人碎片集合" + 切换到关系图按钮 |
| `List` (瀑布流) | `ForEach` 渲染 `FragmentWaterfallItem`，居中卡片高亮 |
| `WaterfallHintCard` | 底部提示卡片 "上下滑动，居中碎片会自动高亮" |
| `PageDots` | 页面指示器 (3 个圆点) |

瀑布流通过 `List.onScrollIndex` 检测可视区域中心碎片，自动更新 `activeIndex`。

**模式二：关系图**

| 组件 | 说明 |
|------|------|
| `GraphHeader` | 标题"脑洞关系网" + 返回按钮 |
| `GraphCard` (Canvas) | 绘制节点圆点 + 曲线连线，支持点击节点跳转碎片 |
| 背景装饰 | `WaterfallBackground` + `WaterfallOrbitLines` (轨道线) |

Canvas 绘制逻辑：
- `drawGraphCanvasNodes()`：绘制节点圆点，关联节点高亮/不关联节点半透明
- `drawGraphCanvasEdges()`：绘制曲线连线，激活边加粗
- `handleGraphCanvasTouch()`：触摸检测最近节点并选中

### 5.4 Community 页面（碎片延伸树）

**布局架构**（重构后）：

```
Stack (外层容器)
├── Circle (装饰背景)
└── Scroll (可滚动)
    └── Stack(alignContent: Top)  ← 连线与节点在同一滚动容器
        ├── Canvas (zIndex 0)     ← 绘制树形连线
        └── Column (zIndex 1)     ← 层级树节点
            ├── Row (Level 0): [Root 节点]
            ├── Row (Level 1): [相似] [相反] [行动]
            ├── Row (Level 2): ...
            └── ...
```

**核心机制**：

| 机制 | 实现方式 |
|------|----------|
| 树结构展开 | `getNodesByLevel()` 根据 `expandedCommunityKeys` 递归构建层级数组 |
| 节点定位 | 每个 `TreeNodeCard` 通过 `onAreaChange` 上报 `globalPosition` 存入 `Map<string, NodePosition>` |
| 连线绘制 | `drawTreeLines()` 遍历展开节点 → 计算父子相对坐标 → 在 Canvas 上绘制 L 型分支线 + 锚点圆点 |
| 连线随滚动 | Canvas 与 Column 同为 Scroll > Stack 子组件，共享滚动偏移 |
| 深度缩放 | `scale = 1.0 - (maxDepth - depth) × 0.05`，越上层越小 |
| 深度透明 | `opacity = 1.0 - (maxDepth - depth) × 0.12`，越上层越淡 |

**树结构数据**：

```
root (当前碎片)
├── similar (相似经验)
│   └── city (城市观察)
├── opposite (相反经验)
│   └── metaphor (延申比喻)
│       └── silence (轻复盘)
└── action (行动方向)
    └── reply (关系提醒)
```

**底部悬浮卡片 `SharedFragmentCard`**：
- 根据 `activeCommunityKey` 动态显示当前选择节点
- "收进 Box"：将社区节点保存为个人碎片
- "继续延伸"：展开下一层或提示到达末端

## 6. 底部弹窗（放入碎片 InputSheet）

### 6.1 弹窗配置

```typescript
.bindSheet($$this.showInputSheet, this.InputSheet(), {
  height: 560,
  showClose: false,
  dragBar: false,
  backgroundColor: 'rgba(0, 0, 0, 0.25)'  // 半透明遮罩
})
```

页面底层在弹窗打开时自动加模糊：`.blur(this.showInputSheet ? 3 : 0)`

### 6.2 弹窗内容结构

```
┌──────────────────────────────┐
│  放入碎片                  × │  ← 标题 + 关闭按钮
│                              │
│  ┌──────────────────────┐   │
│  │ 纸条质感输入区         │   │  ← TextArea
│  │ (微旋转 -1.8°)        │   │    纸张纹理背景
│  │ (非对称阴影)          │   │    墨水色文字
│  └──────────────────────┘   │
│                              │
│  Tag                         │
│  ┌──────────────────────┐   │
│  │ 例如: 通勤观察/情绪    │   │  ← TextInput
│  └──────────────────────┘   │
│                              │
│  提醒偏好                    │
│  [ 通勤 ] [ 睡前 ] [ 周末 ]  │  ← RemindPill 选项卡
│                              │
│  ┌──────────────────────┐   │
│  │      完成存档          │   │  ← 主按钮
│  └──────────────────────┘   │
└──────────────────────────────┘
```

### 6.3 视觉色彩规范

| 元素 | 色值 | 说明 |
|------|------|------|
| 标题文字 | `#1A1A1A` | 柔和深灰 |
| 关闭按钮 | 图标 `#666666`, 背景 `#F5F5F5` | 弱化视觉 |
| TextArea 背景 | `#FAFAF7` (暖纸色) | 待替换为 `paper_texture.png` |
| TextArea 文字 | `#333333` | 墨水质感 |
| 占位符文字 | `#A0A0A0` | 温和灰色 |
| 输入框背景 | `#F7F7F7` | 柔和浅灰 |
| 选中标签 | 文字 `#5A5A85` (莫兰迪紫蓝), 背景 `#EAEAF2` | 低饱和度 |
| 未选中标签 | 文字 `#999999`, 背景 `#F5F5F5` | 弱化 |
| 主按钮 | 背景 `#2C2C2C`, 文字 `#FFFFFF` | 深炭灰替代纯黑 |

## 7. 视觉效果与动效

| 效果 | 实现 | 应用位置 |
|------|------|----------|
| 背景毛玻璃 | `.blur(showInputSheet ? 3 : 0)` | 弹窗打开时全页 |
| 半透明遮罩 | `backgroundColor: 'rgba(0,0,0,0.25)'` | bindSheet 覆盖层 |
| 盲盒浮动 | `setInterval` + `.translate()` + `.animation()` | Box 页面盲盒插图 |
| 盲盒阴影 | `Ellipse` + `.blur(6)` | 盲盒下方 |
| 纸条旋转 | `.rotate({ angle: -1.8 })` | TextArea 容器 |
| 纸条阴影 | `.shadow({ offsetX: 3, offsetY: 5 })` | 非对称悬浮感 |
| 树节点景深 | `.scale()` + `.opacity()` 基于层级 | TreeNodeCard |
| 节点缩放过渡 | `.animation({ duration: 300, curve: EaseOut })` | 树展开/收起 |
| 连线平滑 | Canvas L 型分支线 + 锚点圆点 | 碎片延伸树 |
| 页面切换 | `.animation({ duration: 260 })` | PanGesture |

## 8. 关键交互流程

### 8.1 放入碎片
```
点击盲盒区域 → showInputSheet = true → bindSheet 弹出
→ 输入文字/Tag/选择提醒偏好 → 点击"完成存档"
→ archiveFragment() → fragments[] 增加新项
→ activeIndex 跳转到新碎片 → Toast 提示
```

### 8.2 瀑布流浏览
```
左右滑动切换页面 → currentPage 变化
Collection 页面内 List 滚动 → onScrollIndex 更新 activeIndex
点击"关系图"按钮 → graphMode = true → PersonalGraph 显示
触摸 Canvas 节点 → 切换 activeGraphNodeKey + activeIndex
```

### 8.3 碎片延伸树展开
```
点击未展开节点 → selectCommunityNode(key)
→ expandedCommunityKeys 增加 key → getNodesByLevel() 返回新层级
→ UI 渲染新 Row → onAreaChange 更新位置
→ setInterval + drawTreeLines() 绘制新连线
→ SharedFragmentCard 更新为当前节点内容
```

## 9. 待补充的素材资源

| 资源 | 用途 | 当前替代方案 |
|------|------|-------------|
| `mystery_box.png` | 立体盲盒插图 | `app_icon.svg` |
| `paper_texture.png` | 纸条纹理背景 | 纯色 `#FAFAF7` |

将 PNG 文件放入 `entry/src/main/resources/base/media/` 后，修改代码中的资源引用即可启用。

## 10. 代码关键约定

- **禁止使用** `Record<>` 泛型、对象字面量作为类型声明、索引签名接口 — ArkTS 编译器限制
- **禁止在 `@Builder`** 函数最外层写 `let` 声明 — 必须以 UI 组件开头
- **State 使用 `Map<>`** 替代索引对象 — ArkTS 不支持 `obj[key]` 语法
- 所有 `onAreaChange` 回调不加类型标注 (`oldArea: Area` → `oldArea`)
- 实体类 (`NodePosition`, `ChildLineInfo`) 用于替代内联对象字面量
