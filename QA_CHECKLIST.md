# Quality Assurance Checklist

Use this checklist to review indicators before they are published. This ensures consistency, accuracy, and accessibility across all chapters.

---

## 📋 How to Use This Checklist

**For Authors:**

- [ ] Complete this checklist before submitting a pull request
- [ ] Self-review your work against each criterion
- [ ] Fix any issues before requesting peer review

**For Reviewers:**

- [ ] Use this checklist when reviewing pull requests
- [ ] Comment on specific issues found
- [ ] Approve only when all criteria are met

---

## 1️⃣ Code Execution

### ✅ Code Runs Without Errors

- [ ] **Chapter renders successfully**

  ```bash
  quarto render chapters/XX-topic/index.qmd
  ```

  No errors or fatal warnings during rendering

- [ ] **All code chunks execute**
  - No "object not found" errors
  - No missing package errors
  - No syntax errors

- [ ] **Dependencies are available**
  - All required R packages listed in `renv.lock` (after `renv::snapshot()`)
  - All required Python packages listed in `pyproject.toml`
  - No hardcoded package installations in code chunks

- [ ] **Execution is reproducible**
  - Running the code twice produces identical results
  - No randomness without set seed
  - No reliance on local-only files

---

## 2️⃣ Data Documentation

### ✅ Data Sources Are Documented

- [ ] **Source organization identified**
  - ONS, DfT, local authority, etc.
  - Official name spelled correctly

- [ ] **Source URL or reference provided**
  - Link to dataset (if publicly available)
  - Or citation to report/publication

- [ ] **Download/access date recorded**
  - Format: YYYY-MM-DD or "January 2024"
  - Helps identify data vintage

- [ ] **Geographic coverage stated**
  - "West of England Combined Authority"
  - Or specific local authorities listed

- [ ] **Time period specified**
  - E.g., "2015-2024 (annual)"
  - Frequency noted (annual, quarterly, monthly)

### ✅ Data Quality Noted

- [ ] **Sample size or coverage adequate**
  - Large enough for meaningful analysis
  - Representativeness considered

- [ ] **Limitations acknowledged**
  - Known data gaps or quality issues
  - Breaks in time series noted
  - Impact of events (e.g., COVID-19 on 2020-2021 data)

- [ ] **Data transformations documented**
  - Any filtering, aggregation, or calculations explained
  - Processing steps could be replicated

---

## 3️⃣ Calculations & Analysis

### ✅ Calculations Are Correct

- [ ] **Formulas verified**
  - Spot-check calculations manually
  - Test edge cases (divide by zero, missing values)

- [ ] **Units are correct**
  - Percentages vs. proportions (0.15 vs. 15%)
  - Millions, thousands, absolute numbers
  - Currency (£, nominal vs. real terms)

- [ ] **Comparisons are valid**
  - Like-for-like comparisons (same definitions, geographies)
  - Time series use consistent methodology
  - National benchmarks are appropriate

### ✅ Methodology Is Clear

- [ ] **Analysis approach explained**
  - Why this method was chosen
  - Key assumptions stated

- [ ] **Statistical methods appropriate**
  - Correct tests for data type
  - Assumptions checked (normality, independence, etc.)

- [ ] **Uncertainty quantified (where applicable)**
  - Confidence intervals for estimates
  - Margins of error for surveys
  - Caveats for small samples

---

## 4️⃣ Visualizations

### ✅ Charts Are Well-Designed

- [ ] **Chart type suits the data**
  - Line charts for trends over time
  - Bar charts for comparisons
  - Maps for geographic patterns
  - Not misleading (e.g., broken axes justified)

- [ ] **Axes are labeled**
  - X-axis label (e.g., "Year")
  - Y-axis label with units (e.g., "Employment Rate (%)")
  - Labels are legible

