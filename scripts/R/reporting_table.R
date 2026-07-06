# Per-indicator summary GT tables -------------------------------------------
#
# Turn one row of the reporting view (see `build_reporting_view()` in
# `collate_fact.R`) into a compact two-column GT table suitable for dropping
# into a chapter. The right-hand column hosts an inline sparkline on the
# "Trend" row, drawn as a hand-built SVG string and injected with
# `gt::text_transform()`. Generating SVG directly (rather than via a graphics
# device such as svglite) ensures `fill="none"` is explicit on the polyline --
# device-rendered SVG omits this attribute and browsers fill the path black.
# Using our own SVG (rather than `gtExtras::gt_plt_sparkline()`) also keeps
# the table a clean two-column layout and avoids the list-column/cols_merge
# interaction that previously left raw list contents in the rendered output.
#
# Usage:
#
#   source(here::here("scripts", "R", "collate_fact.R"))
#   source(here::here("scripts", "R", "reporting_table.R"))
#   fact <- collate_fact()
#   rv   <- build_reporting_view(fact)
#   format_indicator_summary(rv, "RI_5_ghg_emissions")

#' Format a single indicator's reporting-view row as a GT summary table
#'
#' Pulls one row out of the reporting view, pivots it to a two-column
#' (metric, value) layout, and renders it with `gt::gt()`. A sparkline of the
#' full history is drawn on the "Trend" row as an inline SVG generated with
#' svglite and injected via `gt::text_transform()`.
#'
#' @param reporting_view A tibble produced by `build_reporting_view()`. Must
#'   contain: `indicator_id`, `latest_period_end`, `latest_value`,
#'   `previous_period_end`, `previous_value`, `first_period_end`, `first_value`,
#'   `pct_change`, `pct_change_since_first`, `n_observations`, `sparkline`,
#'   `last_updated`.
#' @param indicator_id Character scalar identifying the row to render.
#' @param units Character scalar. Units suffix shown alongside the latest /
#'   previous / first values, e.g. `"kt CO2e"`, `"GWh"`, `"%"`. Default `""`
#'   (no unit). When `units == "%"`, the "Change vs previous" and "Change
#'   since first" rows are expressed in **percentage points** (absolute
#'   difference of the underlying values) rather than as a relative
#'   `pct_change`, since a relative change between two percentages is
#'   rarely what readers want.
#' @param title Optional gt table title. Defaults to `indicator_id`.
#' @param subtitle Optional gt table subtitle.
#' @param value_fmt Optional formatter applied to the numeric value cells
#'   (latest / previous / first). Any function that takes a numeric vector
#'   and returns a character vector works. Defaults to
#'   `scales::label_comma(accuracy = 0.1)`.
#'
#' @return A `gt_tbl` object.
#'
#' @examples
#' \dontrun{
#' source(here::here("scripts", "R", "collate_fact.R"))
#' source(here::here("scripts", "R", "reporting_table.R"))
#' rv <- build_reporting_view(collate_fact())
#'
#' # Default formatting (comma-separated numerics with a unit suffix)
#' format_indicator_summary(rv, "RI_5_ghg_emissions", units = "kt CO2e")
#'
#' # Percentage indicator - change rows switch to percentage points
#' format_indicator_summary(rv, "RI_5A1_renewable_share", units = "%")
#' }
format_indicator_summary <- function(reporting_view,
                                     indicator_id,
                                     units = "",
                                     polarity = 0L,
                                     title = NULL,
                                     subtitle = NULL,
                                     value_fmt = NULL) {
  # --- argument validation -------------------------------------------------
  if (!is.data.frame(reporting_view)) {
    stop("`reporting_view` must be a data frame produced by build_reporting_view().",
      call. = FALSE
    )
  }
  if (!is.character(indicator_id) || length(indicator_id) != 1L ||
    is.na(indicator_id) || !nzchar(indicator_id)) {
    stop("`indicator_id` must be a single non-empty character string.",
      call. = FALSE
    )
  }
  if (!is.character(units) || length(units) != 1L || is.na(units)) {
    stop("`units` must be a single character string (use \"\" for none).",
      call. = FALSE
    )
  }
  if (!is.numeric(polarity) || length(polarity) != 1L || is.na(polarity) ||
      !polarity %in% c(-1L, 0L, 1L)) {
    stop("`polarity` must be one of -1 (up is bad), 0 (neutral), or 1 (up is good).",
      call. = FALSE
    )
  }

  required <- c(
    "indicator_id", "latest_period_end", "latest_value",
    "previous_period_end", "previous_value",
    "first_period_end", "first_value",
    "pct_change", "pct_change_since_first",
    "n_observations", "sparkline", "last_updated"
  )
  missing_cols <- setdiff(required, names(reporting_view))
  if (length(missing_cols) > 0L) {
    stop("`reporting_view` is missing required columns: ",
      paste(missing_cols, collapse = ", "),
      ". Did you pass the raw FACT table instead of build_reporting_view() output?",
      call. = FALSE
    )
  }

  # --- row selection -------------------------------------------------------
  row <- reporting_view[reporting_view$indicator_id == indicator_id, , drop = FALSE]
  if (nrow(row) == 0L) {
    available <- paste(sort(unique(reporting_view$indicator_id)), collapse = ", ")
    stop("No row for indicator_id '", indicator_id, "'. Available ids: ",
      available,
      call. = FALSE
    )
  }
  if (nrow(row) > 1L) {
    stop("More than one row matched indicator_id '", indicator_id,
      "'. The reporting view should have one row per indicator - ",
      "investigate build_reporting_view() upstream.",
      call. = FALSE
    )
  }

  # --- sparkline column sanity check ---------------------------------------
  if (!is.list(row$sparkline) || length(row$sparkline) != 1L ||
    !is.numeric(row$sparkline[[1]])) {
    stop("`reporting_view$sparkline` must be a list-column of numeric vectors.",
      call. = FALSE
    )
  }
  spark_vec <- row$sparkline[[1]]

  # --- formatting helpers --------------------------------------------------
  # NB: When units == "%" we report change rows in percentage points rather
  # than as pct_change, since a relative change between two percentages is
  # rarely what a reader wants (20% -> 22% is +2 ppts, not +10%). Longer
  # term this logic belongs in build_reporting_view() alongside a proper
  # units column on the FACT/DIM tables.
  if (is.null(value_fmt)) {
    value_fmt <- scales::label_comma(accuracy = 0.1)
  }
  # No space before "%" (e.g. "22.4%"); space for worded units (e.g. "4,410 kt CO2e").
  unit_suffix <- if (!nzchar(units)) {
    ""
  } else if (identical(units, "%")) {
    "%"
  } else {
    paste0(" ", units)
  }
  fmt_val <- function(x) {
    if (is.na(x)) {
      return(NA_character_)
    }
    paste0(value_fmt(x), unit_suffix)
  }
  fmt_date_suffix <- function(d) {
    if (is.na(d)) "" else paste0(" (", format(d), ")")
  }

  latest_txt <- paste0(
    fmt_val(row$latest_value), fmt_date_suffix(row$latest_period_end)
  )
  previous_txt <- paste0(
    fmt_val(row$previous_value), fmt_date_suffix(row$previous_period_end)
  )
  first_txt <- paste0(
    fmt_val(row$first_value), fmt_date_suffix(row$first_period_end)
  )

  is_percent <- identical(units, "%")
  change_vs_previous_raw <- if (is_percent) {
    row$latest_value - row$previous_value
  } else {
    row$pct_change
  }
  change_since_first_raw <- if (is_percent) {
    row$latest_value - row$first_value
  } else {
    row$pct_change_since_first
  }
  change_vs_previous_txt <- .fmt_change(change_vs_previous_raw, is_percent)
  change_since_first_txt <- .fmt_change(change_since_first_raw, is_percent)
  col_vs_prev  <- .change_colour(change_vs_previous_raw, polarity)
  col_vs_first <- .change_colour(change_since_first_raw, polarity)

  # --- long-form two-column table -----------------------------------------
  # The Trend row's value is a placeholder; text_transform() below replaces
  # it with an inline SVG sparkline.
  trend_placeholder <- "__SPARKLINE__"
  display_tbl <- tibble::tibble(
    metric = c(
      "Latest value",
      "Previous value",
      "Change vs previous",
      "First value",
      "Change since first",
      "Observations",
      "Trend",
      "Last updated"
    ),
    value = c(
      latest_txt,
      previous_txt,
      change_vs_previous_txt,
      first_txt,
      change_since_first_txt,
      as.character(row$n_observations),
      trend_placeholder,
      format(row$last_updated)
    )
  )

  sparkline_svg <- .make_sparkline_svg(spark_vec)

  gt::gt(display_tbl) |>
    gt::tab_header(
      title    = title %||% indicator_id,
      subtitle = subtitle
    ) |>
    gt::cols_label(metric = "", value = "") |>
    gt::cols_align(align = "left", columns = "metric") |>
    gt::cols_align(align = "right", columns = "value") |>
    gt::text_transform(
      locations = gt::cells_body(
        columns = "value",
        rows    = metric == "Trend"
      ),
      fn = function(x) sparkline_svg
    ) |>
    gt::tab_style(
      style     = gt::cell_text(color = col_vs_prev),
      locations = gt::cells_body(
        columns = "value",
        rows    = metric == "Change vs previous"
      )
    ) |>
    gt::tab_style(
      style     = gt::cell_text(color = col_vs_first),
      locations = gt::cells_body(
        columns = "value",
        rows    = metric == "Change since first"
      )
    ) |>
    gt::tab_options(
      table.width          = gt::pct(60),
      column_labels.hidden = TRUE
    )
}

