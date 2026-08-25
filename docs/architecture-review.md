# Architecture Review: weca_regional_indicators

> Review of the workspace architecture. Advisory only — no files were modified as part of the review itself.

## What's working well

Before the critique — this is a genuinely well-thought-out setup for a small analyst team:

- **Per-indicator FACT files** (`data/fact/{id}.csv` + `build_fact()`/`save_fact()`) with strict schema validation is a smart pattern: it kills merge conflicts and enforces a data contract at the write boundary.
- **Committed `_freeze/` cache** is the right call for a team whose CI can't access raw data (VPN-gated Azure blob). Analysts render locally, commit source + cache together, CI assembles without re-executing.
- **The presentation deck is derived, not authored** — chart-as-slide via the `fig-alt:` convention with a hard error when the freeze cache is stale is a genuinely elegant design.
- Fail-fast render (`error: true`), secret-scanning pre-commit hook + CI step, `renv` with a correct activation order in `.Rprofile`, and the `presentation/.Rprofile` `RENV_PROJECT` trick are all solid details.
- The global geometry sizing via `element_geom()` in `theme_weca.R` is a nice way to keep charts consistent.

The issues below are mostly about **enforcing invariants the team already relies on implicitly** and **untangling data-refresh from report-rendering**.

---

## 1. Data refresh and report rendering are entangled (biggest architectural smell)

Indicator scripts (e.g. `scripts/R/01-economy/RI_1B1_gdp_growth.R`) bundle **three responsibilities**: (a) read raw data, (b) build+write the FACT CSV (`save_fact()`), and (c) construct the chart object (`RI_1B1_plot`). Chapters then **`source()` these scripts at render time** (`chapters/01-economy/index.qmd` setup chunk).

Consequences:

- **Rendering mutates committed data files.** Every re-render re-runs `save_fact()`, and `build_fact()` stamps `last_updated = Sys.Date()` on *every row* — including 2015 observations. A chapter re-render (qmd edit, or `--clean-freeze`) rewrites all its FACT CSVs with today's date, so "last updated" actually means "pipeline last ran". This is exactly why `csv-alert.yml` has to strip the column to detect real changes.
- **`_common.R` is sourced N+1 times per chapter** (once directly, once per indicator script). `dim_data.R` re-reads the master xlsx each time. Harmless but wasteful; also not idempotent.
- **Render-time side effects** mean a render can silently overwrite a colleague's freshly-committed values (if both re-render on the same day).

Recommendations:

- Split each indicator into a **refresh script** (manual: raw → `save_fact()`) and the **chart code** that chapters source. The chapter setup chunk should only build plots.
- Make `save_fact()` **idempotent**: read the existing file and skip writing (or only update rows whose values changed) when content is identical. Stamp `last_updated` only for rows that actually changed, or drop the column and let git be the timestamp.
- Guard `_common.R` with a sentinel (`if (!exists(".__weca_common_loaded__"))`) so double-sourcing is free.

## 2. `freeze: auto` + committed data = silently stale published site

