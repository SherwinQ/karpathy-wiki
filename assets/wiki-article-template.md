---
title: ARTICLE_TITLE
type: wiki
stage: compiled
entity_type: concept  # concept | person | tool | event | comparison | pattern | overview
domain: DOMAIN
domains:
  - DOMAIN
confidence: high      # high | medium | low
tags:
  - DOMAIN
  - wiki
  - TAG_1
  - TAG_2
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources:
  - "[[raw/YYYY-MM-DD_source_slug.md]]"
has_counter_arguments: false
---

# ARTICLE_TITLE

导语段：2-4 句话，说明这个主题是什么、为什么重要、本文覆盖什么范围。不要第一人称。不要 hype。陈述文章论点。

（可选）第二段展开核心洞察或文章要解决的张力。铺垫后续结构。

## 第一个核心章节

<!--
  按 entity_type 选择章节结构：
  - concept: 定义与核心思想 → 关键原理 → 应用与实例 → 关系
  - person:  简介 → 主要贡献 → 影响与关联 → 代表作品
  - tool:    概述 → 核心特性 → 架构 → 使用场景 → 生态系统
  - event:   概述 → 背景 → 经过 → 影响
  - comparison: 对比概述 → 对比表格 → 详细分析 → 结论
  - pattern: 问题 → 方案 → 权衡 → 示例 → 变体
  - overview: 领域定义 → 概念图谱 → 现状 → 挑战 → 缺口
  详见 references/entity-types.md
-->

实质内容。大量使用 [[wikilink]] 连接相关概念，包括跨领域链接。

### 子章节

技术深度。代码示例、图表、表格在有助于理解时使用。

```python
# 可运行的示例
def example():
    return "具体优于抽象"
```

## 第二个核心章节

继续展开论点或调研。保持双链密度。在有用时行内引用来源：

> 直接引用来源，附归属。 — [[raw/source_slug.md]]

### 对比表格

| 方案 | 优势 | 劣势 |
|------|------|------|
| A | X | Y |
| B | Z | W |

## 第三个核心章节

综合。识别权衡、模式或从材料中浮现的设计张力。

## Counter-Arguments & Data Gaps

<!--
  综合 3+ 来源或涉及争议性主题时建议添加。
  添加后将 frontmatter has_counter_arguments 改为 true。
-->

### 对立观点
- 针对本文核心论点的最强反驳
- 引用来源（如有）

### 数据缺口
- 本文论断缺少直接证据的部分
- 需要补充来源的方向

## 与其他知识的关联

- [[领域/相关文章1]] — 关联说明
- [[领域/相关文章2]] — 关联说明

## 开放问题

- 尚未解答的问题
- 需要进一步探索的方向

## 来源与延伸阅读

- [[raw/source_slug.md]] — 简述其贡献
- [[raw/another_source.md]] — 简述
- [[领域/相关文章]] — 更深入处理子主题
