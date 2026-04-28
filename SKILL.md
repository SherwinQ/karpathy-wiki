---
name: karpathy-wiki
description: 使用此 skill 构建和维护 LLM 驱动的个人知识库。当用户要求录入资料（ingest）、编译 wiki 文章（compile）、查询知识库（query）、健康检查（lint）、深度研究（research）、初始化知识库（init）时触发。基于 Karpathy LLM Wiki 模式，四阶段流水线，Obsidian 优先。
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
    │ 2. COMPILE   │  分析 → LLM 读 raw/，按实体类型写 wiki/<领域>/
    └──────┬───────┘
           │
           v
    ┌──────────────┐
    │ 3. QUERY     │  对 wiki 提问 → outputs/queries/，promote 优质回答到 wiki/
    └──────┬───────┘
           │
           v
    ┌──────────────┐
    │ 4. LINT      │  查缺补漏，修复错误，建议新文章，图分析
    └──────┬───────┘
           │
           └──────→ 回到 Phase 1 或触发 Deep Research
```

每个阶段结束后追加 `log.md`。每个阶段增强下一个阶段。

## Token 预算 — 渐进加载

> 先读索引定位，再读文章全文。不读索引就读全文是最大的 token 浪费。

| 级别 | ~Token | 何时加载 | 内容 |
|------|--------|---------|------|
| L0 | ~200 | 每次会话 | SKILL.md frontmatter，项目上下文 |
| L1 | ~1-2K | 会话开始 | `purpose.md` + `wiki/index/Concept Index.md` + `Dashboard.md` |
| L2 | ~2-5K | 搜索/定位 | 搜索结果摘要、候选文章列表 |
| L3 | 5-20K | 深度读写 | 完整阅读原始资料或 Wiki 文章 |

## 实体类型分类

Wiki 文章分 7 种类型，每种有不同的必需章节（详见 `references/entity-types.md`）：

`concept`（默认）· `person` · `tool` · `event` · `comparison` · `pattern` · `overview`

## 目录结构

```
wiki/
├── purpose.md              # 知识库目标与方向（LLM 每次操作读取）
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
├── .cache/                 # 增量缓存（content_hash 索引）
├── .gitignore              # Git 排除规则
├── .env                    # API 配置
└── log.md                  # 操作日志（仅追加）
```

## Obsidian CLI 优先

涉及知识页面的创建/移动/重命名/搜索 → 用 `obsidian` CLI。详见 `references/obsidian-cli-cheatsheet.md`。

仅在以下场景用普通文件工具：`raw/` 归档、`log.md` 追加、`outputs/` 文件、索引批量编辑、`.cache/` 操作。

---

## Procedure 1: Init — 初始化

```bash
bash .agents/skills/karpathy-wiki/scripts/init-wiki.sh [目标目录] [--template <模板名>]
```

可用模板：`general`（默认）· `research` · `reading` · `project`

默认在 `wiki/` 下创建完整目录结构 + 模板文件 + `purpose.md` + `.gitignore` + `.cache/`。

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

3. **计算内容哈希**（增量缓存）：
   - 对正文内容计算 SHA256
   - 检查 `.cache/content_hashes.json` 是否已有相同哈希
   - 已存在 → 跳过归档，告知用户「该资料已录入」并指向已有文件
   - 不存在 → 继续，将哈希存入缓存
4. **Classify — 分类**（先分类再提取）：
   - 判断 `source_kind`：article / paper / blog-post / documentation / transcript / report
   - 预判 `classified_as`：最适合编译为哪种实体类型（concept/person/tool/event/comparison/pattern/overview）
   - 分类规则见 `references/entity-types.md` 底部
5. **归档到 raw/**（普通文件工具）：
   - 文件名：`raw/YYYY-MM-DD_{简短slug}.md`
   - YAML frontmatter 参考 `references/frontmatter-schemas.md`
   - 正文为原始资料全文，不做修改
   - **frontmatter 包含 `content_hash` 字段**
6. **标记审阅状态**（Review 队列）：
   - 如果分类不确定或来源重要性需判断 → frontmatter 设 `review_status: pending`
   - 如果来源明确、类型清晰 → `review_status: resolved`
7. **更新 Source Index** + **追加 log.md**

**原则：** `raw/` 不可变。先广泛采集，后精细筛选。哈希去重避免重复录入。

---

## Procedure 3: Compile — 编译 Wiki 文章

**从 raw/ 读取原始资料，经两步分析后生成/更新 Wiki 文章。**

### 步骤

#### Step 1: Analysis（结构化分析）

1. **识别编译目标**：用户指定主题或 raw 文件
2. **分类与目录定位**：
   - 执行 `obsidian folders folder="wiki"` 查询已有领域
   - 无匹配 → 暂停，建议目录名，等用户确认
3. **加载上下文**（遵循 Token 预算）：
   - L1：读 `purpose.md` + `Concept Index.md` 了解知识库目标和已有文章
   - L3：读目标原始资料 + 已有文章全文
4. **增量缓存检查**：
   - 读取 raw 文件的 `content_hash`
   - 对比 `.cache/compiled_hashes.json`（已编译过的源文件哈希）
   - 哈希未变化 → 跳过该源文件，告知用户
   - 哈希变化或首次编译 → 继续
5. **输出结构化分析结果**（展示给用户确认）：
   - **关键实体与概念**：资料中的核心要素
   - **与现有 Wiki 的关联**：哪些已有文章会受影响
   - **矛盾点**：新资料与已有知识的冲突
   - **建议操作**：新建文章 vs 更新已有文章，推荐实体类型
   - **Review 项**：需要用户判断的决策点
   - 询问：*「分析结果是否符合预期？有什么需要强调或淡化的吗？」*

#### Step 2: Generation（生成/更新文章）

6. **按实体类型生成/更新文章**（基于 Step 1 的分析结果）：
   - 参考 `references/entity-types.md` 选择章节结构
   - 参考 `references/compilation-guide.md` 的写作规范
   - 参考 `assets/wiki-article-template.md` 的页面模板
   - **对齐 `purpose.md`** — 生成内容应服务知识库目标，偏离目标的内容降低权重
   - 目标 2000-4000 字，10-30 个 `[[wikilink]]`
   - 综合 3+ 来源时添加 `## Counter-Arguments & Data Gaps`
