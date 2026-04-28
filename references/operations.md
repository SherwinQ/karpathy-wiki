# Operations Reference

Complete procedures for each pipeline stage. SKILL.md contains the decision framework; this file contains the execution details.

---

## Init — Initialize Wiki

```bash
bash .agents/skills/karpathy-wiki/scripts/init-wiki.sh [target_dir] [--template <name>]
```

Templates: `general` (default) · `research` · `reading` · `project`

Creates: directory structure + index files + `purpose.md` + `.gitignore` + `.cache/`

---

## Ingest — Collect Sources

**Collect, classify, and archive only. No wiki page generation.**

### Steps

1. **Receive input**: file path, URL, pasted text, PDF, or image
2. **Fetch content**:

   | Input | Method |
   |-------|--------|
   | URL | `mcp__web_reader__webReader` (fallback: exa) |
   | PDF / Image | `scripts/parse-media.py` (PaddleOCR) |
   | Local .md/.txt | Read tool |
   | Pasted text | Direct use |

3. **Content hash (incremental cache)**:
   - SHA256 the body text
   - Check `.cache/content_hashes.json` for existing hash
   - Exists → skip, inform user with link to existing file
   - New → store hash, continue
4. **Classify** (classify before extract):
   - `source_kind`: article / paper / blog-post / documentation / transcript / report
   - `classified_as`: best entity type (concept/person/tool/event/comparison/pattern/overview)
   - Rules: see `references/entity-types.md` bottom section
5. **Archive to raw/**:
   - Filename: `raw/YYYY-MM-DD_{slug}.md`
   - Frontmatter: see `references/frontmatter-schemas.md`
   - Body: raw source content, unmodified
   - Must include `content_hash` field
6. **Review queue**:
   - Uncertain classification → `review_status: pending`
   - Clear type/source → `review_status: resolved`
7. **Update Source Index** + **append log.md**

---

## Compile — Generate Wiki Articles

**Two-step process: Analysis → Generation.**

### Step 1: Analysis

1. **Identify target**: user-specified topic or raw file
2. **Locate domain directory**:
   - `obsidian folders folder="wiki"` to list existing domains
   - No match → pause, suggest directory name, wait for user confirmation
3. **Load context** (token budget):
   - L1: `Concept Index.md` + `purpose.md` (if missing, suggest `init-wiki.sh` then continue)
   - L3: target raw files + existing article full text
4. **Cache check**:
   - Read raw file `content_hash`
   - Compare with `.cache/compiled_hashes.json`
   - Unchanged → skip, inform user
   - Changed or first compile → continue
5. **Output structured analysis** (show to user for confirmation):
   - Key entities and concepts
   - Connections to existing wiki content
   - Contradictions with existing knowledge
   - Recommendations: new article vs update, suggested entity type
   - Review items needing user judgment
   - Ask: *"Does this analysis look right? Anything to emphasize or de-emphasize?"*

### Step 2: Generation

6. **Generate/update article** (based on Step 1 analysis):
   - Entity type chapter structure: `references/entity-types.md`
   - Writing standards: `references/compilation-guide.md`
   - Page template: `assets/wiki-article-template.md`
   - **Align with `purpose.md`** — content should serve wiki goals; down-weight off-topic material
   - Target: 2000-4000 words, 10-30 `[[wikilinks]]`
   - 3+ sources → add `## Counter-Arguments & Data Gaps`
7. **Backlink audit (mandatory)**:
   - `grep -rln "new-article-keywords" wiki/<domain>/`
   - Decide whether existing articles should add `[[New Article]]` wikilink
8. **Update indexes**: Concept Index + Dashboard + Source Index
9. **Update compile cache**: write content_hash to `.cache/compiled_hashes.json`
10. **Light lint**: `obsidian unresolved` check
11. **Append log.md**

### Updating Existing Articles

Show structured diff per change (format in `references/compilation-guide.md`), each requiring user confirmation. After confirmation: contradiction scan + downstream impact check + reference chain cleanup (see Delete procedure).

---

## Query — Ask and Archive

### Phase A — Answer from Wiki

1. **Read purpose.md** (L0-L1, skip if missing), align answer with wiki goals
2. **Read Concept Index** (L1), scan for candidates
3. **Locate articles**: index sufficient for small wiki; `obsidian search` for larger
4. **Read relevant articles** (L3), follow one layer of `[[wikilinks]]`
5. **Synthesize answer**:
   - Cite sources: `(from [[domain/article]])`
   - Note agreements and contradictions across articles
   - **Explicitly mark gaps**: "No wiki article about X"
   - Suggest Deep Research for identified gaps
6. **Match format**: factual → prose | comparison → table | mechanism → numbered | synthesis → known/unsolved/gap

### Phase B — Archive Answer

7. **Save to outputs/queries/** (template: `assets/query-output-template.md`)
8. **Quality answers → promote to Wiki** (synthesis, comparisons, new concepts)
9. **Append log.md**

**Anti-patterns:** answer from memory without reading wiki · no citations · skip saving · silent gaps

---

## Promote — Elevate Query Results

Promote quality answers from `outputs/queries/` to formal wiki articles per Compile standards. Update query file frontmatter `stage: promoted`.

---

## Lint — Health Check

### Automated Checks (Obsidian CLI)

`obsidian orphans` · `obsidian unresolved` · `obsidian deadends` · `obsidian links/backlinks`

### Deep Checks (LLM-driven)

| Check | Description |
|-------|-------------|
| Stale content | `updated:` older than source `scraped:` |
| Contradictions | Same concept contradicted across articles |
| Missing coverage | 3+ articles reference a concept without its own page |
| Format violations | Missing H1, intro paragraph, Sources, frontmatter |
| Wikilink audit | Missing / excessive / incorrect wikilinks |
| Missing counter-args | 3+ sources without Counter-Arguments section |
| Missing entity_type | frontmatter lacks `entity_type` |
| Unpromoted queries | List items in `outputs/queries/` with suggested actions |
| Orphan sources | raw/ files not referenced by any wiki page |
| Review backlog | raw/ entries with `review_status: pending` |
| Purpose alignment | Article content drifts from purpose.md goals |

### Graph Analysis (text-based)

Wikilink topology analysis without GUI:

**1. Bridge nodes**
```bash
grep -roh '\[\[[^/\]]*/' wiki/ | sort | uniq -c | sort -rn
# Articles linking to 3+ different domains = bridge nodes
```

**2. Isolated pages**
```bash
grep -rl '\[\[' wiki/ | while read f; do
  links=$(grep -o '\[\[[^]]*\]\]' "$f" | wc -l)
  [ "$links" -le 1 ] && echo "$links $f"
