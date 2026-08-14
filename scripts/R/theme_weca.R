# WECA Branding Theme for ggplot2
#
# This file provides WECA-branded styling for data visualisations.
# Usage: Add `+ theme_weca()` to your ggplot2 charts
#
# Example:
#   library(ggplot2)
#   source(here::here("scripts", "R", "theme_weca.R"))
#
#   ggplot(data, aes(x = year, y = value, colour = category)) +
#     geom_line() +
#     scale_colour_weca() +
#     theme_weca() +
#     labs(title = "My Indicator")

library(ggplot2)

# Register fonts for Windows graphics device
if (.Platform$OS.type == "windows") {
  windowsFonts(
    Arial = windowsFont("Arial"),
    `Trebuchet MS` = windowsFont("Trebuchet MS")
  )
}

# WECA Colour Palette (from _brand.yml)
# These colours align with WECA's official brand guidelines
weca_colors <- c(
  forest_green = "#1D4F2B",
  claret = "#CE132D",
  rich_purple = "#590075",
  black = "#1F1F1F",
  west_green = "#40A832", # Extended palette
  park_green = "#007D00",
  soft_green = "#8FCC87",
  soft_purple = "#9C66AB",
  soft_claret = "#ED8073"
)

ua_colors_by_name <-
  c(
    "Bristol" = "#CE132D",
    "South Gloucestershire" = "#1D4F2B",
    "Bath and North East Somerset" = "#590075",
    "North Somerset" = "#ED8073"
  )

# Default geometry sizing, applied by theme_weca() (and so theme_ua()) via
# ggplot2's `geom` theme element. Setting them here means indicator scripts do
# not set `linewidth` in geom_line() or `size` in geom_point() - the chart picks
# them up from the theme, so every line chart in the report matches.
# Override locally only when a chart deliberately deviates (e.g. a lightweight
# reference line).
weca_linewidth <- 1
weca_pointsize <- 2.5

ua_colors_by_code <-
  c(
    "E06000023" = "#CE132D",
    "E06000025" = "#1D4F2B",
    "E06000022" = "#590075",
    "E06000024" = "#ED8073"
  )


# Named palette for easy access
weca_palette <- function() {
  weca_colors
}

#' WECA ggplot2 Theme
#'
#' A clean, accessible theme aligned with WECA branding.
#' Uses Open Sans font and WECA brand colors.
#'
#' Also sets report-wide geometry defaults, so line charts do not need to
#' specify `linewidth` in `geom_line()` or `size` in `geom_point()` - see
#' `weca_linewidth` / `weca_pointsize` above.
#'
#' @param base_size Base font size (default: 11)
#' @param base_family Base font family (default: "Open Sans")
#'
#' @return A ggplot2 theme object
#'
#' @examples
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   theme_weca()
#'
#' @export
theme_weca <- function(base_size = 11, base_family = "Arial") {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      # Text elements
      plot.title = element_text(
        family = "Trebuchet MS", # Use full Windows font name
        size = rel(1.3),
        face = "bold",
        colour = weca_colors["forest_green"],
        margin = margin(0, 0, 10, 0)
      ),
      plot.subtitle = element_text(
        size = rel(1.1),
        colour = weca_colors["black"],
        margin = margin(0, 0, 10, 0)
      ),
      plot.caption = element_text(
        size = rel(0.9),
        colour = weca_colors["black"],
        hjust = 0,
        margin = margin(10, 0, 0, 0)
      ),

      # Axis elements
      axis.title = element_text(
        colour = weca_colors["black"],
        size = rel(1)
      ),
      axis.text = element_text(
        colour = weca_colors["black"],
        size = rel(0.9)
      ),
      axis.line = element_line(colour = weca_colors["black"], linewidth = 0.5),
      axis.ticks = element_line(colour = weca_colors["black"], linewidth = 0.5),

      # Panel elements
      panel.grid.major = element_line(colour = "grey90", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      panel.background = element_rect(fill = "white", colour = NA),

      # Legend
      legend.position = "bottom",
      legend.title = element_text(
        colour = weca_colors["black"],
        size = rel(1),
        face = "bold"
      ),
      legend.text = element_text(
        colour = weca_colors["black"],
        size = rel(0.9)
      ),
      legend.background = element_rect(fill = "white", colour = NA),
      legend.key = element_rect(fill = "white", colour = NA),

      # Plot background
      plot.background = element_rect(fill = "white", colour = NA),
      plot.margin = margin(10, 10, 10, 10),

      # Geometry defaults (ggplot2 >= 3.6): geom_line()/geom_path() inherit
      # `linewidth`, geom_point() inherits `size`. Explicit arguments in a
      # layer still win.
      geom = element_geom(
        linewidth = weca_linewidth,
        pointsize = weca_pointsize
      )
    )
}

