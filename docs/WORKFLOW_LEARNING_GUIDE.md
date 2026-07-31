# Understanding the Publishing Workflow

A guide for WECA analysts who are new to git and Quarto. Written around real errors the team has hit — so you can diagnose problems yourself rather than always asking Steve.

------------------------------------------------------------------------

## Why does this workflow exist?

You are contributing to a shared book. Five analysts, five laptops, five sets of raw data — none of which can be committed to git (too large, possibly sensitive).

The question is: **how does GitHub publish the full book without any analyst's raw data?**

The answer is the freeze cache.

------------------------------------------------------------------------

## The Freeze Cache: the concept that explains everything

When you render your chapter locally:

``` bash
quarto render chapters/04-skills/index.qmd
```

Quarto runs your R code, produces your charts and tables, then **saves the outputs** to a folder called `_freeze/`:

```         
_freeze/
  chapters/
    04-skills/
      index/
        execute-results/
          html.json   ← your chapter's saved outputs
        figure-html/
          my-plot-1.png
```

Think of `html.json` as a **photograph of your chapter's outputs**. It contains every table, every number, every chart reference — everything needed to assemble the page.

When GitHub builds the report, it checks a fingerprint (hash) of your source file against the one stored in `html.json`:

```         
Source file fingerprint == Stored fingerprint?
  ✅ YES → use the photograph. Raw data never needed.
  ❌ NO  → try to re-run your code → FAIL (no raw data)
```

This is why **every time you change your chapter, you must re-render and commit the updated `html.json`**.

------------------------------------------------------------------------

## The four things you always commit together

| File | Location | What it is |
|------------------|-------------------------|------------------------------|
| Chapter source | `chapters/0X-topic/index.qmd` | Narrative + code |
| Indicator script(s) | `scripts/R/0X-topic/RI_XY_name.R` | Data processing |
| Fact CSV(s) | `data/fact/RI_XY_name.csv` | Processed data |
| Freeze snapshot | `_freeze/chapters/0X-topic/index/execute-results/html.json` | Rendered outputs |

Missing any one of these = publishing failure.

The freeze snapshot is the most commonly forgotten.

------------------------------------------------------------------------

## The workflow, step by step

### 1. Render your chapter locally

Your raw data must be in `data/raw/`. Then:

``` bash
quarto render chapters/04-skills/index.qmd
```

Fix any errors before continuing. A broken render means a broken freeze.

### 2. Check what git sees

``` bash
git status
```

A healthy status looks like this:

```         
Changes not staged for commit:
    modified: chapters/04-skills/index.qmd
    modified: _freeze/chapters/04-skills/index/execute-results/html.json

Untracked files:
    scripts/R/04-skills/RI_4A3_apprenticeship_starts.R
    data/fact/RI_4A3_apprenticeship_starts.csv
```

### 3. Stage exactly the right files

**Never use `git add .`** — it sweeps in renv files, `.Rproj`, and personal scratch files. Stage by name:

``` bash
git add chapters/04-skills/index.qmd
git add scripts/R/04-skills/RI_4A3_apprenticeship_starts.R
git add data/fact/RI_4A3_apprenticeship_starts.csv
git add _freeze/chapters/04-skills/index/execute-results/html.json
```

If you have new plots, also add the figure folder:

``` bash
git add _freeze/chapters/04-skills/index/figure-html/
```

### 4. Commit and push

``` bash
git commit -m "feat: add apprenticeship starts indicator"
git push origin your-branch-name
```

------------------------------------------------------------------------

## Files that must never be committed

If these appear in `git status`, do not `git add` them:

| File | Why |
|---------------------------------------|---------------------------------|
| `renv.lock`, `renv/activate.R` | Shared R environment — only the project lead changes these |
| `weca_regional_indicators.Rproj` | IDE file, differs per machine |
| `data/raw/*` | Raw data — gitignored, should never appear |
| Personal files (`simon.R`, `simon.qmd`) | Keep these local |

