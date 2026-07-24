# AI 网关部署

## 为什么必须经过网关

HarmonyOS 客户端不直接访问 DeepSeek 或 DashScope。移动安装包可以被反编译，任何写入源码、资源文件或构建参数的提供商密钥最终都可能泄漏。

当前链路为：

```text
HarmonyOS 客户端
  → HTTPS + 网关访问口令
Cloudflare Worker
  → DEEPSEEK_API_KEY
DeepSeek JSON 分析
  → DASHSCOPE_API_KEY
DashScope text-embedding-v4
```

DeepSeek、DashScope 和网关访问口令都通过 Cloudflare Worker Secret 保存。Worker 会在调用提供商前执行请求大小限制、结构校验、固定时间鉴权和每分钟限流；日志只记录请求 ID、碎片 ID 和向量维度，不记录碎片正文或密钥。

## 前置条件

- Node.js 22 或更高版本；
- pnpm；
- 已登录的 Cloudflare 账号；
- 已重新生成且未公开的 DeepSeek 与 DashScope API Key；
- 一个由密码管理器生成的高熵随机网关访问口令。

不要继续使用曾出现在聊天、截图、日志或 Git 历史中的密钥。

## 本地验证

```powershell
cd ai-gateway
pnpm install --frozen-lockfile
pnpm run check
```

`check` 会重新生成 Worker 类型、执行 TypeScript 检查、运行自动化测试并执行 Wrangler 部署 dry-run。

## 配置 Secret

先登录：

```powershell
wrangler login
```

再分别执行以下命令，并在 Wrangler 的安全输入提示中粘贴新值：

```powershell
wrangler secret put DEEPSEEK_API_KEY
wrangler secret put DASHSCOPE_API_KEY
wrangler secret put FRAGMENT_GATEWAY_TOKEN
```

不要把 Secret 写进 `wrangler.jsonc`、`.dev.vars.example`、命令历史或提交记录。

## 部署

```powershell
wrangler deploy
```

部署完成后先访问：

```text
https://<worker-domain>/health
```

应返回 `ok: true`、DeepSeek 模型、嵌入模型和维度。随后在应用 Box 页点击“幕后整理”，填写：

- 网关地址：Worker 的 HTTPS 根地址，不带末尾 `/`；
- 网关访问口令：`FRAGMENT_GATEWAY_TOKEN` 的值。

应用只持久化网关 URL。访问口令仅保留在本次运行内存中，退出应用后需要重新输入。

## 当前提供商配置

| 用途 | 配置 |
| --- | --- |
| 文本分析 | DeepSeek `deepseek-v4-flash` |
| DeepSeek Base URL | `https://api.deepseek.com` |
| 向量模型 | DashScope `text-embedding-v4` |
| DashScope Base URL | `https://dashscope.aliyuncs.com/compatible-mode/v1` |
| 向量维度 | `1024` |
| 提供商超时 | `20000 ms` |
| 网关限流 | 每个口令 60 秒 30 次 |

修改模型或向量维度后必须同时迁移或清理本机既有向量。相似度服务只比较模型与维度都一致的向量，避免不同向量空间被错误混用。

## 数据行为

1. 碎片先写入本机数据库；
2. 用户对本张碎片明确选择“允许 AI 整理”；
3. 客户端记录 AI 授权，并只上传本张内容、标签和提醒偏好；
4. Worker 并发获取 DeepSeek 结构化分析和 DashScope 向量；
5. 客户端验证 1024 维向量并写入 ArkData；
6. 相似度计算完全在本机进行，不会为匹配而批量上传历史碎片；
7. AI 或网络失败不会回滚已经保存的本地碎片。
