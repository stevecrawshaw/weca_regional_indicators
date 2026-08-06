# presentation_manifest.R
#
# Derives the revealjs slide deck from the Quarto book. Nothing in the deck is
# authored separately: a chart appears on a slide because it appears in a
# chapter, and the image shown is the one the book itself rendered.
#
# Sources of truth:
#   _quarto.yml            chapter order
#   chapters/*/index.qmd   chapter titles, section headings, chart chunks
#   index.qmd              the Priority Areas bullets used for the contents slide
#   _freeze/               the rendered chart PNGs
#
# A chart chunk is a code chunk carrying `fig-alt:`. Summary/GT chunks do not,
# which is what keeps tables out of the deck. If a chart chunk has no cached
# figure the build stops: that means _freeze/ is stale relative to the chapters.

# ---- parsing helpers --------------------------------------------------------

.read_lines_utf8 <- function(path) {
  con <- file(path, encoding = "UTF-8")
  on.exit(close(con))
  readLines(con, warn = FALSE)
}

.strip_option_prefix <- function(x) sub("^#\\|[ ]?", "", x)

#' Parse a chunk's `#|` option block as YAML.
#'
#' Round-tripping through YAML rather than regex means multi-line block scalars
#' (which is how every `fig-alt` in the book is written) parse correctly.
.parse_chunk_options <- function(opt_lines) {
  if (!length(opt_lines)) {
    return(list())
  }
  txt <- paste(.strip_option_prefix(opt_lines), collapse = "\n")
  out <- tryCatch(yaml::yaml.load(txt), error = function(e) NULL)
  if (is.list(out)) out else list()
}

.front_matter <- function(lines) {
  if (!length(lines) || !identical(trimws(lines[[1]]), "---")) {
    return(list(end = 0L, meta = list()))
  }
  close_at <- which(trimws(lines) == "---")
  close_at <- close_at[close_at > 1L]
  if (!length(close_at)) {
    return(list(end = 0L, meta = list()))
  }
  end <- close_at[[1]]
  meta <- tryCatch(
    yaml::yaml.load(paste(lines[2:(end - 1L)], collapse = "\n")),
    error = function(e) list()
  )
  list(end = end, meta = if (is.list(meta)) meta else list())
}

.squish <- function(x) trimws(gsub("[[:space:]]+", " ", x))

