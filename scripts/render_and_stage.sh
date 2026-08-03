#!/bin/bash
# render_and_stage.sh - Render the book (or one chapter) and stage exactly
# the files the publishing workflow needs, per docs/WORKFLOW_LEARNING_GUIDE.md.
#
# Usage:
#   scripts/render_and_stage.sh                  # render whole book, stage safelisted changes
#   scripts/render_and_stage.sh 04-skills         # render only chapters/04-skills/index.qmd
#   scripts/render_and_stage.sh --no-render       # skip render, just stage
#
# Never commits. Prints `git status` at the end for you to review before
# `git commit`. Anything outside the safelist (renv.lock, .Rproj, data/raw/,
# personal scratch files, etc.) is left untouched and reported separately.

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

CHAPTER=""
DO_RENDER=true

for arg in "$@"; do
    case "$arg" in
        --no-render) DO_RENDER=false ;;
        --help|-h)
            echo "Usage: $0 [chapter-dir] [--no-render]"
            echo "  chapter-dir   e.g. 04-skills — render only that chapter"
            echo "  --no-render   skip rendering, just stage safelisted changes"
            exit 0
            ;;
        *) CHAPTER="$arg" ;;
    esac
done

# ----------------------------------------------------------------------------
# 1. Render
# ----------------------------------------------------------------------------

if [ "$DO_RENDER" = true ]; then
    if [ -n "$CHAPTER" ]; then
        TARGET="chapters/$CHAPTER/index.qmd"
        if [ ! -f "$TARGET" ]; then
            echo "Chapter not found: $TARGET" >&2
            exit 1
        fi
        echo "Rendering $TARGET ..."
        quarto render "$TARGET"
    else
        echo "Rendering entire book ..."
        quarto render
    fi
else
    echo "Skipping render (--no-render)"
fi

# ----------------------------------------------------------------------------
# 2. Safelist patterns (the "four things" from WORKFLOW_LEARNING_GUIDE.md,
#    plus figure assets under _freeze/)
# ----------------------------------------------------------------------------

SAFELIST_REGEX='^chapters/[^/]+/index\.qmd$'
SAFELIST_REGEX="$SAFELIST_REGEX|^scripts/R/.+\.R$"
SAFELIST_REGEX="$SAFELIST_REGEX|^scripts/python/.+\.py$"
SAFELIST_REGEX="$SAFELIST_REGEX|^data/fact/.+\.csv$"
SAFELIST_REGEX="$SAFELIST_REGEX|^_freeze/chapters/.+/execute-results/.+\.json$"
SAFELIST_REGEX="$SAFELIST_REGEX|^_freeze/chapters/.+/figure-html/.+\.(png|svg|jpg|jpeg)$"
SAFELIST_REGEX="$SAFELIST_REGEX|^data/common_project_data/indicators-master\.xlsx$"

# ----------------------------------------------------------------------------
# 3. Stage matching changed/untracked/deleted files, report the rest
# ----------------------------------------------------------------------------

STAGED=()
SKIPPED=()

while IFS= read -r line; do
    [ -z "$line" ] && continue
    status="${line:0:2}"
    file="${line:3}"
    # handle renames "R  old -> new"
    if [[ "$file" == *" -> "* ]]; then
        file="${file#* -> }"
    fi

    if [[ "$file" =~ $SAFELIST_REGEX ]]; then
        worktree_status="${status:1:1}"
        if [ "$worktree_status" = " " ]; then
            # Already fully staged (e.g. a staged deletion with nothing
            # pending in the worktree) - `git add` on this errors with
            # "pathspec did not match any files", so nothing to do.
            STAGED+=("$file")
        else
            git add -- "$file"
            STAGED+=("$file")
        fi
    else
        # Ignore already-clean entries; only report actual changes
        SKIPPED+=("$status $file")
    fi
done < <(git status --porcelain)

echo ""
echo "Staged (safelisted):"
if [ ${#STAGED[@]} -eq 0 ]; then
    echo "  (none)"
else
    for f in "${STAGED[@]}"; do
        echo "  + $f"
    done
fi

echo ""
echo "Left untouched (review manually if unexpected):"
if [ ${#SKIPPED[@]} -eq 0 ]; then
    echo "  (none)"
else
    for f in "${SKIPPED[@]}"; do
        echo "  ? $f"
    done
fi

echo ""
echo "git status:"
git status