- [ ] **Y-axis baseline is appropriate**
  - Bar charts (`geom_col`/`geom_bar`) **must start at zero** — truncating the axis misrepresents magnitudes. Anchor with `scale_y_continuous(expand = expansion(mult = c(0, 0.05)))`; if year-on-year movement is then too small to see, switch to a line chart instead of truncating
  - Line charts may start above zero where forcing zero would flatten all variation, but the truncation must be obvious from the axis labels
  - **Never hard-code limits** (e.g., `limits = c(60, 70)`) — data outside the range is silently dropped. Derive limits from the data (e.g., `floor(min(value) / interval) * interval`) or use `expand = expansion(...)`
  - Prefer `coord_cartesian(ylim = ...)` over `scale_y_continuous(limits = ...)` when zooming — `limits` filters out data before drawing, `coord_cartesian` only crops the view
  - Index/change-from-baseline charts anchor at the reference value (0 or 100), with room for negative values where the data can go there

- [ ] **Title is descriptive**
  - Explains what the chart shows
  - E.g., "Bus Ridership Trends in the West of England, 2015-2024"

- [ ] **Data source cited**
  - Caption includes source: "Source: Department for Transport"
  - Or footnote if multiple sources

- [ ] **Legend is clear (if needed)**
  - Colors/lines explained
  - Not cluttered (max 6-7 categories)

### ✅ WECA Branding Applied

- [ ] **Uses WECA color palette**
  - `theme_weca()` applied (R)
  - Or WECA colors used consistently (Python)

- [ ] **Fonts are readable**
  - Open Sans (body), Trebuchet (headings)
  - Minimum 9pt font size

- [ ] **Professional appearance**
  - Clean layout
  - No unnecessary gridlines
  - Appropriate white space

---

## 5️⃣ Accessibility

### ✅ Content Is Accessible

- [ ] **Alt text provided for all figures**

  ```r
  #| fig-cap: "Annual bus ridership showing 15% increase from 2015-2024"
  ```

  Describes what the chart shows, not just what it is