7. **反链审计（不可跳过）**：
   - `grep -rln "新文章标题或关键词" wiki/<领域>/`
   - 判断是否值得在已有文章中添加 `[[新文章]]` wikilink
8. **更新索引**：Concept Index + Dashboard + Source Index
9. **更新编译缓存**：将已编译源文件的 content_hash 写入 `.cache/compiled_hashes.json`
10. **轻量 lint**：`obsidian unresolved` 检查悬空链接
11. **追加 log.md**

### 更新已有文章

用结构化 Diff 逐条展示修改（格式见 `references/compilation-guide.md`），每条需用户确认。确认后执行矛盾扫描 + 下游影响检查 + **引用链清理**（见 Procedure 8）。

---

## Procedure 4: Query — 查询与回填

### Phase A — 从 Wiki 回答

1. **读取 purpose.md**（L0-L1），确保回答方向与知识库目标一致
2. **先读 Concept Index**（L1），扫描定位候选
3. **定位相关文章**：小规模索引足够，大规模补充 `obsidian search`
4. **完整阅读相关文章**（L3），跟随一层 `[[wikilink]]`
5. **综合回答**：
   - 每个论断标注来源：`（来自 [[领域/文章名]]）`
   - 标注文章间的一致和矛盾
   - **显式标注缺口**：「Wiki 中没有关于 X 的文章」
   - 缺口处建议是否触发 Deep Research
