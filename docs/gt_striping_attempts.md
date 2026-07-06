# Removing Bootstrap row striping from GT tables

**Problem:** GT summary tables rendered in the Quarto/cosmo (Bootstrap) theme show
alternating row shading. This conflicts with the green group-header fill applied to
priority rows via `tab_style(locations = cells_row_groups())`.

## Attempts (all unsuccessful)

### 1. `tab_options(row.striping.include_table_body = FALSE)`
Added to the `tab_options()` call in `format_overall_summary()` (`scripts/R/summary_tables.R`).
Stripped out because it only suppresses the GT-level option; the striping is actually
applied by Bootstrap CSS, not by GT itself.

### 2. `gt::opt_row_striping(row_striping = FALSE)`
GT's dedicated function for disabling row striping. Same root cause — has no effect
on the Bootstrap `.table-striped` stylesheet rule applied to all `<table>` elements
in the cosmo theme.

### 3. `gt::tab_style(cell_fill("white"), locations = cells_body())`
Inlines `background-color: white` on every GT body cell, which should beat the
stylesheet in specificity. Did not override the Bootstrap rule in practice, possibly
because Bootstrap uses the `--bs-table-accent-bg` CSS custom property rather than
a direct `background-color` declaration.

### 4. Custom SCSS rule in `custom.scss`
```scss
.gt_table tbody tr:nth-of-type(odd) > * {
  background-color: white !important;
  --bs-table-accent-bg: transparent !important;
}
```
Targets GT table rows directly and resets both the property and the CSS variable.
Still did not work — root cause not confirmed but likely that GT tables are rendered
as self-contained HTML blobs that are inserted after the page stylesheet is applied,
so the custom SCSS may not reach inside the GT HTML.

## Resolution (adopted)

The single grouped table was abandoned. `format_overall_summary()` now returns a
`gt::gt_group()` of **one table per priority**, stacked with spacing. Each table
carries its priority label as a full-width column spanner styled green
(`cells_column_spanners()` + `cell_fill("#d0e4d5")`); the overall title/subtitle
sit on the first table only. Fixed px column widths (`.overall_col_px`) plus
`table.layout = "fixed"` keep the stacked tables aligned.

This sidesteps the Bootstrap `.table-striped` conflict entirely: any alternating
stripe inside a single-priority table, under its own green spanner, is
unambiguous rather than fighting a group band. No CSS override needed.

See `scripts/R/summary_tables.R` (`.build_priority_gt()` / `format_overall_summary()`).

## Notes for future investigation (if a single grouped table is ever revisited)

- GT tables are output as self-contained HTML fragments via `gt::as_raw_html()` /
  `gt::render_gt()`. Styles may need to be injected inside the fragment itself
  rather than via the page stylesheet.
- A potential avenue: use `gt::opt_css()` to inject raw CSS directly into the GT
  table's own `<style>` block, e.g.:
  ```r
  gt::opt_css("tbody tr:nth-of-type(odd) td { background-color: white !important; }")
  ```
- Another avenue: override at the Quarto level by setting `df-print: kable` or
  wrapping the GT output in a `div` with a custom class that resets Bootstrap table
  styles.
