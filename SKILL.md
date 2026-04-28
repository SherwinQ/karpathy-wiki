---
name: karpathy-wiki
description: Use when building or maintaining a personal knowledge base with LLM assistance. Triggers on ingesting sources, compiling wiki articles, querying knowledge, running health checks, deep research, or initializing a new wiki vault. Based on Karpathy's LLM Wiki pattern with Obsidian integration.
---

# Karpathy Wiki

LLM-driven personal knowledge base that compounds over time. Raw sources in, structured wiki out.

> You never write the wiki. The LLM writes everything. You just steer, and every answer compounds.

## When to Use

- User wants to ingest documents, URLs, or text into a knowledge base
- User wants to query, compile, or maintain wiki articles
- User needs deep research to fill knowledge gaps
- User wants to initialize a new wiki vault

## When NOT to Use

- One-off Q&A without persistent knowledge storage
- Note-taking without cross-referencing or structure
- Non-text content management (images, videos alone)

## Core Principles

1. **raw/ is immutable** — sources are never edited; re-ingest as new version
2. **purpose.md anchors direction** — read on every operation, align output with wiki goals
3. **Classify before extract** — determine entity type during Ingest, choose chapter structure during Compile
4. **Analyze before generate** — two-step Compile: structured analysis → article generation
5. **Backlink audit is mandatory** — bidirectional links are the knowledge graph
6. **Query answers must be archived** — good answers are compounding fuel
7. **Token budget first** — always read index before full articles (L0→L1→L2→L3)
8. **Human verifies, LLM maintains** — LLM writes, user steers

## Pipeline

| Stage | Input | Output |
|-------|-------|--------|
| **Ingest** | URLs, files, text | `raw/` (immutable) + hash cache |
| **Compile** | raw/ files | `wiki/<domain>/` articles by entity type |
| **Query** | Questions | Cited answers → `outputs/queries/` |
| **Lint** | Full wiki | Health report → `outputs/reports/` |

Each stage appends `log.md`. Lint and Query can trigger **Deep Research** to fill gaps.

## Token Budget

| Level | ~Tokens | When | What |
|-------|---------|------|------|
| L0 | ~200 | Every session | SKILL.md frontmatter |
| L1 | ~1-2K | Session start | purpose.md + Concept Index + Dashboard |
| L2 | ~2-5K | Search | Result summaries |
| L3 | 5-20K | Deep read | Full articles or raw sources |

## Entity Types

7 types, each with different required sections (see `references/entity-types.md`):

`concept` (default) · `person` · `tool` · `event` · `comparison` · `pattern` · `overview`

## Commands

| Command | Action |
|---------|--------|
| `init [path] [--template <t>]` | Initialize vault (templates: general/research/reading/project) |
| `ingest <source>` | Collect + classify + archive (no wiki generation) |
| `compile [topic]` | Two-step: analyze → generate wiki article |
| `query <question>` | Answer from wiki, archive result |
| `promote` | Elevate quality query answer to wiki article |
| `research <topic>` | Gap → web search → ingest → compile loop |
| `delete <source>` | Safe delete with cascade cleanup |
| `lint` | Health check + graph analysis |

## Conventions

- **Obsidian CLI first** for page operations (see `references/obsidian-cli-cheatsheet.md`)
- **Structured diff** for updates: Current/Proposed/Reason/Source, user confirms each
- **Sources traceability**: frontmatter `sources[]` links every wiki page to raw/ files
- **Incremental cache**: SHA256 hash in `.cache/` skips unchanged sources

## References

- `references/operations.md` — Full procedures for all 9 operations
- `references/frontmatter-schemas.md` · `compilation-guide.md` · `entity-types.md` · `obsidian-cli-cheatsheet.md`
- `assets/` — All templates (purpose, wiki article, raw, query, indexes, log)
- `scripts/` — `init-wiki.sh` (with `--template`), `parse-media.py`