#' Extract chapter metadata and its chart chunks, in document order.
.parse_chapter <- function(qmd_path) {
  lines <- .read_lines_utf8(qmd_path)
  fm <- .front_matter(lines)

  heading <- NA_character_
  charts <- list()

  i <- fm$end + 1L
  n <- length(lines)
  while (i <= n) {
    ln <- lines[[i]]

    if (grepl("^```\\{", ln)) {
      # Chunk options run from the line after the fence until the first line
      # that is not a `#|` comment.
      j <- i + 1L
      opts <- character()
      while (j <= n && grepl("^#\\|", lines[[j]])) {
        opts <- c(opts, lines[[j]])
        j <- j + 1L
      }
      k <- j
      while (k <= n && !grepl("^```[[:space:]]*$", lines[[k]])) {
        k <- k + 1L
      }

      o <- .parse_chunk_options(opts)
      if (!is.null(o[["fig-alt"]]) && !is.null(o[["label"]])) {
        charts[[length(charts) + 1L]] <- tibble::tibble(
          heading = heading,
          label = as.character(o[["label"]]),
          alt = .squish(as.character(o[["fig-alt"]]))
        )
      }

      i <- k + 1L
      next
    }

    # Level-2 headings only; `### Overview` has no space in position 3.
    if (grepl("^## ", ln)) {
      heading <- trimws(sub("^##[[:space:]]+", "", ln))
    }

    i <- i + 1L
  }

  list(
    title = as.character(fm$meta$title %||% basename(dirname(qmd_path))),
    subtitle = as.character(fm$meta$subtitle %||% ""),
    charts = if (length(charts)) dplyr::bind_rows(charts) else tibble::tibble(
      heading = character(),
      label = character(),
      alt = character()
    )
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x

#' Pull the Priority Areas bullets out of the book landing page.
#'
#' Each bullet links to a chapter directory; the contents slide reuses the
#' bullet verbatim with that link retargeted at the deck's own section.
.parse_priority_bullets <- function(index_path) {
  lines <- .read_lines_utf8(index_path)
  start <- grep("^##[[:space:]]+Priority Areas[[:space:]]*$", lines)
  if (!length(start)) {
    return(tibble::tibble(bullet = character(), chapter_dir = character()))
  }
  rest <- lines[(start[[1]] + 1L):length(lines)]
  stop_at <- grep("^##[[:space:]]", rest)
  if (length(stop_at)) {
    rest <- rest[seq_len(stop_at[[1]] - 1L)]
  }

  bullets <- rest[grepl("^-[[:space:]]+", rest)]
  dirs <- sub(
    ".*\\]\\(/chapters/([^/)]+)/?\\).*",
    "\\1",
    bullets
  )
  keep <- dirs != bullets # drop any bullet without a chapter link
  tibble::tibble(
    bullet = sub("^-[[:space:]]+", "", bullets[keep]),
    chapter_dir = dirs[keep]
  )
}

# ---- manifest ---------------------------------------------------------------

#' Locate the book's root by walking up for a directory holding both
#' `_quarto.yml` and `chapters/`.
#'
#' `here::here()` is not used: the presentation is its own Quarto project, so
#' from inside it `here` can settle on the wrong root.
.repo_root <- function(start = getwd()) {
  dir <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (
      file.exists(file.path(dir, "_quarto.yml")) &&
        dir.exists(file.path(dir, "chapters"))
    ) {
      return(dir)
    }
    parent <- dirname(dir)
    if (identical(parent, dir)) {
      stop("Could not locate the book root above ", start, call. = FALSE)
    }
    dir <- parent
  }
}

#' Build the full slide manifest from the book source and freeze cache.
#'
#' @param root Project root (defaults to the book root found by walking up).
#' @return A list with `chapters`, `charts` and `contents` tibbles.
build_slide_manifest <- function(root = .repo_root()) {
  book <- yaml::read_yaml(file.path(root, "_quarto.yml"))
  chapter_paths <- Filter(
    function(p) grepl("^chapters/", p),
    unlist(book$book$chapters, use.names = FALSE)
  )

  chapters <- list()
  charts <- list()

  for (idx in seq_along(chapter_paths)) {
    rel <- chapter_paths[[idx]]
    chapter_dir <- basename(dirname(rel))
    parsed <- .parse_chapter(file.path(root, rel))

    section_id <- paste0("priority-", chapter_dir)
    freeze_dir <- file.path(
      root,
      "_freeze",
      sub("\\.qmd$", "", rel),
      "figure-html"
    )

    chapters[[idx]] <- tibble::tibble(
      order = idx,
      chapter_dir = chapter_dir,
      section_id = section_id,
      title = parsed$title,
      subtitle = parsed$subtitle
    )

    if (nrow(parsed$charts)) {
      # Glob rather than assume `-1.png`, so a chunk emitting several figures
      # still contributes one slide per figure.
      figs <- lapply(parsed$charts$label, function(lbl) {
        sort(list.files(
          freeze_dir,
          pattern = paste0("^", .escape_regex(lbl), "-[0-9]+\\.png$"),
          full.names = TRUE
        ))
      })

      missing <- parsed$charts$label[lengths(figs) == 0L]
      if (length(missing)) {
        stop(
          "No cached figure in _freeze/ for chart chunk(s) in ",
          rel,
          ": ",
          paste(missing, collapse = ", "),
          ".\nRe-render the book so its freeze cache is up to date.",
          call. = FALSE
        )
      }

      charts[[idx]] <- parsed$charts |>
        dplyr::mutate(fig_src = figs) |>
        tidyr::unnest_longer(fig_src) |>
        dplyr::mutate(
          chapter_dir = chapter_dir,
          section_id = section_id,
          fig_dest = paste0(chapter_dir, "__", basename(fig_src))
        )
    }
  }

  chapters <- dplyr::bind_rows(chapters)
  charts <- dplyr::bind_rows(charts)

  contents <- .parse_priority_bullets(file.path(root, "index.qmd")) |>
    dplyr::left_join(
      dplyr::select(chapters, chapter_dir, section_id, order),
      by = "chapter_dir"
    ) |>
    dplyr::filter(!is.na(section_id)) |>
    dplyr::arrange(order)

  list(
    title = as.character(book$book$title %||% "Regional Indicators"),
    chapters = chapters,
    charts = charts,
    contents = contents
  )
}

.escape_regex <- function(x) gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x)

