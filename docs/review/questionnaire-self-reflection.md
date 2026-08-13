# 2026 Project Review — Coordinator Self-Reflection (Steve)

Same structure as the analyst questionnaire where it overlaps, plus coordination-specific
questions. Answer async, or talk it through and I'll write it up.

---

## 1. Setting up the project

1. What did the initial setup (repo scaffolding, `_common.R`, FACT table contract,
   chapter structure, `.Rprofile`/`renv` config) take to get right? What would you do
   differently starting from scratch?
2. Did the chosen architecture (one chapter directory per analyst, shared `data/` and
   `scripts/`, freeze-cache rendering) hold up under five-plus contributors, or did it
   create friction you didn't anticipate?

## 2. Coordination load

3. Git history shows you authored the large majority of commits (122 of 161). How much
   of that reflects direct authorship of others' chapter content versus your own
   Environment chapter, shared infrastructure, and fixes on their behalf? Was that the
   intended division of labour?
4. How much time did you spend unblocking other analysts (git, Quarto, rendering,
   FACT-table issues) versus on your own chapter content or report-level work?
5. Were there points where you were a single point of failure — work stalled because it
   was waiting on you specifically?

## 3. Pace and pressure points

6. The commit history shows two clear spikes (April, June) either side of quieter
   months (Feb–Mar, May) and a final push in August. Does that match your sense of how
   the project actually ran? What drove the spikes?
7. Were there points where you felt the project was at risk of missing its deadline?
   What got it back on track (or didn't)?

## 4. Tooling and process

8. Which recurring technical issues cost the most collective time (freeze-cache
   staleness, `renv` drift, R language-server timeouts, sparkline/GT rendering quirks,
   others)? Are any of these fixable at the template/tooling level before next year
   rather than being re-discovered chapter by chapter?
9. Did the GitHub Issues tracker get used as intended during the project, or did most
   coordination happen informally (Slack/Teams/conversation) and go unrecorded?

## 5. Working with clients/managers

10. Did you feel you had what you needed from the commissioning managers at the right
    points (clarity on priorities, timely feedback, sign-off)?
11. Was there anything you had to guess or assume because client input wasn't
    available when needed?

## 6. Looking forward

12. If you ran this again next year with the same team shape, what's the first thing
    you'd change?
13. If you could change the team shape or process itself (not just tooling), what
    would you propose?
14. What worked well enough that it should be treated as the template for next year,
    not just a one-off?
