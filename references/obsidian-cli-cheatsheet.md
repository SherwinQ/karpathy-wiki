# Obsidian CLI 速查表

所有涉及 Obsidian vault 的知识页面操作，必须优先使用 Obsidian CLI。CLI 自动维护双链关系，处理文件移动后的链接更新，比手动操作更可靠。

> **前提：** Obsidian 应用必须正在运行，且已启用 CLI（设置 → 通用 → Command line interface）。

## 常用命令

| 操作 | CLI 命令 |
|------|---------| 
| 创建文件 | `obsidian create name="标题" path="领域/文件.md" content="..."` |
| 读取文件 | `obsidian read path="领域/文件.md"` |
| 追加内容 | `obsidian append path="领域/文件.md" content="..."` |
| 移动文件 | `obsidian move path="旧路径" to="新路径"` |
| 重命名 | `obsidian rename path="领域/旧名.md" name="新名"` |
| 搜索 | `obsidian search query="关键词" path="领域"` |
| 查看反链 | `obsidian backlinks path="领域/文件.md"` |
| 查看正链 | `obsidian links path="领域/文件.md"` |
| 孤儿页面 | `obsidian orphans` |
| 悬空链接 | `obsidian unresolved` |
| 死胡同页面 | `obsidian deadends` |
| 列出文件夹 | `obsidian folders folder="wiki"` |
| 列出文件 | `obsidian files folder="wiki/领域"` |
| 设置属性 | `obsidian property:set name="标签" value="深度学习" path="..."` |
| 删除文件 | `obsidian delete path="领域/文件.md"` |

## 使用规则

1. **创建/移动/重命名**知识页面 → 用 `obsidian` CLI，确保双链自动更新
2. **搜索/链接检查** → 用 `obsidian search`、`obsidian orphans`、`obsidian unresolved`、`obsidian backlinks`
3. **仅在以下场景用普通文件工具：**
   - `raw/` 归档（原始资料不是知识页面）
   - `log.md` 追加（仅追加操作）
   - `outputs/` 中的非知识文件
   - 索引文件的批量编辑
4. **CLI 要求 Obsidian 应用正在运行**，离线时降级到普通文件工具
