# Frontmatter Schemas

所有 vault 中的笔记使用 YAML frontmatter 管理元信息。

## 约定

- `created` 和 `updated` 使用 ISO 日期格式 `YYYY-MM-DD`
- `tags` 始终包含领域标签 + 类型标签 + 主题标签
- `sources` 条目使用 wikilink 指向 `raw/` 中的文件
- `entity_type` 使用 7 种标准类型（见 `references/entity-types.md`）
- `domains` 支持跨领域标记，实现共享实体的图谱连接

---

## Wiki 文章 — `wiki/<领域>/<文章名>.md`

```yaml
---
title: 文章标题
type: wiki
stage: compiled
entity_type: concept  # concept | person | tool | event | comparison | pattern | overview
domain: <领域>
domains:              # 跨领域标记（如果文章跨越多个领域）
  - <领域>
  - <关联领域>
confidence: high      # high | medium | low — 来源充分性
tags:
  - <领域>
  - wiki
  - 主题标签1
  - 主题标签2
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources:
  - "[[raw/2026-04-05_source_slug.md]]"
  - "[[raw/2026-04-03_another_source.md]]"
has_counter_arguments: false  # 是否包含反论/数据缺口段落
---
```

### 字段说明

| 字段 | 必需 | 说明 |
|------|------|------|
| `title` | ✅ | 与 H1 标题一致 |
| `type` | ✅ | 固定为 `wiki` |
| `stage` | ✅ | 固定为 `compiled` |
| `entity_type` | ✅ | 实体类型，决定章节结构 |
| `domain` | ✅ | 主要所属领域 |
| `domains` | ❌ | 跨领域标记，仅在文章涉及多个领域时使用 |
| `confidence` | ❌ | 来源充分性评估。默认 `high` |
| `tags` | ✅ | 至少包含领域标签和 `wiki` |
| `created` | ✅ | 首次创建日期 |
| `updated` | ✅ | 最近一次更新日期 |
| `sources` | ✅ | 引用的原始资料 wikilink 列表 |
| `has_counter_arguments` | ❌ | Lint 时检查：综合 3+ 来源的文章建议包含反论 |

---

## 原始资料 — `raw/<YYYY-MM-DD>_<slug>.md`

```yaml
---
title: 资料标题
type: source
stage: raw
source_kind: article | paper | blog-post | github-readme | documentation | bookmark-cluster | transcript | report
source_url: https://example.com/article
scraped: YYYY-MM-DD
classified_as: concept  # Classify 步骤的结果
tags:
  - <领域>
  - raw
  - 主题标签
---
```

### 新增字段

| 字段 | 必需 | 说明 |
|------|------|------|
| `source_kind` | ✅ | 来源类型。新增 `transcript`（演讲/访谈记录）、`report`（报告） |
| `classified_as` | ❌ | Ingest Classify 步骤的结果，预判该来源最适合编译为哪种实体类型 |

---

## 查询输出 — `outputs/queries/<YYYY-MM-DD> <问题slug>.md`

```yaml
---
title: 查询标题
type: output
stage: query          # query | promoted
domain: <领域>
tags:
  - <领域>
  - output
  - query
created: YYYY-MM-DD
updated: YYYY-MM-DD
informed_by:
  - "[[领域/相关文章1]]"
  - "[[领域/相关文章2]]"
---
```

---

## Lint 报告 — `outputs/reports/<YYYY-MM-DD>-lint.md`

```yaml
---
title: Lint Report YYYY-MM-DD
type: output
stage: lint-report
domain: <领域>
tags:
  - <领域>
  - output
  - lint-report
created: YYYY-MM-DD
issues_found: N
issues_fixed: M
---
```

---

## 索引文件 — `wiki/index/*.md`

```yaml
---
title: Dashboard | Concept Index | Source Index
type: index
domain: <领域>
updated: YYYY-MM-DD
---
```

---

## 快速参考

| 文件类型 | 路径 | type | stage | entity_type |
|---------|------|------|-------|-------------|
| Wiki 文章 | `wiki/<领域>/` | `wiki` | `compiled` | 7 种之一 |
| 原始资料 | `raw/` | `source` | `raw` | — |
| 查询结果 | `outputs/queries/` | `output` | `query` / `promoted` | — |
| Lint 报告 | `outputs/reports/` | `output` | `lint-report` | — |
| 索引文件 | `wiki/index/` | `index` | — | — |