Per the [Quarto docs on code execution](https://quarto.org/docs/projects/code-execution.html), `freeze: auto` means *"re-render only when source changes"* — it does **not** invalidate when a data file read inside a chunk changes. Your summary tables and figures read committed `data/fact/*.csv` and `indicators-master.xlsx`, so:

- A push that updates only a FACT CSV (no qmd change) → CI reuses the frozen summaries/figures → **the published site serves stale numbers** with a green build.
- The convention exists in CONTRIBUTING.md ("force re-execution, e.g. data updated") but nothing enforces it. `csv-alert.yml` is the only guard and it's hardcoded to **one CSV and one person** ("tell Joe", assignee `stevecrawshaw`).

Recommendations:

- Add a **pre-commit hook or CI check** that maps each changed `data/fact/{id}.csv` to its chapter (the `RI_1*` → `01-*` prefix mapping holds in practice) and fails unless the chapter's `_freeze/.../execute-results/html.json` changed in the same commit. This automates the invariant your workflow docs already describe.
- Generalize `csv-alert.yml` to all FACT CSVs, or fold it into the freshness check above.
- Decide explicitly: FACT CSVs + master xlsx are **render inputs**, so their updates must always be accompanied by a re-render commit. Document that as a hard rule, then enforce it.

## 3. Data integrity has no automated guard — I found real defects

There is zero automated validation of the FACT corpus between `build_fact()` time and render. Concrete findings:

- **Duplicate indicator under two IDs**: `data/fact/RI_3C4_temp_accom.csv` and `data/fact/RI_3C4_temp_accommodation.csv` contain identical data under different `indicator_id`s. No script writes the `_accom` id anymore (the script writes `RI_3C4_temp_accommodation`) — it's an orphan that `collate_fact()` still binds into the reporting view.
- **Stale "_plot" artifact**: `data/fact/RI_2C2_pop_30min_employment_plot.csv` is an old plot-specific aggregation collated into every render; the current script writes `RI_2C2_pop_30min_employment`.
- **53 indicator scripts vs 49 FACT files** — several scripts (e.g. `RI_4B4_neet_18_24`, `RI_4C1_skills_gaps`, `RI_6C1`, `RI_6D1–D3`) have no FACT output (work in progress), and nothing flags the mismatch either way.

Recommendation: add `scripts/R/check_consistency.R` run in CI that cross-references:

- every `data/fact/*.csv` `indicator_id` resolves in `indicators-master.xlsx` (and its `include` flag is deliberate),
- every `include == TRUE` indicator has a FACT file,
- no `_plot`/suffix ids, no id mismatches between script, CSV, and master.

## 4. The DIM master table is read in a fragile way

`dim_data.R` does `read_excel(..., range = "A2:AP100")` — a hardcoded range, so a 101st row or a new column is **silently dropped**. `include` filtering is silent, and `get_dim_priority()` extracts the priority number from free text via `str_extract(priority, "\\d")`. The `valid_unit_types` check and `check_order_within_priority()` are good fail-fasts, but they only fire at render.

Recommendations: read the whole used range (or a named range), add a proper numeric `priority` column to the master, and let the consistency checker (item 3) validate fact↔dim completeness so problems surface in CI, not in a `quarto render` on someone's machine.

## 5. No tests, and lintr is configured but never runs

- Zero `testthat` tests for the report backbone: `build_fact()` edge cases (zero rows, dup periods), `build_reporting_view()` (single observation → `previous_value = NA`; zero denominator → `pct_change = Inf`; `latest/previous` with irregular periods), `.fmt_change`/`.change_colour` (percent vs ppt, polarity), and the sparkline SVG generator. These are the most-fixed, highest-stakes functions in the repo; a small testthat suite is cheap and would have caught the kind of copy-paste bug in item 7.
- `.lintr` exists but `publish.yml` runs only the secret scan. Add a lint job (and run it on PRs).
- `pyproject.toml` points pytest at `tests/`, which doesn't exist (the only Python is `scripts/vtt_to_text.py`, a review-process utility).

## 6. CI can assemble but can never rebuild — surface breakage before merge

Because raw data is VPN-gated and `data/raw/` isn't in CI (or even in a fresh checkout), a clean render is impossible in CI — the committed `_freeze/` is the only bootstrap. That's fine, but it means:

- The **only** place the book is rendered is the `main` push in `publish.yml`; a chapter that can't render (missing raw file, schema error) breaks publishing at deploy time, with no PR-time warning.
- There's no PR workflow at all — no lint, no consistency check, no freeze-freshness check, no `test_render.sh --fast`.

Recommendation: add a `pull_request` workflow that runs the cheap checks that don't need raw data: secret scan, lintr, `check_consistency.R`, freeze freshness (item 2), and `test_render.sh --fast` syntax checks. Keep the expensive full render on `main`, but know that's where rendering defects will surface — the pre-merge checks exist to catch everything else.

## 7. Content and docs drift (quick wins)

- **Copy-paste bug in a shipped chapter**: in `chapters/01-economy/index.qmd`, the median-wage card (`RI_1B3_median_wage`) is titled "Annual GVA per job, 2013-2023" with the GVA subtitle — wrong title/subtitle for the indicator. `QA_CHECKLIST.md` exists but nothing catches this; a consistency check comparing card titles against the master's `indicator_summary` would.
- **Chapter READMEs are 5/6 empty templates.** CLAUDE.md cites `chapters/03-place/README.md` as the documented pattern, but it's a placeholder ("Add a row per indicator as they are developed"). Only `05-environment` is actually filled in. Either populate them (they're the agreed data-provenance record) or drop the requirement.
- **Stale duplicated docs**: `docs/review/*.md` are byte-identical to `review/*.md` (post-"move review folder" leftovers). `.gitignore` now lists `docs/review/`, but the files remain tracked — `git rm` the old copies so the two don't drift.
- **CLAUDE.md is out of date**: it says `docs/agents/domain.md` is "not yet created" (it exists), claims Python "is not part of the toolchain" (there's a pyproject/uv setup for the transcript tool), and references the 03-place README pattern that doesn't exist.
- Small stuff: `index.qmd` line 6 has "West of England West of England's priority areas" (duplicated phrase); `data/README.md` recommends Python/pathlib patterns in an R-only project and has "cheque" typos; `scripts/R/01-economy/old_RI_1B1_gdp_growth.R` and `scripts/R/test_fonts.R` are dead files; indicator scripts retain commented-out exploratory code (`## |> glimpse()`).

## 8. Shared-code hygiene

- `%||%` is defined in **two files** (`reporting_table.R`, `presentation_manifest.R`) — later `source()` silently wins.
- `.fmt_change`/`.change_colour` live in `summary_tables.R` but are used by `reporting_table.R` — implicit cross-file coupling that only works because both are always loaded via `_common.R`.
- `helpers.R` has `library()` calls inside functions (`summary_table()`, `check_missing()`), mixed `%>%`/`|>` styles, and some functions that look unused by chapters (worth an audit).
- If the team wants to go further: promote `scripts/R/` into a tiny internal R package (e.g. `wecareport`) via renv. That gives you explicit dependencies, `::` namespacing, and testthat integration — but it's a bigger change; the minimum viable version is the idempotent `_common.R` + tests above.

## 9. Minor operational notes

- **Font divergence between analyst machines and CI**: the theme hardcodes Arial/Trebuchet MS (Windows fonts), but `publish.yml`'s Ubuntu runner doesn't install `msttcorefonts`. Frozen PNGs mask this until something forces a Linux re-render (e.g. `--clean-freeze`), at which point charts render with substituted fonts and look different. Either install the fonts in CI or document that figures are Windows-rendered.
- `docs/issues.md` is a hand-maintained backlog that overlaps with GitHub Issues (which you have templates and an issue-tracker skill for) — worth migrating so items don't live in two places.
- The `review/` questionnaire/interview artifacts are committed to a **public** repo. The transcripts were correctly untracked, but double-check the questionnaires/guides for any participant-identifying content before the review work goes live.

---

## Suggested priority order

| # | Action | Effort | Impact |
|---|---|---|---|
| 1 | Delete the two orphan FACT files (`RI_3C4_temp_accom.csv`, `RI_2C2_pop_30min_employment_plot.csv`) | 5 min | Fixes real data defects |
| 2 | Make `save_fact()` idempotent + `_common.R` guarded; stop stamping `last_updated` on unchanged rows | Small | Kills render-time data churn |
| 3 | `check_consistency.R` (fact ↔ master ↔ scripts) run in CI + PR workflow | Medium | Prevents silent staleness/defects |
| 4 | Freeze-freshness enforcement (pre-commit hook or CI) when FACT CSVs change | Medium | Protects the published report |
| 5 | testthat suite for the shared report functions + lint job | Medium | Catches formatting/edge-case regressions |
| 6 | Separate indicator *refresh* scripts from chapter *chart* code | Larger | Cleanest architectural fix |
| 7 | Docs/QA sweep (duplicated `docs/review/`, CLAUDE.md, chapter READMEs, copy-paste title) | Small | Trustworthy docs, better QA |

## Bottom line

The architecture's core bets — per-indicator data files, committed freeze cache, derived deck, blob-synced raw data — are sound for a 6-analyst team. The main improvement opportunity is **making the invariants you already rely on explicit and enforced** (data changes ⇒ re-render; scripts ⇒ fact ⇒ master consistency) and **decoupling data refresh from rendering** so that rendering a chapter never mutates committed data.
