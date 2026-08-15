# MoonGridGym 本地验收复核记录

更新时间：2026-08-12。本文记录本地工作区的复核结果，不代表 GitHub、GitLink
或 mooncakes.io 已被修改。

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
- GitHub Actions 已包含格式、包信息、拒绝警告检查、测试和可运行示例；最新
  `master` 提交 `ee3d641` 的远程 CI 已成功通过：
  https://github.com/zhaoyuanjuns/MoonGridGym/actions/runs/31885057334
- `moon.mod` 模块名为 `zhaojingjun/moongridgym`，仓库地址、README 和许可证
  字段已填写。
- CliffWalking 到达目标时现在返回正奖励 `50`，跌入悬崖仍返回 `-100`，两种
  终止路径分别有回归测试。

## 仍不能在本地替代确认的验收项

- mooncakes.io 是否已经发布，以及发布版本是否与最终验收提交一致；当前本地已
  按邮件要求准备好 `zhaojingjun/moongridgym`，发布动作需在提交推送后执行。
- GitHub 已更新到最新提交；GitLink 的 `master` 仍为旧提交，推送时远端返回
  `Gitea: User permission denied for writing`，需要 `zyjzyj78` 仓库写权限。
- mooncakes.io 预发布检查已完成打包和本地解包验证，但服务器返回
  `User mismatch`：当前登录用户是 `zhaoyuanjuns`，而邮件要求的模块 namespace
  是 `zhaojingjun`；需要使用 `zhaojingjun` 账号重新登录后发布。
- 正式申报材料中提交的 GitHub/GitLink 链接、申请人账号和默认分支是否与组委会
  系统登记完全一致。

## 授权后的发布顺序

1. 先审阅本地工作区改动并形成一个有意义的提交。
2. 在 GitHub 和 GitLink 分别确认默认分支为 `master`，再按你的明确指令推送；不
   自动推送，也不执行任何 gitlink 操作。
3. 确认远程 CI 通过后，再按 `moon.mod` 的模块名发布到 mooncakes.io。
4. 记录发布版本、包页面和对应提交，作为 8 月 17 日最终验收证据。
