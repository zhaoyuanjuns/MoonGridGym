# MoonGridGym 项目申报书

MoonGridGym 是一个使用 MoonBit 编写的轻量级 Gym 风格网格环境套件，面向 OSC2026 参赛展示场景设计，统一提供 `reset / step / render` 接口，并内置 `GridWorld`、`CliffWalking`、`Maze`、`FrozenLakeLike`、`RandomMaze`、`EmptyRoom` 和 `FourRooms` 等经典或可扩展环境。要求 MoonBit 0.10.3 及以上版本。

## 项目链接

- GitLink: https://gitlink.org.cn/zyjzyj78/MoonGridGym
- GitHub: https://github.com/zhaoyuanjuns/MoonGridGym

## 项目定位

本项目的目标不是做一个单点演示，而是提供一个结构清晰、便于扩展、便于测试、便于展示的 MoonBit 环境基础库。它既可以用于强化学习与路径规划的教学演示，也适合用于后续扩展更多网格类环境、策略评测工具和自动求解模块。

## 已完成内容

- 统一环境接口：`reset / step / render`
- 多个经典网格环境
- 随机迷宫生成，支持固定种子复现
- BFS 最短路径求解
- 回放与自动求解辅助接口
- 单元测试与黑盒测试
- GitHub Actions 持续集成
- MIT 许可证
- 源码来源说明与原创性说明

## 提交与合规说明

- 仓库默认分支为 `master`
- 提交历史仅保留单一贡献者
- 不包含虚拟贡献者
- 仓库结构、README、License、测试和 CI 已按 OSC2026 要求整理

## 结论

MoonGridGym 的实现规模与功能边界适合 OSC2026 参赛，也保留了继续扩展的空间。当前版本已具备完整的仓库展示形态，可以直接作为参赛项目提交基础。
