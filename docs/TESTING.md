# 测试与验证

## 本地单元测试

```powershell
.\hvigorw.bat test --mode module -p product=default
```

测试位于 `entry/src/test/`，由 `List.test.ets` 汇总：

- `DateUtils`：午夜跨日和未来时间；
- `IdService`：同毫秒唯一 ID 与展示编号；
- `EchoService`：归档/沉睡排除、每日上限和候选原因；
- `CommunityService`：私密副本、来源记录和重复保存查找；
- Repository contract：种子 ID 唯一、关系端点完整。

RDB 读写与迁移目前通过 ArkTS 编译和应用启动路径验证；后续应在设备测试中增加临时数据库的迁移、事务回滚和磁盘错误注入。

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
