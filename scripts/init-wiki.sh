#!/usr/bin/env bash
# 初始化 Karpathy Wiki 知识库目录结构
#
# 用法：bash init-wiki.sh [目标目录]
# 默认目标目录：当前目录下的 wiki/
#
# 示例：
#   bash init-wiki.sh              # 在 ./wiki/ 创建
#   bash init-wiki.sh ~/notes/kb   # 在指定目录创建

set -euo pipefail

TARGET_DIR="${1:-wiki}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$SCRIPT_DIR/../assets"
TODAY="$(date +%Y-%m-%d)"

if [[ -e "$TARGET_DIR" ]]; then
  echo "ERROR: $TARGET_DIR 已存在。请选择其他路径或先删除。" >&2
  exit 1
fi

if [[ ! -d "$ASSETS" ]]; then
  echo "WARNING: assets 目录未找到 ($ASSETS)，将创建空模板文件。" >&2
  ASSETS=""
fi

echo "正在初始化知识库：$TARGET_DIR"

# 创建目录结构
mkdir -p "$TARGET_DIR/raw" \
  "$TARGET_DIR/wiki/index" \
  "$TARGET_DIR/outputs/queries" \
  "$TARGET_DIR/outputs/reports"

# 从模板创建索引文件
if [[ -n "$ASSETS" ]]; then
  cp "$ASSETS/dashboard-template.md" "$TARGET_DIR/wiki/index/Dashboard.md"
  cp "$ASSETS/concept-index-template.md" "$TARGET_DIR/wiki/index/Concept Index.md"
  cp "$ASSETS/source-index-template.md" "$TARGET_DIR/wiki/index/Source Index.md"
  cp "$ASSETS/log-template.md" "$TARGET_DIR/log.md"
else
  touch "$TARGET_DIR/wiki/index/Dashboard.md"
  touch "$TARGET_DIR/wiki/index/Concept Index.md"
  touch "$TARGET_DIR/wiki/index/Source Index.md"
  touch "$TARGET_DIR/log.md"
fi

# 占位文件，确保空目录可被 git 追踪
touch "$TARGET_DIR/raw/.gitkeep" \
  "$TARGET_DIR/outputs/queries/.gitkeep" \
  "$TARGET_DIR/outputs/reports/.gitkeep"

# 创建 .gitignore
cat > "$TARGET_DIR/.gitignore" << 'EOF'
# 敏感配置
.env

# 系统文件
.DS_Store
Thumbs.db

# Obsidian 内部缓存（可选排除）
# .obsidian/workspace.json
# .obsidian/workspace-mobile.json
EOF
echo "已创建 .gitignore"

# 创建 .env 模板（API 配置）
if [[ ! -f "$TARGET_DIR/.env" ]]; then
  cat > "$TARGET_DIR/.env" << 'EOF'
# Karpathy Wiki — PDF/图片解析 API 配置
# 请填入你的 API URL 和 Token
LAYOUT_API_URL=https://your-api-url
LAYOUT_API_TOKEN=your-token
EOF
  echo "已创建 .env 模板，请填写 PDF/图片解析 API 配置"
fi

# 替换模板中的日期占位符
if command -v sed &> /dev/null; then
  find "$TARGET_DIR" -name "*.md" -exec sed -i '' "s/YYYY-MM-DD/$TODAY/g" {} + 2>/dev/null || true
fi

echo ""
echo "✅ 完成！目录结构："
echo "  $TARGET_DIR/"
echo "  ├── raw/              # 原始资料（不可变）"
echo "  ├── wiki/"
echo "  │   ├── index/        # Dashboard + Concept Index + Source Index"
echo "  │   └── <领域>/       # Wiki 文章（按领域子目录）"
echo "  ├── outputs/"
echo "  │   ├── queries/      # 查询结果"
echo "  │   └── reports/      # Lint 报告"
echo "  ├── .gitignore        # Git 排除规则"
echo "  ├── .env              # API 配置（已被 .gitignore 排除）"
echo "  └── log.md            # 操作日志（仅追加）"
echo ""
echo "下一步："
echo "  1. 编辑 $TARGET_DIR/.env 填写 PDF/图片解析 API 配置（可选）"
echo "  2. 用 Obsidian 打开 $TARGET_DIR 作为 vault"
echo "  3. 运行 /karpathy-wiki ingest <文件或URL> 开始录入资料"
