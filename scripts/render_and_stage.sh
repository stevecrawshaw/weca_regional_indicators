#!/bin/bash
# render_and_stage.sh - Render the book (or one chapter) and stage exactly
# the files the publishing workflow needs, per docs/WORKFLOW_LEARNING_GUIDE.md.
#
# Usage:
#   scripts/render_and_stage.sh                  # render whole book, stage safelisted changes
#   scripts/render_and_stage.sh 04-skills         # render only chapters/04-skills/index.qmd
#   scripts/render_and_stage.sh --no-render       # skip render, just stage
#   scripts/render_and_stage.sh --clean-freeze    # wipe freeze cache (all chapters), then render
#   scripts/render_and_stage.sh 04-skills --clean-freeze  # wipe cache for one chapter, then render
#
# --clean-freeze deletes the _freeze/chapters/*/index/ cache dir(s) before
# rendering, forcing a full re-execution instead of a freeze-cached render.
# Use this to regenerate every figure from scratch (e.g. after a theme or
# palette change) — it's slower since all R code reruns, not just plotting.
#
# Never commits. Prints `git status` at the end for you to review before
# `git commit`. Anything outside the safelist (renv.lock, .Rproj, data/raw/,
# personal scratch files, etc.) is left untouched and reported separately.

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

CHAPTER=""
DO_RENDER=true
CLEAN_FREEZE=false

for arg in "$@"; do
    case "$arg" in
        --no-render) DO_RENDER=false ;;
        --clean-freeze) CLEAN_FREEZE=true ;;
        --help|-h)
            echo "Usage: $0 [chapter-dir] [--no-render] [--clean-freeze]"
            echo "  chapter-dir     e.g. 04-skills — render only that chapter"
            echo "  --no-render     skip rendering, just stage safelisted changes"
            echo "  --clean-freeze  delete the freeze cache (that chapter, or all) before rendering"
            exit 0
            ;;
        *) CHAPTER="$arg" ;;
    esac
done

# ----------------------------------------------------------------------------
# 1. Optionally wipe the freeze cache to force full re-execution
# ----------------------------------------------------------------------------

if [ "$CLEAN_FREEZE" = true ]; then
    if [ -n "$CHAPTER" ]; then
        FREEZE_DIR="_freeze/chapters/$CHAPTER/index"
        echo "Removing freeze cache: $FREEZE_DIR"
        rm -rf "$FREEZE_DIR"
    else
        echo "Removing freeze cache for all chapters ..."
        rm -rf _freeze/chapters/*/index/
    fi
fi

# ----------------------------------------------------------------------------
# 2. Render
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
# 3. Safelist patterns (the "four things" from WORKFLOW_LEARNING_GUIDE.md,
#    plus figure assets under _freeze/)
# ----------------------------------------------------------------------------

SAFELIST_REGEX='^chapters/[^/]+/index\.qmd$'
SAFELIST_REGEX="$SAFELIST_REGEX|^index\.qmd$"
SAFELIST_REGEX="$SAFELIST_REGEX|^scripts/R/.+\.R$"
SAFELIST_REGEX="$SAFELIST_REGEX|^data/fact/.+\.csv$"
SAFELIST_REGEX="$SAFELIST_REGEX|^_freeze/chapters/.+/execute-results/.+\.json$"
SAFELIST_REGEX="$SAFELIST_REGEX|^_freeze/index/execute-results/html\.json$"
SAFELIST_REGEX="$SAFELIST_REGEX|^_freeze/chapters/.+/figure-html/.+\.(png|svg|jpg|jpeg)$"
SAFELIST_REGEX="$SAFELIST_REGEX|^data/common_project_data/indicators-master\.xlsx$"
SAFELIST_REGEX="$SAFELIST_REGEX|^presentation/(index\.qmd|_quarto\.yml|weca-reveal\.scss|\.Rprofile|\.gitignore)$"
SAFELIST_REGEX="$SAFELIST_REGEX|^docs/presentation\.md$"

# ----------------------------------------------------------------------------
# 4. Stage matching changed/untracked/deleted files, report the rest
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