6. **匹配格式**：事实型→散文 | 对比型→表格 | 原理型→编号 | 综合型→已知/未解/缺口

### Phase B — 归档回答

7. **保存到 outputs/queries/**（模板见 `assets/query-output-template.md`）
8. **优质回答 → promote 到 Wiki**（综合分析、对比表格、新概念）
9. **追加 log.md**

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
| 缺少反论 | 综合 3+ 来源但无 Counter-Arguments 段落 |
| 实体类型缺失 | frontmatter 缺少 `entity_type` |
| 查询吸收 | outputs/queries/ 有未 promote 的洞察（逐条列出，建议处理方式） |
| 孤儿资料 | raw/ 未被引用的文件 |
| 审阅积压 | raw/ 中 `review_status: pending` 的条目 |
| Purpose 对齐 | 文章内容偏离 purpose.md 定义的目标方向 |

### 图分析（纯文本）

基于 wikilink 拓扑的结构分析，无需 GUI：

**1. 桥接节点识别**
```
# 统计每篇文章链接到多少个不同领域
grep -roh '\[\[[^/\]]*/' wiki/ | sort | uniq -c | sort -rn
# 链接到 3+ 不同领域的文章 = 桥接节点（知识库关键枢纽）
```

**2. 孤立/低连接页面**
```
# 出链 ≤ 1 的文章
grep -rl '\[\[' wiki/ | while read f; do
  links=$(grep -o '\[\[[^]]*\]\]' "$f" | wc -l)
  [ "$links" -le 1 ] && echo "$links $f"
done
```

**3. 被引用最多但无独立条目的概念**
```
# 查找 [[概念名]] 但概念名.md 不存在
grep -roh '\[\[([^/\]|]*)\]\]' wiki/ | sort | uniq -c | sort -rn | head -20
```

**4. 知识集群发现**
- 基于双链拓扑，识别紧密互连的文章群组
- 跨集群的「惊喜连接」— 不同知识领域之间的意外关联
- 报告格式：集群名称 → 成员列表 → 内聚度 → 跨集群连接

**5. 知识缺口推荐**
- 桥接节点和低连接页面建议补充 Deep Research
- 孤立集群建议补充跨领域链接

修复流程逐个处理，报告保存到 `outputs/reports/`。

---

## Procedure 7: Research — 深度研究

**发现知识缺口后自动填补的闭环机制。**

### 触发条件

- Lint 发现知识缺口（被引用但无独立条目的概念）
- 用户主动要求 `research <主题>`
- Compile 的分析步骤发现 Wiki 缺少关键背景
- Query 发现显性缺口

### 步骤

1. **读取上下文**：
   - L1：读 `purpose.md` + `overview`（如有）+ `Concept Index.md`
   - 目的：生成与知识库目标和现有内容对齐的搜索查询
2. **生成搜索策略**：
   - 基于 purpose.md 生成 3-5 个研究问题
   - 每个问题生成 2-3 个搜索查询
   - 展示给用户确认，可编辑调整
3. **执行搜索**：
   - 逐个查询调用 web 搜索工具
   - 收集搜索结果（标题 + URL + 摘要）
4. **筛选与 Ingest**：
   - 过滤掉低质量/重复结果
   - 对每个有价值的结果执行 Ingest（Procedure 2）
5. **自动 Compile**：
   - 对新 Ingest 的资料执行 Compile（Procedure 3）
   - 特别关注填补触发研究时的缺口
6. **追加 log.md**（标记 `research` 操作类型）

---

## Procedure 8: Delete — 删除与级联清理

**安全删除源文件并清理所有引用链。**

### 步骤

1. **定位关联页面**（3-method matching）：
   - 方法 A：frontmatter `sources[]` 字段包含被删文件的所有 wiki 页面
   - 方法 B：以被删源文件名为标题的 Source Summary 页面
   - 方法 C：正文中引用被删资料的段落
2. **分级处理**：
   - **仅引用被删资料的页面** → 删除页面，清理索引
   - **多源页面**（引用被删资料 + 其他资料）→ 仅从 `sources[]` 移除被删资料，保留页面
   - **Source Summary 页面** → 删除
3. **清理索引**：从 Concept Index、Dashboard、Source Index 移除相关条目
4. **清理 wikilink**：删除指向已删页面的 `[[wikilinks]]`
5. **清理缓存**：从 `.cache/content_hashes.json` 和 `.cache/compiled_hashes.json` 移除
6. **追加 log.md**

---

## Procedure 9: Append to log.md

每次操作结束追加。格式：`## [YYYY-MM-DD] <操作> | <简短描述>`

