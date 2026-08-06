# West of England Priority Indicators: Collaborative Quarto Report

This repository contains the source code and data for the integrated West of England regional report. This is a polyglot project using **R** and **Python**, managed via **Quarto**.

## 🚀 Quick Start

**New to this project?** Start here:

- **[Getting Started Guide](GETTING_STARTED.md)** - First-time setup, installation, and your first indicator
- **[Contributing Guide](CONTRIBUTING.md)** - Git workflow, code standards, and peer review process
- **[QA Checklist](QA_CHECKLIST.md)** - Quality assurance standards before submitting work

## 📊 Project Overview

The goal of this project is to produce a single, cohesive report where each analyst contributes analysis for a chapter based on their specific priority area.

**Published report:** [https://westofengland-ca.github.io/weca_regional_indicators/](https://westofengland-ca.github.io/weca_regional_indicators/)

## 📂 Repository Structure

We use a modular structure. Each chapter has its own directory to prevent file conflicts.

- `index.qmd`: The report landing page/executive summary.
- `_quarto.yml`: Global configuration (Chapter order, themes, and execution settings).
- `data/`: Shared data assets (Raw and Processed).
- `scripts/`: Shared utility scripts (Python/R functions used across chapters).
- **Chapters** (under `chapters/`):
  - `chapters/01-economy/`: Contributing to national economic growth (SN)
  - `chapters/02-transport/`: Connecting the region through better public transport (HB)
  - `chapters/03-place/`: Creating and building affordable/sustainable homes (CJ)
  - `chapters/04-skills/`: Empowering residents with future-ready skills (MJ)
  - `chapters/05-environment/`: Making the West of England the home for green jobs (SC)
  - `chapters/06-child-poverty/`: Lifting children and families out of poverty (MJ)

## 🛠 Tech Stack

- **IDE:** Positron
- **Python Management:** `uv` (using `pyproject.toml`)
- **R Management:** `renv`
- **Rendering:** Quarto

## 🚀 Deployment

Every push to `main` runs `.github/workflows/publish.yml`, which renders the book and the presentation deck, then publishes the result to GitHub Pages via a `build` job (renders, then packages `_output/` as a Pages artefact) and a separate `deploy` job (`actions/deploy-pages`). Pages is configured under Settings → Pages → Source: **GitHub Actions** — there's no `gh-pages` branch to push to or watch anymore.

## 📚 Learning Resources

### R for Excel Users

- **[R for Excel Users (Online Course)](https://rstudio-conf-2020.github.io/r-for-excel/)** - Transition from Excel to R with practical examples
- **[R for Data Science (2e)](https://r4ds.hadley.nz/)** - Comprehensive guide to modern R workflows

### Quarto Documentation

- **[Quarto Official Documentation](https://quarto.org/)** - Complete reference for Quarto features
- **[Quarto Books Guide](https://quarto.org/docs/books/)** - How to structure multi-chapter reports
- **[Quarto with R](https://quarto.org/docs/computations/r.html)** - R-specific execution and output
- **[Quarto with Python](https://quarto.org/docs/computations/python.html)** - Python-specific execution and output

### Git and Version Control

- **[GitHub Desktop Tutorial](https://docs.github.com/en/desktop)** - GUI-based Git workflow (beginner-friendly)
- **[Git Bash Essentials](https://www.atlassian.com/git/tutorials)** - Command-line Git fundamentals
- **[Happy Git with R](https://happygitwithr.com/)** - Git workflows specifically for R users

### Reproducible Analytical Pipelines (RAP)

- **[Government Analysis Function: RAP](https://analysisfunction.civilservice.gov.uk/support/reproducible-analytical-pipelines/)** - UK government best practises
- **[The Turing Way](https://the-turing-way.netlify.app/)** - Handbook for reproducible research
- **[RAP Companion](https://ukgovdatascience.github.io/rap_companion/)** - Practical guide to implementing RAP

### Data Visualisation

- **[ggplot2 Reference](https://ggplot2.tidyverse.org/)** - Grammar of graphics for R
- **[Data-to-Viz](https://www.data-to-viz.com/)** - Choosing the right chart type
- **[Accessibility Guidelines](https://www.gov.uk/guidance/content-design/data-and-analytics)** - Making charts accessible

## 🔧 Setup and Installation

See **[GETTING_STARTED.md](GETTING_STARTED.md)** for detailed setup instructions including:

- Prerequisites (Quarto, R, Python, Git)
- Environment configuration
- Pre-commit hook installation
- Rendering your first chapter

## 🤝 Contributing

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for:

- Git workflow and branch naming conventions
- Commit message standards
- Pull request process
- Code style guide (R vs Python)
- Peer review checklist
