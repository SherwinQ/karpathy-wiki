# Changelog

## 2026-04-28 — 借鉴 llm_wiki 设计优化

对比 [nashsu/llm_wiki](https://github.com/nashsu/llm_wiki) 项目，借鉴其设计思想和功能，对本项目做优化改进。

### 1. purpose.md — 知识库方向锚定

新增 `purpose.md` 机制和 4 种场景模板。定义知识库目标、核心问题、研究范围和演进论点。LLM 每次 Compile 和 Query 时读取 purpose.md，确保输出对齐知识库目标。

### 2. 两步 Chain-of-Thought Compile

将 Compile 从单步生成重构为 Analysis → Generation 两步。第一步输出结构化分析（关键实体、矛盾点、建议操作），用户确认后再生成文章。

### 3. SHA256 增量缓存

在 raw/ frontmatter 新增 `content_hash` 字段，Ingest 时哈希去重，Compile 时跳过未变化的源文件。

### 4. Deep Research 闭环

新增 `research <主题>` 命令：读取上下文 → 生成搜索策略 → web 搜索 → 自动 Ingest → 自动 Compile。由 Lint 缺口、Query 缺口或用户主动触发。

### 5. 纯文本图分析增强 Lint

新增基于 wikilink 拓扑的图分析：桥接节点、孤立页面、缺失概念、知识集群发现。无 GUI 依赖。

### 6. SKILL.md 规范重构

按 agentskills.io 规范重构：description 改为英文触发式条件、删除角色定义、新增 When to Use 章节、原则从 16 条压缩为 8 条、操作规程下沉到 `references/operations.md`，SKILL.md 从 1506 词瘦身到 589 词。

### 7. 场景模板 + init-wiki.sh 增强

`init-wiki.sh` 新增 `--template` 参数，支持 4 种场景模板（general/research/reading/project）。修复不可见字符 bug。

### 8. 异步审阅队列

在 raw/ frontmatter 新增 `review_status` 和 `review_notes` 字段。Lint 时扫描 pending 条目提醒用户。

### 9. 安全删除 + 级联清理

新增 Delete 操作：3-method matching 定位关联页面，分级处理，清理索引 + wikilink + 缓存 + 源文件。

### 10. Source Traceability 强化

强化 `sources[]` 字段价值：Lint 检查完整性、Delete 级联清理、Query 引用关联。

### 11. Bug 修复

- 图分析 grep 正则错误 → 改为可移植的提取 + find 检查
- 旧 vault 缺少 purpose.md 时 Compile/Query 报错 → 增加 fallback
- log-template.md 操作类型不同步 → 补齐 research、delete