操作类型：`ingest` · `compile` · `query` · `promote` · `research` · `delete` · `lint`

```bash
grep "^## \[" log.md | tail -10                # 最近 10 条
grep "^## \[.*compile" log.md | wc -l          # 编译总次数
grep "^## \[.*research" log.md | wc -l         # 研究总次数
```

---

## 操作调度

用户调用 `/karpathy-wiki` 时：

| 参数 | 行为 |
|------|------|
| 无参数 / `help` | 显示流水线概览 |
| `init [路径] [--template <名>]` | 初始化知识库（可选模板） |
| `ingest [文件/URL]` | 录入资料（含 Classify + 哈希去重） |
| `compile [主题]` | 两步编译：分析 → 生成文章 |
| `query <问题>` | 查询并回填 |
| `promote` | 提升查询结果 |
| `research <主题>` | 深度研究：搜索 → Ingest → Compile |
| `delete <源文件>` | 安全删除 + 级联清理 |
| `lint` | 全量健康检查 + 图分析 |

---

## 原则汇总

1. **raw/ 不可变** — 来源更新时重新 ingest 为新版本
2. **log.md 仅追加** — 完整变更历史
3. **purpose.md 锚定方向** — 每次操作读取，确保与知识库目标一致
4. **编译前分析** — 先分析后生成，不盲目输出
5. **反链审计不可跳过** — 双向链接是知识图谱
6. **更新用结构化 Diff** — 逐条确认
7. **查询必须回填** — 好的回答是复利燃料
8. **新建领域目录需确认** — 查询已有目录，无匹配时建议
9. **Obsidian CLI 优先** — 确保双链完整性
10. **渐进式深入** — 先骨架再细节
11. **先分类再提取** — Ingest 时 Classify，Compile 时按类型选章节
12. **Token 预算** — 先索引后全文，不浪费上下文
13. **人类验证** — LLM 是写手，用户是主编
14. **增量缓存** — 哈希去重，跳过未变化的资料
15. **来源可追溯** — sources[] 是所有后续操作（删除、更新、溯源）的基础
16. **缺口驱动研究** — 发现缺口 → 自动填补，知识库持续生长

## 参考资料

- `references/frontmatter-schemas.md` — YAML frontmatter 规范
- `references/compilation-guide.md` — 文章编译写作规范
- `references/entity-types.md` — 实体类型分类系统
- `references/obsidian-cli-cheatsheet.md` — Obsidian CLI 命令速查
- `assets/purpose-template.md` — purpose.md 通用模板
- `assets/purpose-research-template.md` — 学术研究场景模板
- `assets/purpose-reading-template.md` — 读书笔记场景模板
- `assets/purpose-project-template.md` — 项目文档场景模板
- `assets/wiki-article-template.md` — Wiki 文章模板
- `assets/raw-article-template.md` — 原始资料模板
- `assets/query-output-template.md` — 查询输出模板
- `assets/dashboard-template.md` — Dashboard 模板
- `assets/concept-index-template.md` — Concept Index 模板
- `assets/source-index-template.md` — Source Index 模板
- `assets/log-template.md` — Log 模板
- `scripts/init-wiki.sh` — 初始化脚本（含模板选择）
- `scripts/parse-media.py` — PDF/图片解析脚本