done
```

**3. Referenced but missing pages**
```bash
grep -roh '\[\[[^]/|]*' wiki/ | sed 's/\[\[//' | sort | uniq -c | sort -rn | head -20 | while read count name; do
  find wiki/ -name "${name}.md" -print -quit | grep -q . || echo "$count $name (MISSING)"
done
```

**4. Knowledge clusters**
- Identify tightly interconnected article groups via wikilink topology
- Find "surprising connections" — cross-cluster links
- Report: cluster name → members → cohesion score → cross-cluster links

**5. Gap recommendations**
- Bridge nodes and isolated pages → suggest Deep Research
- Isolated clusters → suggest cross-domain links

Save report to `outputs/reports/`.

---

## Research — Deep Research

**Closed-loop gap filling.**

### Triggers

- Lint finds gaps (referenced but missing concepts)
- User requests `research <topic>`
- Compile analysis discovers missing background
- Query identifies explicit gaps

### Steps

1. **Load context**:
   - L1: `purpose.md` + overview (if exists) + `Concept Index.md`
   - Goal: generate search queries aligned with wiki goals
2. **Generate search strategy**:
   - 3-5 research questions from purpose.md
   - 2-3 search queries per question
   - Show to user for confirmation/editing
3. **Execute search**:
   - Run each query via web search tool
   - Collect results (title + URL + snippet)
4. **Filter and Ingest**:
   - Remove low-quality/duplicate results
   - Ingest each valuable result (Ingest procedure)
5. **Auto-Compile**:
   - Compile new materials (Compile procedure)
   - Focus on filling the gap that triggered the research
6. **Append log.md** (operation type: `research`)

---

## Delete — Safe Deletion with Cascade

### Steps

1. **Locate related pages** (3-method matching):
   - A: wiki pages with target file in frontmatter `sources[]`
   - B: Source Summary page named after the target file
   - C: Body text referencing the target source
2. **Tiered handling**:
   - Pages citing only the deleted source → delete page, clean indexes
   - Multi-source pages → remove deleted source from `sources[]` only, keep page
   - Source Summary pages → delete
3. **Clean indexes**: remove entries from Concept Index, Dashboard, Source Index
4. **Clean wikilinks**: remove `[[wikilinks]]` pointing to deleted pages
5. **Delete source file**: `rm raw/<file>.md`
6. **Clean cache**: remove from `.cache/content_hashes.json` and `.cache/compiled_hashes.json`
7. **Append log.md**

---

## Log — Append to log.md

After every operation. Format: `## [YYYY-MM-DD] <operation> | <description>`

Operations: `ingest` · `compile` · `query` · `promote` · `research` · `delete` · `lint` · `split`

```bash
grep "^## \[" log.md | tail -10                # Last 10 entries
grep "^## \[.*compile" log.md | wc -l          # Total compiles
grep "^## \[.*research" log.md | wc -l         # Total research runs
```
