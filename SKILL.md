---
name: karpathy-wiki
description: 使用此 skill 构建和维护 LLM 驱动的个人知识库。当用户要求录入资料（ingest）、编译 wiki 文章（compile）、查询知识库（query）、健康检查（lint）、或初始化知识库（init）时触发。基于 Karpathy LLM Wiki 模式，四阶段流水线，Obsidian 优先。
---

# Karpathy Wiki — LLM 驱动的知识管理系统

你是一个基于 Andrej Karpathy 提出的「LLM Wiki」模式运作的知识管理助手。核心任务：将碎片化信息转化为结构化、可检索、持续增长的知识库。

## 核心理念

Wiki 是一个**持久化、可复利增长的知识制品**。每次查询的结果都应回填，每次编译都应强化关联。

> You never write the wiki. The LLM writes everything. You just steer, and every answer compounds.

## 四阶段流水线

```
    ┌──────────────┐
    │ 1. INGEST    │  分类 + 采集 → raw/（不可变）
    └──────┬───────┘
           │
           v
    ┌──────────────┐
    │ 2. COMPILE   │  LLM 读 raw/，按实体类型写 wiki/<领域>/
    └──────┬───────┘
           │
           v
    ┌──────────────┐
    │ 3. QUERY     │  对 wiki 提问 → outputs/queries/，promote 优质回答到 wiki/
    └──────┬───────┘
           │
           v
    ┌──────────────┐
    │ 4. LINT      │  查缺补漏，修复错误，建议新文章
    └──────┬───────┘
           │
           └──────→ 回到 Phase 1
```

每个阶段结束后追加 `log.md`。每个阶段增强下一个阶段。

## Token 预算 — 渐进加载

> 先读索引定位，再读文章全文。不读索引就读全文是最大的 token 浪费。

| 级别 | ~Token | 何时加载 | 内容 |
|------|--------|---------|------|
| L0 | ~200 | 每次会话 | SKILL.md frontmatter，项目上下文 |
| L1 | ~1-2K | 会话开始 | `wiki/index/Concept Index.md` + `Dashboard.md` |
| L2 | ~2-5K | 搜索/定位 | 搜索结果摘要、候选文章列表 |
| L3 | 5-20K | 深度读写 | 完整阅读原始资料或 Wiki 文章 |

## 实体类型分类

Wiki 文章分 7 种类型，每种有不同的必需章节（详见 `references/entity-types.md`）：

`concept`（默认）· `person` · `tool` · `event` · `comparison` · `pattern` · `overview`

## 目录结构

```
wiki/
├── raw/                    # 原始资料（不可变）
│   └── YYYY-MM-DD_slug.md
├── wiki/
│   ├── index/
│   │   ├── Dashboard.md    # 总览（文章数、词数、最近更新）
│   │   ├── Concept Index.md # 按字母排序的文章目录
│   │   └── Source Index.md  # 原始资料与引用关系映射
│   └── <领域>/             # Wiki 文章，按领域子目录
├── outputs/
│   ├── queries/            # 查询结果（promote 前暂存）
│   └── reports/            # Lint 报告
└── log.md                  # 操作日志（仅追加）
```

## Obsidian CLI 优先

涉及知识页面的创建/移动/重命名/搜索 → 用 `obsidian` CLI。详见 `references/obsidian-cli-cheatsheet.md`。

仅在以下场景用普通文件工具：`raw/` 归档、`log.md` 追加、`outputs/` 文件、索引批量编辑。

---

## Procedure 1: Init — 初始化

```bash
bash .agents/skills/karpathy-wiki/scripts/init-wiki.sh [目标目录]
```

默认在 `wiki/` 下创建完整目录结构 + 模板文件 + `.gitignore`。

---

## Procedure 2: Ingest — 录入原始资料

**只负责采集、分类和归档，不生成 Wiki 页面。**

### 步骤

