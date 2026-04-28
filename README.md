# Karpathy Wiki — LLM 驱动的知识管理系统

> 基于 [Andrej Karpathy](https://github.com/karpathy) 提出的 [LLM Wiki 模式](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) 构建的 Agent Skill，通过四阶段流水线将碎片化信息转化为结构化、可检索、持续增长的个人知识库。

## 核心理念

Wiki 是一个**持久化、可复利增长的知识制品**，不是一次性问答工具。

> You never write the wiki. The LLM writes everything. You just steer, and every answer compounds.

## 四阶段流水线

```
    ┌──────────────┐
    │ 1. INGEST    │  分类 + 采集 → raw/（不可变）
    └──────┬───────┘
           │
           v
    ┌──────────────┐
    │ 2. COMPILE   │  两步分析 → LLM 读 raw/，按实体类型写 wiki/<领域>/
    └──────┬───────┘
           │
           v
    ┌──────────────┐
    │ 3. QUERY     │  对 wiki 提问 → outputs/queries/，promote 优质回答到 wiki/
    └──────┬───────┘
           │
           v
    ┌──────────────┐
    │ 4. LINT      │  查缺补漏，修复错误，图分析，建议新文章
    └──────┬───────┘
           │
           └──────→ 回到 Phase 1 或触发 Deep Research
```

每个阶段结束后追加 `log.md`，每个阶段增强下一个阶段，循环持续运行。

## 特性

### 核心特性

- **四阶段分离** — Ingest（采集）与 Compile（编译）解耦，可批量采集后统一编译
- **先分类再提取** — Ingest 时 Classify 来源类型和实体类型，Compile 时按类型选择章节结构
- **7 种实体类型** — concept · person · tool · event · comparison · pattern · overview，每种有不同的必需章节
- **Token 预算 / 渐进加载** — L0-L3 四级上下文管理，先索引后全文
- **Counter-Arguments** — 综合 3+ 来源的文章自动添加反论段落，防止偏见积累
- **YAML Frontmatter 规范** — entity_type、confidence、跨领域 domains，支持 Obsidian Dataview 动态查询
- **Obsidian CLI 优先** — 创建/移动/重命名通过 CLI 自动维护双链完整性
- **三级索引** — Dashboard（总览）、Concept Index（文章目录）、Source Index（资料映射）
- **查询回填 + Promote** — 查询结果先暂存，优质回答提升为正式 Wiki 文章
- **结构化 Diff 更新** — 更新已有文章时逐条展示 Current/Proposed/Reason/Source
- **反链审计** — 编译后自动扫描已有文章补充反向链接
- **PDF/图片解析** — 基于百度 PaddleOCR 的 Layout Parsing API

### 新增特性

- **purpose.md — 知识库灵魂** — 定义目标、核心问题、研究范围和演进论点，LLM 每次操作读取对齐
- **场景模板** — 4 种初始化模板（通用 / 学术研究 / 读书笔记 / 项目文档），一键启动不同场景
- **两步 Chain-of-Thought Compile** — 先结构化分析（实体、矛盾、关联），再生成文章，显著提升质量
- **SHA256 增量缓存** — 源文件内容哈希去重，跳过未变化的资料，节省 token
- **Deep Research** — 发现知识缺口 → 自动生成搜索策略 → 网络搜索 → Ingest → Compile 闭环
- **纯文本图分析** — 桥接节点、孤立页面、知识集群发现、惊喜连接，无 GUI 依赖
- **异步审阅队列** — LLM 标记需人工判断的条目，用户统一处理，不阻塞 Ingest
- **来源可追溯** — sources[] 驱动删除级联清理、更新溯源、Query 引用链
- **安全删除** — 3-method matching + 级联清理，删除源文件时自动清理所有引用链
- **未 promote 查询提醒** — Lint 显式列出未处理的优质回答，建议处理方式

## Token 预算

| 级别 | ~Token 量 | 何时加载 | 内容 |
|------|----------|---------|------|
| L0 | ~200 | 每次会话 | SKILL.md frontmatter |
| L1 | ~1-2K | 会话开始 | purpose.md + Concept Index + Dashboard |
| L2 | ~2-5K | 搜索/定位 | 搜索结果摘要 |
| L3 | 5-20K | 深度读写 | 完整文章或原始资料 |

## 实体类型系统

| 类型 | 适用场景 | 示例 |
|------|---------|------|
| `concept` | 抽象概念、理论、算法 | Transformer、反向传播 |
| `person` | 人物、团队、组织 | Andrej Karpathy、OpenAI |
| `tool` | 软件、框架、平台 | PyTorch、Obsidian |
| `event` | 发布、突破、历史节点 | GPT-4 发布 |
| `comparison` | 多方案对比分析 | PyTorch vs TensorFlow |
| `pattern` | 方法论、流程、最佳实践 | RAG 模式 |
| `overview` | 领域/子领域总览 | 大语言模型综述 |

## 目录结构

```
wiki/
├── purpose.md              # 知识库目标与方向（LLM 每次操作读取）
├── raw/                    # 原始资料（不可变）
│   └── YYYY-MM-DD_slug.md
├── wiki/
│   ├── index/
│   │   ├── Dashboard.md    # 总览
│   │   ├── Concept Index.md # 文章目录
│   │   └── Source Index.md  # 资料引用映射
│   └── <领域>/             # Wiki 文章
├── outputs/
│   ├── queries/            # 查询结果
│   └── reports/            # Lint 报告
├── .cache/                 # 增量缓存（已被 .gitignore 排除）
├── .gitignore              # Git 排除规则
├── .env                    # API 配置
└── log.md                  # 操作日志
```

## 安装

### 1. 安装 Skill

将 `karpathy-wiki/` 目录放入 Agent 的 skills 目录：

```bash
# 方式一：克隆到 .agents/skills/
git clone https://github.com/your-username/karpathy-wiki.git .agents/skills/karpathy-wiki

# 方式二：手动复制
cp -r karpathy-wiki/ .agents/skills/karpathy-wiki
```

本 Skill 遵循 [agentskills.io](https://agentskills.io) 开放规范，兼容 Claude Code、Cursor、Codex 等支持 SKILL.md 的工具。

### 2. 安装 Obsidian CLI（推荐）

1. 安装最新版 [Obsidian](https://obsidian.md)
2. 设置 → 通用 → 开启「Command line interface」
3. 注册 CLI（按提示将 Obsidian 加入 PATH）
4. 终端验证：`obsidian help`

### 3. 配置 PDF/图片解析（可选）

编辑知识库根目录下的 `.env` 文件，填入百度 PaddleOCR Layout Parsing API 的 URL 和 Token：

```env
LAYOUT_API_URL=https://your-api-url
LAYOUT_API_TOKEN=your-token
```

安装 Python 依赖：

```bash
pip install requests
```

## 快速开始

### 初始化知识库

```bash
cd ~/your-obsidian-vault

# 通用知识库
bash .agents/skills/karpathy-wiki/scripts/init-wiki.sh

# 学术研究模板
bash .agents/skills/karpathy-wiki/scripts/init-wiki.sh --template research

# 读书笔记模板
bash .agents/skills/karpathy-wiki/scripts/init-wiki.sh --template reading

# 项目文档模板
bash .agents/skills/karpathy-wiki/scripts/init-wiki.sh --template project

# 指定目录 + 模板
bash .agents/skills/karpathy-wiki/scripts/init-wiki.sh ~/my-wiki --template research
```

### 在 LLM Agent 中使用

```bash
# 切换到 vault 目录
cd ~/your-obsidian-vault

# 录入资料（自动分类 + 归档 + 哈希去重）
/karpathy-wiki ingest https://example.com/article

# 编译文章（两步：分析 → 生成）
/karpathy-wiki compile Transformer 架构

# 查询知识库（自动回填优质回答）
/karpathy-wiki query Transformer 和 RNN 的核心区别？

# 提升查询结果为正式文章
/karpathy-wiki promote

# 深度研究（搜索 → Ingest → Compile 闭环）
/karpathy-wiki research Mixture of Experts

# 安全删除源文件（级联清理引用链）
/karpathy-wiki delete raw/2026-04-01_old_article.md

# 健康检查（含图分析 + 审阅提醒）
/karpathy-wiki lint
```

### 资料类型支持

| 输入类型 | 读取方法 | 说明 |
|---------|---------|------|
| URL（网页） | `webReader` / Exa crawling | 优先 webReader，失败自动 fallback |
| PDF | `parse-media.py` | 百度 PaddleOCR Layout Parsing，转为 Markdown + 提取图片 |
| 图片 | `parse-media.py` | 百度 PaddleOCR OCR + 图表理解 |
| 本地 .md/.txt | Read 工具 | 直接读取 |
| 粘贴文本 | 直接使用 | 无需额外处理 |

## 在 Obsidian 中使用

知识库就是一个标准 Obsidian vault，所有 Obsidian 功能都可用：

| Obsidian 功能 | 对应知识库元素 |
|--------------|---------------|
| 图谱视图 | 看知识关联全貌，孤儿节点一目了然 |
| 反链面板 | 打开任意文章，看谁引用了它 |
| 全文搜索 | 快速定位内容 |
| Dataview 插件 | 基于 frontmatter（entity_type、confidence、domains）做动态查询 |
| 属性面板 | 查看/编辑 YAML frontmatter |

## 文件说明

```
karpathy-wiki/
├── SKILL.md                              # 主技能定义（四阶段流水线 + 操作规程）
├── README.md                             # 本文件
├── references/
│   ├── frontmatter-schemas.md            # YAML frontmatter 规范
│   ├── compilation-guide.md              # 文章编译写作规范
│   ├── entity-types.md                   # 实体类型分类系统（7 种类型）
│   └── obsidian-cli-cheatsheet.md        # Obsidian CLI 命令速查
├── assets/
│   ├── purpose-template.md               # purpose.md 通用模板
│   ├── purpose-research-template.md      # 学术研究场景模板
│   ├── purpose-reading-template.md       # 读书笔记场景模板
│   ├── purpose-project-template.md       # 项目文档场景模板
│   ├── wiki-article-template.md          # Wiki 文章模板
│   ├── raw-article-template.md           # 原始资料模板
│   ├── query-output-template.md          # 查询输出模板
│   ├── dashboard-template.md             # Dashboard 模板
│   ├── concept-index-template.md         # Concept Index 模板
│   ├── source-index-template.md          # Source Index 模板
│   └── log-template.md                   # Log 模板
└── scripts/
    ├── init-wiki.sh                      # 初始化脚本（含 --template 模板选择）
    └── parse-media.py                    # PDF/图片解析脚本（PaddleOCR）
```

## 设计原则

1. **raw/ 不可变** — 原始记录不编辑，来源更新时重新 ingest
2. **log.md 仅追加** — 完整变更历史，不修改历史条目
3. **purpose.md 锚定方向** — 每次操作读取，确保与知识库目标一致
4. **先分类再提取** — Ingest 时判断来源和实体类型，Compile 按类型选章节
5. **编译前分析** — 先结构化分析后生成，不盲目输出
6. **反链审计不可跳过** — 双向链接是知识图谱，单向链接是博客
7. **更新用结构化 Diff** — Current / Proposed / Reason / Source，逐条确认
8. **查询必须回填** — 好的回答是复利燃料
9. **Token 预算** — 先索引后全文，渐进加载
10. **人类验证** — LLM 是写手，用户是主编
11. **渐进式深入** — 先建立骨架，再逐步补充细节
12. **增量缓存** — 哈希去重，跳过未变化的资料
13. **来源可追溯** — sources[] 是删除、更新、溯源的基础
14. **缺口驱动研究** — 发现缺口 → 自动填补，知识库持续生长

## 致谢

- [Andrej Karpathy](https://github.com/karpathy) — [LLM Wiki: Knowledge Base Pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [pedronauck/skills](https://github.com/pedronauck/skills) — karpathy-kb 技能（四阶段分离、结构化 Diff、反链审计等设计的参考来源）
- [bluewater8008](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f?permalink_comment_id=6079549#gistcomment-6079549) — Token 预算、实体类型分类、先分类再提取等最佳实践
- [localwolfpackai](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f?permalink_comment_id=6079697#gistcomment-6079697) — Counter-Arguments 偏见检测机制
- [nashsu/llm_wiki](https://github.com/nashsu/llm_wiki) — purpose.md、两步 Chain-of-Thought、增量缓存、知识图谱分析、Deep Research 等设计的灵感来源
- [百度 PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) — PDF/图片 Layout Parsing

## License

MIT
