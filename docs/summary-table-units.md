# Units in summary tables: percentages vs. percentage points

Units and percentage handling flow through three files, and there's a key
distinction between an indicator's **own units** and the **units of its
period-over-period change**.

## 1. Where units come from

`units` is a plain string per indicator in
`data/common_project_data/indicators-master.xlsx` (e.g. `"%"`, `"kt CO2e"`,
`"GBP"`). It's pulled in via `get_dim_priority()` / `get_dim_all()` in
`scripts/R/dim_data.R:21-51` and joined onto the reporting view. The **latest
value** column in every summary table just shows this string as-is next to
the formatted number — no unit-aware logic there.

## 2. Change is computed two different ways depending on whether the indicator is itself a percentage

In `build_reporting_view()` (`scripts/R/collate_fact.R:124-127`), a relative
`pct_change` is *always* precomputed for every indicator, unit-agnostic:

```r
pct_change = (latest_value / previous_value - 1) * 100
```

But that's only actually used for non-percentage indicators. In
`format_overall_summary()` (`scripts/R/summary_tables.R:353-360`), the code
branches on the indicator's own units:

```r
is_percent = (units == "%"),
change_raw = dplyr::if_else(
  is_percent,
  latest_value - previous_value,   # simple point difference
  pct_change                       # relative % change from build_reporting_view()
)
```

The reasoning: if an indicator is already a percentage (e.g. employment rate
74.8% -> 75.2%), the meaningful change is the **percentage-point difference**
(+0.4 ppt), not the relative change of a percentage (+0.53%), which is
misleading and rarely what a reader wants. For a non-percentage indicator
(e.g. GHG emissions in kt), the natural change measure is relative % change.

## 3. Formatting the suffix

`.fmt_change()` (`scripts/R/summary_tables.R:31-49`) picks the suffix to
match which branch was taken:

```r
suffix <- dplyr::if_else(is_percent, " ppt", "%")
```

So confusingly-but-consistently: `units == "%"` indicators get a `" ppt"`
suffix on their change column, and everything else gets `"%"` (because their
`change_raw` already *is* a relative percentage).

## 4. Arrow direction and colour are independent of the above

`.change_colour()` (`scripts/R/summary_tables.R:56-66`) only cares about the
sign of `change_raw` and the indicator's `polarity` (+1 = up is good, -1 = up
is bad, from indicators-master.xlsx) — it doesn't care whether the underlying
number was ppt or %.

## Caveat

`format_priority_summary()` (the per-chapter table) doesn't do any of this —
it has no `change` column at all, just latest value + units verbatim. The
ppt/% distinction only applies to `format_overall_summary()` on the landing
page.
