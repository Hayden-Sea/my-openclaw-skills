# My OpenClaw Skills

我在使用 OpenClaw 过程中创建的 custom skills 集合。

## 简介

这个仓库包含我为自己定制的 OpenClaw skills，用于增强 AI 助手的能力。所有 skills 都经过实际使用验证，针对我的工作流程优化。

## 已有的 Skills

| Skill | 描述 | 状态 |
|-------|------|------|
| [window-screenshot](./skills/window-screenshot) | Windows 窗口截图工具，使用 BitBlt API 捕获屏幕，支持 DPI 缩放校正 | ✅ 已完成 |

## 快速开始

### 安装 Skills

```bash
# 克隆仓库
git clone https://github.com/Hayden-Sea/my-openclaw-skills.git
cd my-openclaw-skills

# 复制 skills 到 OpenClaw
cp -r skills/* /path/to/openclaw/workspace/skills/
```

### 使用 Skills

每个 skill 目录下都有独立的 `SKILL.md` 文档，描述其用途和使用方法。

## 新增 Skill 流程

1. **创建 Skill**：在 `skills/` 目录下创建新文件夹
2. **必需文件**：
   - `SKILL.md` - Skill 文档（用途、使用方法、示例）
   - `skill.json` - 元数据
   - `<skill-name>.ps1` 或其他可执行文件
3. **更新 README**：添加 skill 到上面的表格中
4. **测试**：确保在本地 OpenClaw 中正常工作
5. **推送**：提交并推送到 GitHub

## 维护规则

- ✅ **README 同步**：每次新增或修改 skill 后，必须更新本 README
- ✅ **测试优先**：新 skill 需在本地验证后再推送
- ✅ **文档完整**：每个 skill 必须有清晰的 SKILL.md

## 目录结构

```
my-openclaw-skills/
├── README.md              # 本文档
├── LICENSE               # MIT License
└── skills/
    └── window-screenshot/
        ├── SKILL.md      # Skill 文档
        ├── skill.json    # 元数据
        └── screenshot.ps1 # 可执行脚本
```

## 联系我

- GitHub: [@Hayden-Sea](https://github.com/Hayden-Sea)
- OpenClaw: 用于个人 AI 助手定制