#' Render a minimal sparkline as an inline SVG string
#'
#' Internal helper. Generates SVG markup directly (no graphics device) so the
#' output is a portable string suitable for injection into gt cells via
#' `text_transform()`. Using direct SVG construction guarantees `fill="none"`
#' on the polyline -- device-rendered SVG (svglite) omits this attribute and
#' browsers then fill the path black by default.
#'
#' @param vec Numeric vector (oldest to newest).
#' @param width,height SVG viewport dimensions in pixels.
#' @return A single character string containing `<svg>...</svg>`.
#' @keywords internal
.make_sparkline_svg <- function(vec, width = 150, height = 30) {
  n <- length(vec)

  # Single-point edge case: just draw the endpoint dot.
  if (n < 2L) {
    return(paste0(
      '<svg xmlns="http://www.w3.org/2000/svg" width="', width,
      '" height="', height, '">',
      '<circle cx="', width / 2, '" cy="', height / 2,
      '" r="2.5" fill="#c00000"/>',
      "</svg>"
    ))
  }

  y_rng <- range(vec, na.rm = TRUE)
  # Avoid degenerate range (all values identical).
  if (diff(y_rng) == 0) y_rng <- y_rng + c(-1, 1)

  margin <- 3
  plot_w <- width - 2 * margin
  plot_h <- height - 2 * margin

  xs <- margin + (seq_len(n) - 1L) / (n - 1L) * plot_w
  # SVG y-axis is top-down, so invert the data direction.
  ys <- margin + (1 - (vec - y_rng[1]) / diff(y_rng)) * plot_h

  pts <- paste(round(xs, 1), round(ys, 1), sep = ",", collapse = " ")

  paste0(
    '<svg xmlns="http://www.w3.org/2000/svg" width="', width,
    '" height="', height, '">',
    '<polyline points="', pts,
    '" fill="none" stroke="#1f4e79" stroke-width="1.5"',
    ' stroke-linejoin="round" stroke-linecap="round"/>',
    '<circle cx="', round(xs[n], 1), '" cy="', round(ys[n], 1),
    '" r="2.5" fill="#c00000"/>',
    "</svg>"
  )
}

# Lightweight null-coalesce so we don't pull in rlang just for this.
`%||%` <- function(x, y) if (is.null(x)) y else x
