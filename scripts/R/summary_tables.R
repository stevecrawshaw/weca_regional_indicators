# Multi-indicator GT summary tables ------------------------------------------
#
# Two cross-indicator aggregate functions that complement the single-indicator
# card in reporting_table.R:
#
#   - format_priority_summary(): one row per indicator within a priority,
#     for the top of each chapter.
#   - format_overall_summary():  one row per indicator across the whole report,
#     for the landing page (index.qmd).
#
# Both join DIM data (from dim_data.R) to the reporting view produced by
# build_reporting_view() in collate_fact.R.
#
# Usage:
#
#   source(here::here("scripts", "R", "_common.R"))
#   rv  <- build_reporting_view(collate_fact())
#   format_priority_summary(rv, core_dim_data_tbl, priority = 5)
#   format_overall_summary(rv, core_dim_data_tbl)

#' Internal: format a change value with directional arrow and sign
#'
#' Fully vectorised: operates on same-length `value` and `is_percent` vectors.
#' Returns "--" for NA values (no previous observation). Arrows are generated via
#' intToUtf8() so the source file stays ASCII-clean.
#'
#' @param value Numeric vector of change amounts.
#' @param is_percent Logical vector; TRUE for percentage indicators (ppt suffix).
#' @return Character vector.
#' @keywords internal
.fmt_change <- function(value, is_percent) {
  up_arrow <- intToUtf8(8593L)
  down_arrow <- intToUtf8(8595L)
  arrow <- dplyr::if_else(
    value >= 0,
    paste0(up_arrow, " "),
    paste0(down_arrow, " "),
    missing = ""
  )
  sign <- dplyr::if_else(value >= 0, "+", "", missing = "")
  suffix <- dplyr::if_else(is_percent, " ppt", "%")
  formatted <- paste0(
    arrow,
    sign,
    formatC(value, format = "f", digits = 1),
    suffix
  )
  dplyr::if_else(is.na(value), "--", formatted)
}

#' Internal: determine cell colour for a change value given indicator polarity
#'
#' @param change_raw Numeric vector of raw change amounts.
#' @param polarity Numeric vector; +1 means up is good, -1 means up is bad.
#' @return Character vector of hex colour codes.
#' @keywords internal
.change_colour <- function(change_raw, polarity) {
  good <- (change_raw > 0 & polarity == 1) | (change_raw < 0 & polarity == -1)
  bad <- (change_raw < 0 & polarity == 1) | (change_raw > 0 & polarity == -1)
  dplyr::case_when(
    is.na(change_raw) ~ "#888888",
    good ~ "#1a7a3f",
    bad ~ "#c00000",
    TRUE ~ "#888888"
  )
}