# ---- rendering --------------------------------------------------------------

#' Copy the book's cached figures and the WECA logo into the deck's own
#' resource directory.
#'
#' Quarto will not carry files in from outside the presentation project, so
#' everything the deck references is copied in at render time. The directory is
#' disposable and gitignored.
copy_slide_figures <- function(manifest, dest_dir, root = .repo_root()) {
  if (dir.exists(dest_dir)) {
    unlink(list.files(dest_dir, full.names = TRUE))
  } else {
    dir.create(dest_dir, recursive = TRUE)
  }
  file.copy(
    manifest$charts$fig_src,
    file.path(dest_dir, manifest$charts$fig_dest),
    overwrite = TRUE
  )

  # Referenced by `logo:` in the deck's YAML.
  logo <- file.path(root, "weca_logo.jpg")
  if (!file.exists(logo)) {
    stop(
      "weca_logo.jpg is missing from the repository root; the deck's ",
      "`logo:` reference cannot be resolved.",
      call. = FALSE
    )
  }
  file.copy(logo, file.path(dest_dir, "weca_logo.jpg"), overwrite = TRUE)

  invisible(dest_dir)
}

.md_escape_attr <- function(x) gsub('"', "'", x, fixed = TRUE)

#' Emit the deck body as markdown.
#'
#' Level-1 headings open a vertical stack (one column per priority); the level-2
#' chart slides sit beneath their priority. Chart slide headings are kept in the
#' DOM for screen readers but hidden visually, so the plot -- which already
#' carries its own title, subtitle and source caption -- gets the full slide.
render_slides <- function(manifest, fig_dir = "figures") {
  out <- character()

  # Contents: one bullet per priority, retargeted at the deck's own sections.
  out <- c(out, "# Contents {#contents}", "")
  for (i in seq_len(nrow(manifest$contents))) {
    row <- manifest$contents[i, ]
    bullet <- sub(
      "\\]\\(/chapters/[^/)]+/?\\)",
      paste0("](#", row$section_id, ")"),
      row$bullet
    )
    out <- c(out, paste0("- ", bullet))
  }
  out <- c(out, "")

  for (i in seq_len(nrow(manifest$chapters))) {
    ch <- manifest$chapters[i, ]
    out <- c(
      out,
      paste0("# ", ch$title, " {#", ch$section_id, "}"),
      ""
    )
    if (nzchar(ch$subtitle)) {
      out <- c(out, ch$subtitle, "")
    }

    slides <- manifest$charts |>
      dplyr::filter(section_id == ch$section_id)

    for (j in seq_len(nrow(slides))) {
      sl <- slides[j, ]
      heading <- if (is.na(sl$heading)) ch$title else sl$heading
      out <- c(
        out,
        paste0("## ", heading, " {.chart-slide}"),
        "",
        paste0(
          "![](",
          file.path(fig_dir, sl$fig_dest),
          '){fig-alt="',
          .md_escape_attr(sl$alt),
          '" fig-align="center"}'
        ),
        "",
        "::: {.notes}",
        paste0(heading, " -- ", sl$alt),
        ":::",
        ""
      )
    }
  }

  out
}
