# Log

按时间顺序、仅追加的知识库操作记录。不可修改历史条目。

**条目格式：**

```markdown
## [YYYY-MM-DD] <操作> | <简短描述>

（可选）一段简短上下文、发现或决策
```

**操作类型：** `ingest` · `compile` · `query` · `promote` · `split` · `lint`

**快速查询：**

```bash
grep "^## \[" log.md | tail -10                # 最近 10 条
grep "^## \[.*compile" log.md | wc -l          # 编译总次数
grep "^## \[2026-04" log.md                    # 某月所有操作
```

---

## [YYYY-MM-DD] bootstrap | 知识库初始化

Wiki 目录结构已创建，准备开始 ingest。