#' Per-chapter priority summary GT table
#'
#' One row per indicator within the given priority, showing the latest
#' observed value, its period, and units. Only indicators that have FACT
#' data are included (inner join on indicator_id).
#'
#' @param reporting_view A tibble produced by `build_reporting_view()`. Must
#'   contain `indicator_id`, `latest_period_start`, `latest_period_end`,
#'   `latest_value`.
#' @param dim_tbl The core DIM data tibble (e.g. `core_dim_data_tbl`).
#' @param priority Priority number (1-6) or character. Passed to
#'   `get_dim_priority()`.
#' @param title Optional gt table title.
#' @param subtitle Optional gt table subtitle.
#'
#' @return A `gt_tbl` object.
format_priority_summary <- function(
  reporting_view,
  dim_tbl,
  priority,
  title = NULL,
  subtitle = NULL
) {
  if (!is.data.frame(reporting_view)) {
    stop(
      "`reporting_view` must be a data frame produced by build_reporting_view().",
      call. = FALSE
    )
  }
  if (!is.data.frame(dim_tbl)) {
    stop(
      "`dim_tbl` must be a data frame (e.g. core_dim_data_tbl).",
      call. = FALSE
    )
  }
  if (length(priority) != 1L || is.na(priority)) {
    stop("`priority` must be a single non-NA value.", call. = FALSE)
  }

  required_rv <- c(
    "indicator_id",
    "latest_period_start",
    "latest_period_end",
    "latest_value"
  )
  missing_rv <- setdiff(required_rv, names(reporting_view))
  if (length(missing_rv) > 0L) {
    stop(
      "`reporting_view` is missing columns: ",
      paste(missing_rv, collapse = ", "),
      call. = FALSE
    )
  }

  dim_priority <- get_dim_priority(dim_tbl, priority)

  tbl <- dplyr::inner_join(
    dim_priority,
    reporting_view,
    by = dplyr::join_by(indicator_id)
  )

  check_order_within_priority(tbl)

  tbl <- tbl |>
    dplyr::arrange(order_within_priority) |>
    dplyr::mutate(
      period_start = format(latest_period_start),
      period_end = format(latest_period_end)
    ) |>
    dplyr::select(
      indicator_summary,
      period_start,
      period_end,
      value = latest_value,
      units
    )

  if (nrow(tbl) == 0L) {
    stop(
      "No indicators with FACT data found for priority ",
      priority,
      ".",
      call. = FALSE
    )
  }

  gt::gt(tbl) |>
    gt::tab_header(
      title = title %||% paste0("Priority ", priority, " "),
      subtitle = subtitle
    ) |>
    gt::cols_label(
      indicator_summary = "Indicator",
      period_start = "From",
      period_end = "To",
      value = "Latest value",
      units = "Units"
    ) |>
    gt::cols_align(align = "left", columns = c("indicator_summary", "units")) |>
    gt::cols_align(align = "right", columns = "value") |>
    gt::cols_align(
      align = "center",
      columns = c("period_start", "period_end")
    ) |>
    gt::fmt_number(columns = "value", decimals = 1, use_seps = TRUE) |>
    gt::cols_width(indicator_summary ~ gt::px(360)) |>
    gt::tab_style(
      style = gt::cell_text(weight = "bold"),
      locations = gt::cells_body(columns = "indicator_summary")
    ) |>
    gt::tab_style(
      style = gt::cell_text(weight = "bold"),
      locations = gt::cells_column_labels()
    ) |>
    gt::tab_options(table.width = gt::pct(100))
}

# Column widths as percentages of table width. Shared by every per-priority
# sub-table so the stacked tables in the gt_group line up vertically. Percentages
# (not px) let each table fill its container exactly, avoiding gt's horizontal
# scroll container. Must sum to 100.
.overall_col_pct <- c(
  indicator_summary = 40,
  period_start = 10,
  period_end = 10,
  value = 11,
  units = 16,
  change = 13
)

#' Internal: build one per-priority gt table for the overall summary
#'
#' Renders a single priority's indicators as a self-contained gt table. The
#' priority label is carried by a full-width column spanner (styled as a green
#' band) so that every table in the group is labelled consistently. The overall
#' report title/subtitle are attached to the first table only.
#'
#' @param grp A tibble for one priority. Must contain the display columns plus
#'   `priority` (label) and `change_color`.
#' @param title Overall report title (first table only; NULL otherwise).
#' @param subtitle Overall report subtitle (first table only; NULL otherwise).
#' @return A `gt_tbl` object.
#' @keywords internal
.build_priority_gt <- function(grp, title = NULL, subtitle = NULL) {
  change_colours <- grp$change_color

  tbl_display <- grp |>
    dplyr::select(
      indicator_summary,
      period_start,
      period_end,
      value = latest_value,
      units,
      change
    )

  gt_tbl <- gt::gt(tbl_display) |>
    gt::tab_header(title = title, subtitle = subtitle) |>
    gt::tab_spanner(label = grp$priority[1], columns = gt::everything()) |>
    gt::cols_label(
      indicator_summary = "Indicator",
      period_start = "From",
      period_end = "To",
      value = "Latest value",
      units = "Units",
      change = "Change"
    ) |>
    gt::cols_align(align = "left", columns = c("indicator_summary", "units")) |>
    gt::cols_align(align = "right", columns = c("value", "change")) |>
    gt::cols_align(
      align = "center",
      columns = c("period_start", "period_end")
    ) |>
    gt::fmt_number(columns = "value", decimals = 1, use_seps = TRUE) |>
    gt::cols_width(
      indicator_summary ~ gt::pct(.overall_col_pct[["indicator_summary"]]),
      period_start ~ gt::pct(.overall_col_pct[["period_start"]]),
      period_end ~ gt::pct(.overall_col_pct[["period_end"]]),
      value ~ gt::pct(.overall_col_pct[["value"]]),
      units ~ gt::pct(.overall_col_pct[["units"]]),
      change ~ gt::pct(.overall_col_pct[["change"]])
    ) |>
    gt::tab_style(
      style = gt::cell_text(weight = "bold"),
      locations = gt::cells_body(columns = "indicator_summary")
    ) |>
    gt::tab_style(
      style = gt::cell_text(weight = "bold"),
      locations = gt::cells_column_labels()
    ) |>
    # Green priority band: fill + bold + left-align the spanner label.
    gt::tab_style(
      style = list(
        gt::cell_fill(color = "#d0e4d5"),
        gt::cell_text(weight = "bold", align = "left")
      ),
      locations = gt::cells_column_spanners()
    ) |>
    gt::tab_options(
      table.width = gt::pct(100),
      table.layout = "fixed",
      container.overflow.x = FALSE,
      container.overflow.y = FALSE,
      column_labels.border.top.width = gt::px(0)
    )

  # Per-row colours for the change column (one tab_style() per unique colour
  # avoids passing a vector to cell_text()).
  for (col in unique(change_colours)) {
    row_idx <- which(change_colours == col)
    gt_tbl <- gt_tbl |>
      gt::tab_style(
        style = gt::cell_text(color = col),
        locations = gt::cells_body(columns = "change", rows = row_idx)
      )
  }

  gt_tbl
}

