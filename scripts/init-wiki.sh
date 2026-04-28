#!/usr/bin/env bash
# Initialize Karpathy Wiki knowledge base directory structure
#
# Usage: bash init-wiki.sh [target_dir] [--template <name>]
# Default target: wiki/ in current directory
#
# Templates:
#   general    - General knowledge base (default)
#   research   - Academic research
#   reading    - Reading notes
#   project    - Project documentation
#
# Examples:
#   bash init-wiki.sh                            # ./wiki/, general template
#   bash init-wiki.sh ~/notes/kb                 # specified dir, general template
#   bash init-wiki.sh ~/notes/kb --template research

set -euo pipefail

TARGET_DIR="wiki"
TEMPLATE="general"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --template|-t)
      TEMPLATE="${2:?ERROR: --template requires a name (general|research|reading|project)}"
      shift 2
      ;;
    -*)
      echo "WARNING: Unknown option $1" >&2
      shift
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$SCRIPT_DIR/../assets"
TODAY="$(date +%Y-%m-%d)"

# Validate template name
case "$TEMPLATE" in
  general|research|reading|project) ;;
  *)
    echo "ERROR: Unknown template '$TEMPLATE'. Available: general, research, reading, project" >&2
    exit 1
    ;;
esac

if [[ -e "$TARGET_DIR" ]]; then
  echo "ERROR: $TARGET_DIR already exists. Choose another path or remove it first." >&2
  exit 1
fi

if [[ ! -d "$ASSETS" ]]; then
  echo "WARNING: assets directory not found ($ASSETS), will create empty template files." >&2
  ASSETS=""
fi

echo "Initializing wiki: $TARGET_DIR (template: $TEMPLATE)"

# Create directory structure
mkdir -p "$TARGET_DIR/raw" \
  "$TARGET_DIR/wiki/index" \
  "$TARGET_DIR/outputs/queries" \
  "$TARGET_DIR/outputs/reports"

# Create index files from templates
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

# Create purpose.md based on template
if [[ -n "$ASSETS" ]]; then
  case "$TEMPLATE" in
    general)  cp "$ASSETS/purpose-template.md" "$TARGET_DIR/purpose.md" ;;
    research) cp "$ASSETS/purpose-research-template.md" "$TARGET_DIR/purpose.md" ;;
    reading)  cp "$ASSETS/purpose-reading-template.md" "$TARGET_DIR/purpose.md" ;;
    project)  cp "$ASSETS/purpose-project-template.md" "$TARGET_DIR/purpose.md" ;;
  esac
else
  touch "$TARGET_DIR/purpose.md"
fi
echo "Created purpose.md (template: $TEMPLATE)"

# Gitkeep for empty directories
touch "$TARGET_DIR/raw/.gitkeep" \
  "$TARGET_DIR/outputs/queries/.gitkeep" \
  "$TARGET_DIR/outputs/reports/.gitkeep"

# Create .gitignore
cat > "$TARGET_DIR/.gitignore" << 'GITEOF'
.env
.DS_Store
Thumbs.db
.cache/
GITEOF
echo "Created .gitignore"

# Create .env template
if [[ ! -f "$TARGET_DIR/.env" ]]; then
  cat > "$TARGET_DIR/.env" << 'ENVEOF'
LAYOUT_API_URL=https://your-api-url
LAYOUT_API_TOKEN=your-token
ENVEOF
  echo "Created .env template"
fi

# Create cache directory
mkdir -p "$TARGET_DIR/.cache"
echo "Created .cache/ (incremental cache)"

# Replace date placeholders in templates
if command -v sed &> /dev/null; then
  find "$TARGET_DIR" -name "*.md" -exec sed -i '' "s/YYYY-MM-DD/$TODAY/g" {} + 2>/dev/null || true
fi

echo ""
echo "Done! Structure:"
echo "  $TARGET_DIR/"
echo "  +-- purpose.md        # Wiki goals (edit this!)"
echo "  +-- raw/              # Source materials (immutable)"
echo "  +-- wiki/"
echo "  |   +-- index/        # Dashboard + Concept Index + Source Index"
echo "  |   +-- <domain>/     # Wiki articles"
echo "  +-- outputs/"
echo "  |   +-- queries/      # Query results"
echo "  |   +-- reports/      # Lint reports"
echo "  +-- .cache/           # Incremental cache"
echo "  +-- .gitignore"
echo "  +-- .env              # API config"
echo "  +-- log.md            # Operation log"
echo ""
echo "Next steps:"
echo "  1. Edit $TARGET_DIR/purpose.md"
echo "  2. Open $TARGET_DIR as Obsidian vault"
echo "  3. Run /karpathy-wiki ingest <file-or-url>"