#' WECA Discrete Color Scale
#'
#' Applies WECA brand colors to categorical data.
#'
#' @param ... Additional arguments passed to scale_colour_manual()
#'
#' @return A ggplot2 scale object
#'
#' @examples
#' ggplot(iris, aes(Sepal.Length, Sepal.Width, colour = Species)) +
#'   geom_point() +
#'   scale_colour_weca()
#'
#' @export
scale_colour_weca <- function(...) {
  ggplot2::scale_colour_manual(
    values = weca_colors,
    ...
  )
}

#' WECA Discrete Fill Scale
#'
#' Applies WECA brand colors to filled areas (bars, polygons, etc.).
#'
#' @param ... Additional arguments passed to scale_fill_manual()
#'
#' @return A ggplot2 scale object
#'
#' @examples
#' ggplot(mtcars, aes(factor(cyl), fill = factor(gear))) +
#'   geom_bar() +
#'   scale_fill_weca()
#'
#' @export
scale_fill_weca <- function(...) {
  ggplot2::scale_fill_manual(
    values = weca_colors,
    ...
  )
}

#' Get a Specific WECA Color
#'
#' Helper function to retrieve a specific WECA brand color by name.
#'
#' @param color_name Name of the color (e.g., "forest_green", "claret")
#'
#' @return Hex color code
#'
#' @examples
#' get_weca_color("forest_green") # Returns "#1D4F2B"
#'
#' @export
get_weca_color <- function(color_name) {
  if (!color_name %in% names(weca_colors)) {
    stop(paste0(
      "Color '",
      color_name,
      "' not found. ",
      "Available colors: ",
      paste(names(weca_colors), collapse = ", ")
    ))
  }
  weca_colors[[color_name]]
}

#' Display WECA Color Palette
#'
#' Visualizes all available WECA brand colors.
#' Useful for selecting colors for custom visualizations.
#'
#' @return A ggplot2 object showing the color palette
#'
#' @examples
#' show_weca_palette()
#'
#' @export
#' WECA Unitary Authority Theme
#'
#' Extends theme_weca() with a compact legend suited to charts that use
#' the four West of England unitary authority names as category labels.
#' Long names such as "Bath and North East Somerset" and "South
#' Gloucestershire" are displayed in a single vertical column so they
#' are never clipped.
#'
#' @param base_size Base font size (default: 11)
#' @param base_family Base font family (default: "Arial")
#'
#' @return A ggplot2 theme object
#'
#' @examples
#' ggplot(df, aes(x = year, y = value, fill = local_authority)) +
#'   geom_col() +
#'   scale_fill_manual(values = ua_colors_by_name) +
#'   theme_ua()
#'
#' @export
theme_ua <- function(base_size = 11, base_family = "Arial") {
  theme_weca(base_size = base_size, base_family = base_family) +
    theme(
      legend.position = "bottom",
      legend.direction = "vertical",
      legend.text = element_text(
        colour = weca_colors["black"],
        size = rel(0.85)
      ),
      legend.title = element_text(
        colour = weca_colors["black"],
        size = rel(0.9),
        face = "bold"
      ),
      legend.key.size = unit(0.4, "cm"),
      legend.spacing.y = unit(0.15, "cm"),
      legend.margin = margin(4, 0, 0, 0)
    )
}

show_weca_palette <- function() {
  palette_df <- data.frame(
    color = names(weca_colors),
    hex = unname(weca_colors),
    y = 1
  )

  ggplot(palette_df, aes(x = color, y = y, fill = color)) +
    geom_tile(width = 0.9, height = 0.8) +
    geom_text(
      aes(label = hex),
      colour = "white",
      fontface = "bold",
      vjust = 2
    ) +
    geom_text(
      aes(label = color),
      colour = "white",
      fontface = "bold",
      vjust = -1
    ) +
    scale_fill_manual(values = weca_colors) +
    theme_void() +
    theme(legend.position = "none") +
    coord_flip() +
    labs(title = "WECA Brand Color Palette")
}