#' Whole-report summary for the landing page
#'
#' One table per priority (that has FACT data), stacked with spacing via a
#' `gt_group`. Each table shows one row per indicator with the latest observed
#' value, its period, units, and a change column: percentage-point change for
#' percentage indicators (units == "%"), otherwise relative % change vs the
#' previous observation. "--" where no previous observation exists.
#'
#' Splitting into separate tables (rather than one grouped table) avoids the
#' Bootstrap `.table-striped` conflict with a green group band: striping inside
#' a single-priority table, under its own green spanner, is unambiguous.
#'
#' @param reporting_view A tibble produced by `build_reporting_view()`.
#' @param dim_tbl The core DIM data tibble (e.g. `core_dim_data_tbl`).
#' @param title Optional overall title (attached to the first table).
#' @param subtitle Optional overall subtitle (attached to the first table).
#'
#' @return A `gt_group` object.
format_overall_summary <- function(
  reporting_view,
  dim_tbl,
  title = NULL,
  subtitle = NULL
) {
  if (!is.data.frame(reporting_view)) {
    stop(
      "`reporting_view` must be a data frame produced by build_reporting_view().",
      call. = FALSE
    )
  }
  if (!is.data.frame(dim_tbl)) {
    stop(
      "`dim_tbl` must be a data frame (e.g. core_dim_data_tbl).",
      call. = FALSE
    )
  }

  required_rv <- c(
    "indicator_id",
    "latest_period_start",
    "latest_period_end",
    "latest_value",
    "previous_value",
    "pct_change"
  )
  missing_rv <- setdiff(required_rv, names(reporting_view))
  if (length(missing_rv) > 0L) {
    stop(
      "`reporting_view` is missing columns: ",
      paste(missing_rv, collapse = ", "),
      call. = FALSE
    )
  }

  dim_all <- get_dim_all(dim_tbl)

  tbl <- dplyr::inner_join(
    dim_all,
    reporting_view,
    by = dplyr::join_by(indicator_id)
  )

  check_order_within_priority(tbl)

  tbl <- tbl |>
    dplyr::mutate(
      is_percent = (units == "%"),
      change_raw = dplyr::if_else(
        is_percent,
        latest_value - previous_value,
        pct_change
      ),
      change = .fmt_change(change_raw, is_percent),
      change_color = .change_colour(change_raw, polarity),
      period_start = format(latest_period_start),
      period_end = format(latest_period_end),
      priority = paste0("Priority ", priority, ": ", priority_description)
    ) |>
    dplyr::arrange(priority, order_within_priority)

  if (nrow(tbl) == 0L) {
    stop("No indicators with FACT data found.", call. = FALSE)
  }

  # Split into one tibble per priority, preserving the arranged order.
  by_priority <- dplyr::group_split(tbl, priority)

  gt_list <- purrr::imap(
    by_priority,
    function(grp, i) {
      if (i == 1L) {
        .build_priority_gt(
          grp,
          title = title %||% "Regional Priorities: All Indicators",
          subtitle = subtitle
        )
      } else {
        .build_priority_gt(grp)
      }
    }
  )

  gt::gt_group(.list = gt_list)
}