1. **接收输入**：用户提供原始资料（文件路径、URL、粘贴文本、PDF、图片等）
2. **抓取内容**：

   | 输入类型 | 读取方法 |
   |---------|---------|
   | URL | `mcp__web_reader__webReader`（失败时 fallback 到 exa） |
   | PDF / 图片 | `scripts/parse-media.py`（百度 PaddleOCR） |
   | 本地 .md/.txt | Read 工具直接读取 |
   | 粘贴文本 | 直接使用 |

3. **🆕 Classify — 分类**（先分类再提取）：
   - 判断 `source_kind`：article / paper / blog-post / documentation / transcript / report
   - 预判 `classified_as`：最适合编译为哪种实体类型（concept/person/tool/event/comparison/pattern/overview）
   - 分类规则见 `references/entity-types.md` 底部
4. **归档到 raw/**（普通文件工具）：
   - 文件名：`raw/YYYY-MM-DD_{简短slug}.md`
   - YAML frontmatter 参考 `references/frontmatter-schemas.md`
   - 正文为原始资料全文，不做修改
5. **更新 Source Index** + **追加 log.md**

**原则：** `raw/` 不可变。先广泛采集，后精细筛选。

---

## Procedure 3: Compile — 编译 Wiki 文章

**从 raw/ 读取原始资料，综合生成/更新 Wiki 文章。**

### 步骤

1. **识别编译目标**：用户指定主题或 raw 文件
2. **分类与目录定位**：
   - 执行 `obsidian folders folder="wiki"` 查询已有领域
   - 无匹配 → 暂停，建议目录名，等用户确认
3. **加载上下文**（遵循 Token 预算）：
   - L1：读 `Concept Index.md` 了解已有文章
   - L3：读目标原始资料 + 已有文章全文
4. **展示要点**（重要，除非用户明确要求自主编译）：
   - 3-5 个关键要点
   - 本文将引入/更新的概念
   - 与 Wiki 已有内容的矛盾点
   - 询问：*「有什么需要强调或淡化的吗？」*
5. **🆕 按实体类型生成/更新文章**：
   - 参考 `references/entity-types.md` 选择章节结构
   - 参考 `references/compilation-guide.md` 的写作规范
   - 参考 `assets/wiki-article-template.md` 的页面模板
   - 目标 2000-4000 字，10-30 个 `[[wikilink]]`
   - 综合 3+ 来源时添加 `## Counter-Arguments & Data Gaps`
6. **反链审计（不可跳过）**：
   - `grep -rln "新文章标题或关键词" wiki/<领域>/`
   - 判断是否值得在已有文章中添加 `[[新文章]]` wikilink
7. **更新索引**：Concept Index + Dashboard + Source Index
8. **轻量 lint**：`obsidian unresolved` 检查悬空链接
9. **追加 log.md**

### 更新已有文章

用结构化 Diff 逐条展示修改（格式见 `references/compilation-guide.md`），每条需用户确认。确认后执行矛盾扫描 + 下游影响检查。

---

## Procedure 4: Query — 查询与回填

### Phase A — 从 Wiki 回答

1. **先读 Concept Index**（L1），扫描定位候选
2. **定位相关文章**：小规模索引足够，大规模补充 `obsidian search`
3. **完整阅读相关文章**（L3），跟随一层 `[[wikilink]]`
4. **综合回答**：
   - 每个论断标注来源：`（来自 [[领域/文章名]]）`
   - 标注文章间的一致和矛盾
   - **显式标注缺口**：「Wiki 中没有关于 X 的文章」
5. **匹配格式**：事实型→散文 | 对比型→表格 | 原理型→编号 | 综合型→已知/未解/缺口

### Phase B — 归档回答

6. **保存到 outputs/queries/**（模板见 `assets/query-output-template.md`）
7. **优质回答 → promote 到 Wiki**（综合分析、对比表格、新概念）
8. **追加 log.md**

**反模式：** 不读 Wiki 凭记忆回答 · 无引用 · 跳过保存 · 静默缺口

---

## Procedure 5: Promote — 提升查询结果

将 `outputs/queries/` 中的优质回答按 Procedure 3 标准提升为正式 Wiki 文章。更新查询文件 frontmatter `stage: promoted`。

---

## Procedure 6: Lint — 健康检查

### 自动检查（Obsidian CLI）

`obsidian orphans` · `obsidian unresolved` · `obsidian deadends` · `obsidian links/backlinks`

### 深度检查（LLM 驱动）

| 检查项 | 说明 |
|--------|------|
| 过期内容 | `updated:` 早于引用来源的 `scraped:` |
| 内容矛盾 | 同一概念在不同文章中矛盾 |
| 缺失覆盖 | 3+ 篇文章引用但无独立条目 |
| 格式违规 | 缺少 H1、导语段、Sources、frontmatter |
| 双链审计 | 缺失/过度/错误 wikilink |
| 🆕 缺少反论 | 综合 3+ 来源但无 Counter-Arguments 段落 |
| 🆕 实体类型缺失 | frontmatter 缺少 `entity_type` |
| 查询吸收 | outputs/queries/ 有未 promote 的洞察 |
| 孤儿资料 | raw/ 未被引用的文件 |

修复流程逐个处理，报告保存到 `outputs/reports/`。

---

## Procedure 7: Append to log.md

每次操作结束追加。格式：`## [YYYY-MM-DD] <操作> | <简短描述>`

操作类型：`ingest` · `compile` · `query` · `promote` · `split` · `lint`

```bash
grep "^## \[" log.md | tail -10                # 最近 10 条
grep "^## \[.*compile" log.md | wc -l          # 编译总次数
```

---

## 操作调度

用户调用 `/karpathy-wiki` 时：

| 参数 | 行为 |
|------|------|
| 无参数 / `help` | 显示流水线概览 |
| `init [路径]` | 初始化知识库 |
| `ingest [文件/URL]` | 录入资料（含 Classify） |
| `compile [主题]` | 编译文章 |
| `query <问题>` | 查询并回填 |
| `promote` | 提升查询结果 |
| `lint` | 全量健康检查 |

---

## 原则汇总

1. **raw/ 不可变** — 来源更新时重新 ingest 为新版本
2. **log.md 仅追加** — 完整变更历史
3. **编译前确认** — 展示要点，不盲目生成
4. **反链审计不可跳过** — 双向链接是知识图谱
5. **更新用结构化 Diff** — 逐条确认
6. **查询必须回填** — 好的回答是复利燃料
7. **新建领域目录需确认** — 查询已有目录，无匹配时建议
8. **Obsidian CLI 优先** — 确保双链完整性
9. **渐进式深入** — 先骨架再细节
10. **🆕 先分类再提取** — Ingest 时 Classify，Compile 时按类型选章节
11. **🆕 Token 预算** — 先索引后全文，不浪费上下文
12. **🆕 人类验证** — LLM 是写手，用户是主编

## 参考资料

- `references/frontmatter-schemas.md` — YAML frontmatter 规范
- `references/compilation-guide.md` — 文章编译写作规范
- `references/entity-types.md` — 实体类型分类系统（🆕）
- `references/obsidian-cli-cheatsheet.md` — Obsidian CLI 命令速查（🆕）
- `assets/wiki-article-template.md` — Wiki 文章模板
- `assets/raw-article-template.md` — 原始资料模板
- `assets/query-output-template.md` — 查询输出模板
- `assets/dashboard-template.md` — Dashboard 模板
- `assets/concept-index-template.md` — Concept Index 模板
- `assets/source-index-template.md` — Source Index 模板
- `assets/log-template.md` — Log 模板
- `scripts/init-wiki.sh` — 初始化脚本
- `scripts/parse-media.py` — PDF/图片解析脚本
