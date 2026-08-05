# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository (`weca_regional_indicators`) contains the West of England Combined Authority (WECA) regional priorities report - a collaborative Quarto-based book where each analyst contributes a chapter.

**Published report:** [https://westofengland-ca.github.io/weca_regional_indicators/](https://westofengland-ca.github.io/weca_regional_indicators/)

## Architecture

### Repository Structure

Everything lives at the repository root (no nested `projects/` directory):

```
weca_regional_indicators/
├── _quarto.yml          # Quarto configuration (chapter order, themes, execution)
├── _brand.yml           # WECA branding configuration
├── index.qmd            # Report landing page
├── custom.scss          # Custom SCSS styling
├── .Rprofile            # renv activation + vscode-R options (must load renv first)
├── .Renviron            # Disables renv startup sync check (speeds up R start)
├── chapters/            # Modular chapter directories (one per analyst/priority)
│   ├── 01-economy/
│   ├── 02-transport/
│   ├── 03-place/
│   ├── 04-skills/
│   ├── 05-environment/
│   └── 06-child-poverty/
├── data/                # Shared data assets
│   ├── raw/             # Original data files (not committed)
│   ├── processed/       # Cleaned/transformed data (not committed)
│   ├── fact/            # Per-indicator FACT CSVs (committed, one file per indicator)
│   └── examples/        # Small example datasets (committed)
├── scripts/
│   ├── R/
│   │   ├── _common.R          # Sourced by every chapter (loads all helpers below)
│   │   ├── theme_weca.R       # WECA ggplot2 theme
│   │   ├── helpers.R          # General data loading utilities
│   │   ├── fact_helpers.R     # build_fact() / save_fact() — analyst FACT workflow
│   │   ├── collate_fact.R     # collate_fact() / build_reporting_view()
│   │   ├── reporting_table.R  # format_indicator_summary() — GT summary tables
│   │   ├── dim_data.R         # core_dim_data_tbl — indicator metadata (polarity, priority, units)
│   │   ├── summary_tables.R   # format_priority_summary() / format_overall_summary() — multi-indicator GT tables
│   │   ├── db_connect.R       # Postgres connection via .env variables
│   │   ├── azure_blob.R       # refresh_raw_chapter_data() — pull a chapter's raw data from Azure Blob
│   │   ├── sync_raw_data.R    # CLI wrapper around azure_blob.R (Rscript, manual step)
│   │   └── load_pins.R        # pins board helpers (S3-backed spatial/tabular pins)
│   ├── python/          # Python utility scripts
│   └── hooks/           # Pre-commit hook scripts
├── _freeze/             # Quarto execution cache (committed)
├── _output/             # Rendered HTML/PDF output (gitignored)
├── WIP/                 # In-progress analyst notes/specs (gitignored, local only)
├── pyproject.toml       # Python dependencies (uv-managed)
├── renv.lock            # R package lock file
└── .github/workflows/   # GitHub Actions (publish to GitHub Pages)
```

### Quarto Polyglot Report

**Tech Stack:**

- **Rendering:** Quarto
- **Python:** Managed via `uv` (pyproject.toml-based)
- **R:** Managed via `renv`
- **IDE:** Positron (recommended)

**Architecture Pattern:**

- **Polyglot:** Chapters can use R or Python as needed
- **Modular:** Each chapter has its own directory to prevent merge conflicts
- **Freeze execution:** Chapters only re-render when source changes (`freeze: auto`)
- **Shared resources:** `data/` and `scripts/` directories contain assets used across chapters

**Chapter Structure:**
Each priority area has a dedicated chapter directory under `chapters/`:

- `chapters/01-economy/` - Contributing to national economic growth
- `chapters/02-transport/` - Better public transport connectivity
- `chapters/03-place/` - Affordable/sustainable homes
- `chapters/04-skills/` - Future-ready skills development
- `chapters/05-environment/` - Green jobs and growth
- `chapters/06-child-poverty/` - Lifting families out of poverty

## Working with the Report

### Adding a New Chapter

1. Create directory: `chapters/XX-topic-name/`
2. Add `index.qmd` file with Quarto frontmatter
3. Update `_quarto.yml` to include the chapter in sidebar navigation
4. Use `freeze: auto` to prevent re-rendering other chapters during development

### Code Display Settings

The report uses code folding to keep output clean:

- `code-fold: true` - Code is hidden by default
- `code-summary: "Show code"` - Toggle to reveal code blocks
- Set chunk options `message: false` and `warning: false` in code blocks

## Quarto Execution Model

**Key concept:** `freeze: auto` prevents R/Python environment conflicts during final assembly. Chapters are cached and only re-executed when their source files change.

**Execution engines:**

- Python chunks use the `uv` virtual environment
- R chunks use the `renv` library
- Jupyter kernel: `python3`

## R Environment Setup

`.Rprofile` and `.Renviron` are committed to make the project portable across IDEs (RStudio, Positron, VS Code).

**Critical ordering:** `.Rprofile` activates `renv` first (`source("renv/activate.R")`), then loads vscode-R session watcher. If renv activates after `languageserver`/`httpgd` load, the wrong `rlang` namespace gets pinned for the session.

`.Renviron` sets `RENV_CONFIG_SYNCHRONIZED_CHECK=FALSE` to skip the per-startup lock-file sync (saves ~1.4 s). Run `renv::status()` manually when needed.

## FACT Table Workflow

The shared data contract for indicator observations. Each analyst writes their indicator's data to `data/fact/{indicator_id}.csv`; the report collates them at render time.

**Analyst steps (in every indicator script):**

```r
source(here::here("scripts", "R", "fact_helpers.R"))  # or via _common.R

# 1. Wrangle to exactly three columns: period_start, period_end, value
my_tbl <- raw_data |>
  transmute(
    period_start = as.Date(paste0(year, "-01-01")),
    period_end   = as.Date(paste0(year, "-12-31")),
    value        = my_metric
  )

# 2. Validate and stamp with indicator_id
fact_tbl <- build_fact(my_tbl, indicator_id = "RI_5_ghg_emissions")

# 3. Write to data/fact/RI_5_ghg_emissions.csv
save_fact(fact_tbl)
```

**At render time** (`_common.R` sources `collate_fact.R`):

```r
fact <- collate_fact()            # binds all data/fact/*.csv
rv   <- build_reporting_view(fact) # one row per indicator: latest, previous, sparkline

# Per-chapter GT summary table
# units/unit_type are looked up from core_dim_data_tbl by indicator_id
format_indicator_summary(rv, "RI_5_ghg_emissions", dim_tbl = core_dim_data_tbl, polarity = 1L)
```

**Rules enforced by `build_fact()`:** exactly `period_start`, `period_end`, `value` columns; no duplicate `period_end` per indicator; dates must coerce without NA; `period_start <= period_end`.

`polarity` (`format_indicator_summary()` arg, and a column on `core_dim_data_tbl`) marks whether an increase is good (`1`), bad (`-1`), or neutral (`0`) — it drives the up/down arrow colour in GT tables.

**Multi-indicator summary tables** (`dim_data.R` + `summary_tables.R`, both sourced by `_common.R`):

```r
# core_dim_data_tbl is loaded from data/common_project_data/indicators-master.xlsx
rv <- build_reporting_view(collate_fact())

# One row per indicator within a priority — chapter top-of-page summary
format_priority_summary(rv, core_dim_data_tbl, priority = 3)

# One table per priority, stacked — report landing page (index.qmd)
format_overall_summary(rv, core_dim_data_tbl)
```

See [`docs/summary-table-units.md`](docs/summary-table-units.md) for how `units` and the change column handle percentages vs. percentage points.

**Sparkline note:** `format_indicator_summary()` generates SVG strings directly (not via `svglite`). Never use device rendering for inline GT sparklines — browsers fill `fill`-less polylines black.

## Chapter Setup

Every chapter sources `_common.R` which loads all shared helpers:

```r
source(here::here("scripts", "R", "_common.R"))
```

This provides: `theme_weca`, `load_csv()`, `build_fact()`, `save_fact()`, `collate_fact()`, `build_reporting_view()`, `format_indicator_summary()`, `core_dim_data_tbl`, `format_priority_summary()`, `format_overall_summary()`.

Each chapter directory also carries a `README.md` documenting its indicator table (ID, name, status, data source, refresh cadence) and known data gaps — see `chapters/03-place/README.md` for the pattern.

## Database Connection

`scripts/R/db_connect.R` connects to Postgres via variables in `.env` (gitignored):

```
POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD
```

Call `readRenviron(".env")` before sourcing `db_connect.R` in interactive scripts.

## Azure Blob Raw Data Sync

Raw chapter data (`data/raw/`) is not committed — it's synced from the central Azure Blob container. See the `sync-raw-data` skill for the commands and auth flow.

## R Documentation (btw MCP)

An MCP server for the `btw` R package is available. Use it when writing or reviewing R code in chapters:

- **`mcp__r-btw__btw_tool_docs_help_page`** — fetch full help pages (usage, arguments, examples) for any R function
- **`mcp__r-btw__btw_tool_docs_available_vignettes`** / **`btw_tool_docs_vignette`** — list and read package vignettes
- **`mcp__r-btw__btw_tool_docs_package_help_topics`** — list all topics in a package
- **`mcp__r-btw__list_r_sessions`** — inspect active R sessions (requires `mcptools::mcp_session()` running in R)

Use these tools instead of guessing R function signatures. Particularly valuable for ggplot2, dplyr, tidyr, and other tidyverse packages used in chapters.

**Data locations:**

- `data/` - Project data assets
- Raw data sources should be documented in chapter READMEs
- Processed data should be reproducible via documented scripts

## Output

Rendered reports are written to:

- `_output/` (configured in `_quarto.yml`)

This directory is gitignored - only source files are version controlled. The report is published to GitHub Pages via GitHub Actions.

**Setup (run once per clone):**

```bash
bash scripts/hooks/install-hooks.sh
```

**What the hook scans for:**

- `.env` files (blocked automatically)
- API keys (OpenAI, GitHub, AWS, Slack)
- Variable assignments containing passwords, tokens, credentials

**If a commit is blocked:**

1. Remove the secret from the file
2. Move credentials to environment variables or `.env` files (gitignored)
3. For false positives, update exclude patterns in `scripts/hooks/scan_secrets.sh`

## Agent skills

### Issue tracker

Issues live in GitHub Issues (`westofengland-ca/weca_regional_indicators`). See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles mapped to default label strings. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout — one `CONTEXT.md` + `docs/adr/` at the repo root, per `docs/agents/domain.md`. Not yet created: check before assuming either exists.
