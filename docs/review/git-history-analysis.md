# 2026 Project Review — Git History Analysis

Objective read of the repository history (161 commits, 2026-02-16 to 2026-08-07). Source
data for this analysis, not the final write-up — figures should be spot-checked before
quoting in the report.

## 1. Cadence

Commits by ISO week:

| Week | Commits | Note |
|---|---|---|
| 07 (mid-Feb) | 5 | Project kickoff |
| 08–11 | 0 | **4-week gap** |
| 12–17 (late Mar–Apr) | 16, 19, 8, 8, 12 | Sustained April push |
| 18–19 | 3, 2 | Tailing off |
| 20–21 | 0 | **Gap** |
| 22–24 (early–mid Jun) | 1, 15, 30 | Sharp June spike, peaking at 30 commits in one week |
| 25 | 0 | Gap |
| 26–27 | 1, 6 | |
| 28–29 | 0 | Gap |
| 30–31 (early Aug) | 3, 30 | Final push before the last commit on 2026-08-07 |

Reading: **not a steady cadence** — four multi-week silent stretches (Feb–Mar, May,
late Jun, late Jul), each followed by a burst of a dozen-plus commits in a single week.
The two biggest single weeks (19 and 30 commits) sit immediately before what look like
deadline points. Worth asking analysts/Steve directly whether these gaps reflect
data-availability waits, other-work competing for time, or review/feedback cycles
sitting with clients.

Monthly view for reference: Feb 5, Mar 12, Apr 52, May 6, Jun 46, Jul 10, Aug 30.

## 2. Contribution balance — overall

| Author | Commits | % |
|---|---|---|
| Steve Crawshaw | 122 | 76% |
| Megan Johns | 23 | 14% |
| Simon.Moss / Simon Moss | 11 | 7% |
| copilot-swe-agent[bot] | 3 | 2% |
| weca-digital-office | 2 | 1% |

## 3. Contribution balance — by chapter

This is the headline finding. Commits touching each chapter directory, by author:

| Chapter | Owner (per Steve) | Total commits | Steve | Owner's own commits |
|---|---|---|---|---|
| 01-economy | Stuart | 17 | 14 | 0 (Simon.Moss: 2, bot: 1) |
| 02-transport | Heather | 8 | 8 | **0** |
| 03-place | Tom | 10 | 10 | **0** |
| 04-skills | Megan | 13 | 11 | 2 |
| 05-environment | Steve | 24 | 24 | — (Steve's own chapter) |
| 06-child-poverty | (unassigned/Steve?) | 8 | 7 | 1 (Megan) |

**Heather, Tom and Stuart have zero commits under their own name anywhere in the
repository.** Every commit touching their chapters was made by Steve. Megan committed
directly but only for a minority of the work on her own chapter. This is worth
confirming directly rather than assuming a cause — possibilities include: analysts
handed off content/data to Steve rather than committing themselves (git unfamiliarity —
consistent with `docs/WORKFLOW_LEARNING_GUIDE.md`'s framing of the workflow as new to
the team), commits were made under a shared/different identity not captured here, or
the coordination model was in practice "Steve commits everyone's work" rather than
"each analyst commits their own." The analyst questionnaire (Q1–3, Q16) should surface
which.

If the pattern holds, the git history alone doesn't tell you how much *authored* work
(vs. data/content handed over) each analyst actually contributed — only who ran `git
commit`. Flag this limitation in the report rather than treating commit counts as
effort.

## 4. Churn — most frequently modified files

| File | Times changed |
|---|---|
| `_freeze/chapters/05-environment/.../html.json` | 31 |
| `chapters/05-environment/index.qmd` | 23 |
| `_freeze/chapters/01-economy/.../html.json` | 23 |
| `renv.lock` | 16 |
| `data/fact/RI_5_ghg_emissions.csv` | 16 |
| `chapters/01-economy/index.qmd` | 16 |
| `.github/workflows/publish.yml` | 14 |

Reading: Environment (Steve's own chapter) and Economy churned hardest — consistent
with §3 showing these as the two most actively iterated chapters. `renv.lock` changing
16 times independently corroborates the renv-drift friction already known from this
project (see memory: `project_renv_drift_surgical_add`). `publish.yml` changing 14 times
suggests the CI/deploy pipeline needed repeated correction rather than being right
first time — worth asking whether that cost coordination time.

## 5. Commit message hygiene

Of 161 commits, only 48 (30%) carry a recognised Conventional Commit prefix
(`fix:` 17, `chore:` 15, `feat:` 13, `docs:` 2, `ci:` 1). The remaining 70% don't follow
the convention documented in `CLAUDE.md`. Not necessarily a problem in itself, but it
means commit-history-based analysis (like this one) has limited reach — a
process improvement (enforcing the convention, e.g. via commitlint) would make next
year's retrospective easier to do from git alone.

## 6. Issue tracker usage

Only 2 GitHub issues exist in the repository, both bot-filed by GitHub Actions
(`CSV values changed - tell Joe: RI_1B1_gdp_growth.csv`), both still open, no human-filed
issues at all. Despite `docs/agents/issue-tracker.md` documenting a GitHub Issues
workflow, it was not used for coordinating this project — day-to-day coordination
evidently happened elsewhere (verbal/Slack/Teams) and isn't captured anywhere durable.
Worth asking directly whether that's a gap worth closing next year, or whether informal
coordination worked fine for a team this size.

## 7. Summary of git-history findings to carry into the report

1. Cadence was bursty, not steady — four multi-week gaps followed by crunch weeks.
2. Steve authored 76% of all commits and 100% of commits on three of six chapters —
   the "one analyst per chapter, each commits their own work" model wasn't what
   happened in practice, at least not via git.
3. Environment and Economy chapters churned hardest; CI pipeline (`publish.yml`) needed
   repeated fixes; `renv.lock` drift was a recurring, not one-off, problem.
4. Commit conventions were followed inconsistently (30% compliance).
5. The issue tracker was unused for human coordination — no durable record of
   day-to-day blockers/decisions exists outside git commits themselves.
