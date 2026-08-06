# The slide deck

`presentation/` produces a revealjs deck containing every chart in the book, one chart per slide. It is **derived from the book**, not maintained beside it: no chart, title or caption is written twice.

## Rendering it

```bash
cd presentation
quarto render
```

Open `presentation/_output/index.html`.

The deck reads the chart images the book has already cached in `_freeze/`, so it needs no raw data, no database and no Azure sync — a fresh clone can render it. It does need R with the project's `renv` library.

**Render the book first if you have changed a chapter.** The deck shows what is in `_freeze/`, so a chapter edit only reaches the deck once the book has re-rendered and refreshed that cache. If a chart has no cached figure the render stops:

```
No cached figure in _freeze/ for chart chunk(s) in chapters/03-place/index.qmd: RI_3C2_plot.
Re-render the book so its freeze cache is up to date.
```

That error means the freeze cache is stale, not that the deck is broken.

## Adding a chart to the deck

Nothing in `presentation/` needs editing. Add the chart to its chapter as normal, giving the chunk a label and `fig-alt`:

````markdown
```{r}
#| label: RI_5F2_hedgerow_length_plot
#| fig-alt: |
#|   Line chart of total hedgerow length in kilometres across the West of
#|   England, 2015 to 2024. The line rises gently throughout.
RI_5F2_plot
```
````

Re-render the book, then the deck. The chart becomes a slide in the position it occupies in the chapter.

**The rule: a chart chunk is any chunk carrying `fig-alt:`.** Summary tables, KPI blocks and setup chunks do not carry one, which is what keeps them out of the deck. Two charts under one indicator are two chunks, so they get a slide each — as the apprenticeships, greenhouse gas and life expectancy indicators already do.

The practical consequence is that **a chart without `fig-alt` is invisible to the deck**. That is the same alt text the published book needs for accessibility, so the two requirements pull in the same direction.

## Where each part of a slide comes from

| Deck element | Derived from |
| --- | --- |
| Priority order | the chapter list in `_quarto.yml` |
| Priority divider slide | the chapter's YAML `title` and `subtitle` |
| Contents slide bullets | the `## Priority Areas` list in the book's `index.qmd`, with each chapter link retargeted at the matching deck section |
| Which charts appear, and in what order | chart chunks in `chapters/*/index.qmd`, in document order |
| The chart image | the PNG the book cached at `_freeze/chapters/{chapter}/index/figure-html/{label}-1.png` |
| Slide heading | the `##` heading the chart sits under |
| Image alt text and speaker notes | the chunk's `fig-alt` |
| Chart title, subtitle, axis labels, source | the ggplot itself — the deck adds nothing |

Because the contents bullets are lifted from `index.qmd`, editing a priority's wording there updates the book and the deck together. Only bullets inside `## Priority Areas` are read, so other content on that page is safe to change.

## How it is put together

Three files, plus one helper script:

| File | Role |
| --- | --- |
| `scripts/R/presentation_manifest.R` | All the logic: parses the book, resolves cached figures, emits slide markdown |
| `presentation/index.qmd` | Deck metadata and a single `output: asis` chunk — it holds no slide content |
| `presentation/_quarto.yml` | Project settings |
| `presentation/weca-reveal.scss` | Brand styling |

`presentation/index.qmd` is deliberately tiny:

```r
root <- normalizePath("..", winslash = "/")
source(file.path(root, "scripts", "R", "presentation_manifest.R"))

manifest <- build_slide_manifest(root)
copy_slide_figures(manifest, "figures", root)
cat(render_slides(manifest), sep = "\n")
```

`build_slide_manifest()` returns the chapters, charts and contents bullets. `copy_slide_figures()` copies the cached PNGs and the WECA logo into `presentation/figures/` — Quarto will not pull resources in from outside the presentation project, so everything the deck references has to be inside it. `render_slides()` returns the deck as markdown, which the chunk prints for Quarto to render.

No `.qmd` is generated and committed, so there is no generated file to fall out of step with the book.

### Slide structure

Level-1 headings open one vertical stack per priority; the chart slides are level-2 within their stack. That gives a 2D grid — priorities across, charts down — which drives the slide overview (`o` key) and produces stable deep links such as `#/priority-05-environment`.

`navigation-mode: linear` means left/right and space step through all 61 slides in reading order regardless. The grid is there for navigation and linking; nobody has to know to press down.

Chart slides keep their `##` heading in the DOM for screen readers and the overview, but hide it visually (`.chart-slide` in `weca-reveal.scss`). Every plot already renders its own title, subtitle and source caption, so a visible slide heading would repeat it and cost a third of the slide.

### Branding

`weca-reveal.scss` mirrors the book's `custom.scss` — Trebuchet MS headings, Open Sans body, forest green `#1D4F2B` primary — so the deck and the book share one identity. The charts arrive already styled by `theme_weca()`.

`weca_logo.jpg` sits bottom-right on every slide, sized on width because the mark is wordmark-only and wide. The render fails with a clear message if the logo file is missing from the repository root.

## Publishing

`.github/workflows/publish.yml` runs three steps in this order:

1. `quarto render` — the book, into `_output/`
2. `quarto render` in `presentation/` — the deck, into `presentation/_output/`
3. `cp -r presentation/_output _output/presentation`

then publishes with `render: false` so the second render survives. The order matters: the deck reads the freeze cache the book render refreshes.

The book's landing page links to the deck at `presentation/index.html`. That resolves on the published site; locally the deck is at `presentation/_output/index.html`.

## Things worth knowing

**`_freeze/` holds stale orphans.** Figure PNGs from chunks that have since been renamed or deleted stay in the cache until Quarto cleans them. That is why the deck is built by parsing the chapter `.qmd` files rather than by listing the freeze directory — orphaned PNGs are never picked up.

**The deck is never frozen** (`freeze: false` in `presentation/_quarto.yml`). It must re-read the book's cache on every render, so caching it would defeat the point.

**Charts are raster images at the book's figure size** (1344×960, i.e. 7×5 inches at 192 dpi). They scale to about 860 px wide on a 1050×700 slide, which is comfortable. If a chart looks weak at slide scale, change its `fig-width`/`fig-height` in the chapter — that improves the book and the deck together.

**The deck's `title`, `subtitle` and `date` in `presentation/index.qmd` are the only hardcoded strings.** They are the deck's own metadata rather than book content.

URL: <https://westofengland-ca.github.io/weca_regional_indicators/presentation/>

That follows from the book being at <https://westofengland-ca.github.io/weca_regional_indicators/> and the deck landing in _output/presentation/, which becomes presentation/ on the site. The landing page's "slide deck" link points there.

How it gets there, on every push to main:

1. quarto render — book into _output/
2. quarto render in presentation/ — deck into presentation/_output/
3. cp -r presentation/_output _output/presentation
4. actions/upload-pages-artifact packages _output/, then a separate deploy job runs actions/deploy-pages to publish it — GitHub Pages is configured as an Actions-based deployment (Settings → Pages → Source: "GitHub Actions"), not the legacy "Deploy from a branch" / gh-pages build

The gh-pages branch is no longer written to or used — it's left dormant from the pre-migration setup.
