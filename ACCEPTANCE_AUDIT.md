# MoonGridGym 本地验收复核记录

更新时间：2026-08-15。本文记录本地工作区、GitHub 和 Mooncakes 的复核结果；
申报书文件未修改。

## 已验证通过

- MoonBit 工具链为 0.10.3，符合项目要求。
- `moon fmt --check`、`moon info`、`moon check --deny-warn`、
  `moon test --deny-warn` 均通过。
- `moon run cmd/main` 可运行，输出 `valid=true`，6 个确定性场景的规划执行门
  通过；FrozenLakeLike 的随机滑动被单独作为随机环境处理。
- 36 个自动化测试通过，覆盖七个场景、策略基准、边界动作、随机种子复现、
  数据集导出、编码、合约和发布门禁。
- `.mbt` 源码和测试共 3,106 行，新增内容均属于环境、规划、评测、数据和验收
  工具；不是空函数或重复代码。
- 根目录 MIT `LICENSE` 清晰；`docs-source-provenance.md` 声明无复制的上游代码、
  无不明生成贡献者，并说明未来引用上游时的披露义务。
- GitHub Actions 已包含格式、包信息、拒绝警告检查、测试和可运行示例；功能提交
  `e3ab489` 的远程 CI 已成功通过：
  https://github.com/zhaoyuanjuns/MoonGridGym/actions/runs/31885245531
- `moon.mod` 模块名为 `zhaoyuanjuns/moongridgym`，仓库地址、README 和许可证
  字段已填写。
- CliffWalking 到达目标时现在返回正奖励 `50`，跌入悬崖仍返回 `-100`，两种
  终止路径分别有回归测试。

## 当前外部状态

- `zhaoyuanjuns/moongridgym` 版本 `0.1.1` 已通过打包、解包复核并由
  `moon publish` 返回 `200 OK`。
- GitHub `master` 已更新到 `e3ab489`，远程 CI 已成功。
- GitLink 的 `master` 仍为旧提交 `b871e36`。标准 token/basic 认证返回
  `Verify / Authentication failed`，因此该镜像仍需要有效的 GitLink 写入凭据或
  仓库授权。
- 正式申报材料中提交的 GitHub/GitLink 链接、申请人账号和默认分支是否与组委会
  系统登记完全一致。

## GitLink 剩余处理

确认 GitLink 账号对 `zyjzyj78/MoonGridGym` 具有写权限并登录后，在当前工作区执行：

```bash
git push gitlink master
```

成功后应核对 GitHub 与 GitLink 的 `master` 都指向 `e3ab489`，并将 GitHub、
GitLink、Mooncakes 版本 `0.1.1` 一并作为最终验收证据。