- [ ] **Color choices are colorblind-friendly**
  - Avoid red-green combinations alone
  - Use patterns or labels in addition to color
  - Test with colorblind simulator (e.g., [Coblis](https://www.color-blindness.com/coblis-color-blindness-simulator/))

- [ ] **Text contrast is sufficient**
  - Text on background meets WCAG AA standard (4.5:1 ratio)
  - Check with [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

- [ ] **Charts work in grayscale**
  - Print preview or desaturate to check
  - Lines distinguishable by style (solid, dashed, dotted)

### ✅ Language Is Clear

- [ ] **Plain English used**
  - Technical terms defined on first use
  - Acronyms spelled out: "Office for National Statistics (ONS)"
  - Sentences are concise

- [ ] **Headings follow logical hierarchy**
  - `##` for main sections
  - `###` for subsections
  - No skipping levels (no `####` without `###`)

- [ ] **Tables are formatted clearly**
  - Column headers are descriptive
  - Numbers aligned right, text aligned left
  - Units in header (not repeated in every cell)

---

## 6️⃣ Code Quality

### ✅ Code Is Readable

- [ ] **No hardcoded file paths**
  - Uses relative paths from project root (R) or `pathlib.Path` (Python)
  - No `C:/Users/username/...`

- [ ] **Code is commented**
  - Complex logic explained
  - Why, not just what
  - E.g., `# Filter to 2020+ to exclude COVID-impacted baseline`

- [ ] **Variable names are descriptive**
  - `employment_rate` not `x`
  - `bus_ridership_data` not `df1`

- [ ] **Code chunks have labels**

  ```r
  #| label: load-employment-data
  ```

  Helps with debugging and cross-references

### ✅ Code Follows Style Guidelines

**R:**

- [ ] Uses `<-` for assignment (not `=`)
- [ ] snake_case for variables and functions
- [ ] Packages loaded at top of chunk

**Python:**

- [ ] Follows PEP 8 (check with `ruff`)
- [ ] Type hints where helpful
- [ ] Imports at top of chunk

**Both:**

- [ ] No commented-out code (remove or explain why kept)
- [ ] Consistent indentation (2 spaces for R, 4 for Python)

---

## 7️⃣ Narrative & Context

### ✅ Indicator Is Well-Explained

- [ ] **Introduction provides context**
  - Why this indicator matters
  - What it measures
  - Link to regional priority

- [ ] **Key findings highlighted**
  - 3-5 main takeaways
  - Trends, comparisons, notable patterns
  - Written for non-technical audience

- [ ] **Interpretation is balanced**
  - Acknowledges limitations
  - Avoids overstating findings
  - Notes where causality vs. correlation

- [ ] **Recommendations or implications (where appropriate)**
  - What the findings suggest
  - Areas for further investigation

---

## 8️⃣ Reproducibility

### ✅ Work Can Be Reproduced

- [ ] **All data files are accessible**
  - In `data/raw/` or `data/processed/`
  - Or documented where team can access (shared drive, Databricks)

- [ ] **Processing scripts are available**
  - If data was transformed, script is in `scripts/`
  - Script has comments explaining steps

- [ ] **Package versions are recorded**
  - R: `renv::snapshot()` run after adding packages
  - Python: packages listed in `pyproject.toml`

- [ ] **Randomness is controlled**
  - `set.seed()` used if analysis involves random sampling
  - Seed value documented

---

## 9️⃣ Security & Privacy

### ✅ No Sensitive Data

- [ ] **No personal identifiable information (PII)**
  - No names, addresses, contact details
  - No individual-level data (aggregated only)

- [ ] **No credentials or secrets**
  - No API keys, passwords, tokens in code
  - Pre-commit hook passes (no secrets detected)

- [ ] **Data license permits use**
  - Public data or licensed for this purpose
  - Attribution requirements met

- [ ] **Data is appropriately anonymized**
  - Cell suppression applied (e.g., counts <5)
  - No re-identification risk

---

## 🔟 Publication Readiness

### ✅ Final Polish

- [ ] **Spelling and grammar checked**
  - No typos in narrative text
  - Consistent terminology (e.g., "West of England" not "WoE")

- [ ] **Numbers formatted consistently**
  - Thousands separator: 1,234 or 1 234
  - Decimal places appropriate (e.g., 72.3% not 72.29384%)
  - Currency: £1,234.56

- [ ] **References to other chapters work**
  - Internal links formatted correctly
  - Cross-references resolve

- [ ] **Chapter integrates with book**
  - Sidebar navigation shows chapter
  - Chapter appears in correct section
  - Consistent style with other chapters

---

## ✅ Sign-Off

**Author Self-Review:**

- [ ] I have reviewed my work against this checklist
- [ ] All criteria are met or exceptions documented
- [ ] Ready for peer review

**Author name:** _______________
**Date:** _______________

---

**Peer Reviewer:**

- [ ] I have reviewed this work against the checklist
- [ ] All critical issues resolved
- [ ] Approved for merge

**Reviewer name:** _______________
**Date:** _______________

---

## 📝 Notes & Exceptions

Use this space to document:

- Any checklist items not applicable
- Exceptions or special circumstances
- Outstanding issues to address in future updates

---

## 🔗 Related Resources

- **Accessibility:** [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- **Data visualization:** [Government Analysis Function Chart Guidance](https://analysisfunction.civilservice.gov.uk/policy-store/data-visualisation-charts/) — includes the official position on axis baselines (bar charts must include zero)
- **Plain English:** [GOV.UK Content Design](https://www.gov.uk/guidance/content-design/writing-for-gov-uk)
- **Reproducible analysis:** [The Turing Way](https://the-turing-way.netlify.app/reproducible-research/reproducible-research.html)

---

**Questions about quality standards?** Ask in the Analysts Team Chat or discuss with your peer reviewer.