------------------------------------------------------------------------

## Diagnosing and fixing common errors

### "path does not exist: data/raw/..."

```         
Error: `path` does not exist:
'.../data/raw/4.A.3-data_apprenticeships_starts_05.26.xlsx'
```

**Why it happened:** Your chapter source changed (even a small edit), so the fingerprints no longer match. GitHub tried to re-run your code and couldn't find your raw data.

**Fix:**

``` bash
git checkout main
git pull origin main
# Put your raw data back in data/raw/ if needed
quarto render chapters/04-skills/index.qmd
git add _freeze/chapters/04-skills/index/execute-results/html.json
git commit -m "fix: regenerate freeze cache for skills chapter"
git push origin main
```

------------------------------------------------------------------------

### "Updates were rejected"

```         
error: failed to push some refs
hint: Updates were rejected because the remote contains
hint: work that you do not have locally.
```

**Why it happened:** Someone else pushed to your branch after your last pull. Git won't let you overwrite their work.

**Fix:** Pull first, then push:

``` bash
git pull origin your-branch-name
git push origin your-branch-name
```

------------------------------------------------------------------------

### "no changes added to commit"

**Why it happened:** You ran `git commit` without running `git add` first. Or the file you tried to add hasn't actually changed.

**Fix:** Run `git status`, then `git add` the files you want, then `git commit`.

------------------------------------------------------------------------

### Pushed to the wrong branch

You pushed a fix to your feature branch instead of `main`.

**Fix:** Switch to main, pull, re-do the fix there:

``` bash
git checkout main
git pull origin main
# re-render or re-apply your fix
git add ...
git commit -m "fix: ..."
git push origin main
```

------------------------------------------------------------------------

### Script or fact file not found on GitHub

```         
Error in source(...): cannot open file
'scripts/R/01-economy/RI_1E2_population_change.R'
```

**Why it happened:** The script exists on your machine but was never committed.

**Fix:** Stage and commit the missing files:

``` bash
git add scripts/R/01-economy/RI_1E2_population_change.R
git add data/fact/RI_1E2_population_change.csv
git commit -m "feat: add missing indicator script and fact data"
git push origin your-branch-name
```

Also check the filename matches exactly what the chapter sources — a common mistake is reversing the digit groups (`RI_3E1_` instead of `RI_1E3_`).

------------------------------------------------------------------------

## Pre-PR checklist

Before opening a pull request:

- [ ] `quarto render chapters/0X-topic/index.qmd` completes without errors
- [ ] All indicator R scripts committed under `scripts/R/0X-topic/`
- [ ] All fact CSVs committed under `data/fact/`
- [ ] Freeze snapshot committed: `_freeze/chapters/0X-topic/index/execute-results/html.json`
- [ ] No renv files, no `.Rproj`, no personal files staged (`git status` is clean)
- [ ] Branch is up to date: `git pull origin main` says "Already up to date"

------------------------------------------------------------------------

## Quick reference

| Task                   | Command                                     |
|------------------------|---------------------------------------------|
| Check what has changed | `git status`                                |
| Switch to main         | `git checkout main`                         |
| Get latest from GitHub | `git pull origin main`                      |
| Render your chapter    | `quarto render chapters/0X-topic/index.qmd` |
| Stage a file           | `git add path/to/file`                      |
| Stage a folder         | `git add path/to/folder/`                   |
| Commit staged files    | `git commit -m "feat: description"`         |
| Push your branch       | `git push origin your-branch-name`          |
| See recent commits     | `git log --oneline -5`                      |

------------------------------------------------------------------------

## The freeze path — get it right

```         
_freeze/chapters/0X-topic/index/execute-results/html.json
```

Note: there is **no** `html/` folder between `_freeze/` and `chapters/`. Examples:

```         
_freeze/chapters/04-skills/index/execute-results/html.json
_freeze/chapters/01-economy/index/execute-results/html.json
_freeze/chapters/05-environment/index/execute-results/html.json
```