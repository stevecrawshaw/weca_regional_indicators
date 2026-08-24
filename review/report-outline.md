# Review Report for the Regional Indicators Project

## Executive Summary

- An MVP (Minimum Viable Product) was produced but the process is fragile due to weakly embedded skills in core technologies (R, quarto, git, cli, sql)
- The MVP created valuable foundations for repeat work including: style guide, report scaffolding, indicator definition, foundation skills and analyst responsibility for priorities
- The audience for the report is only weakly defined - "residents". Clearer definition of audience and purpose would increase utility and focus.
- The current product does not utilise many potential features of the publishing platform (Quarto) for example: interactive charts, data downloads etc.
- The scope of the report is limited. Despite being an excellent platform for in - depth reporting of the issues covered, the analysis is only at a surface level for the indicators. It is possible, and desireable to use this report to do a deeper dive into the issues, and initial comments from internal stakeholder have revealed this demand (Stewart Grey)

## Introduction

The requirement for a public facing report on regional indicators emerged from the work undertaked to define an outcomes framework for the projects in the MCA. A component of this was a set of regional indicators. These are metrics not directly influenced by MCA projects, but giving an overview of the regional measures covered by the six priorities identified in the Growth Strategy.

Discovery work was undertaken to determine an appropriate platform for presenting and publishing these regional indicators, Quarto was identified as the optimum choice as it supports literate programming, publishing in a wide range of formats and version control.

## Indicator Definition

Indicators were defined in a consultative process with the MCA's lead economist, senior analysts and the relevant business area leads. At the time they were defined, the decision to report these in a public document had not been made, hence the shape of the published indicators was not defined, even though the broad description of the metric was known.

The indicators could have been defined as a comparison with another "similar" area, for example another MCA or MSA. This is problematic in that although ONS have done some work on nearest statistical neighbours, the "nearness" of these neighbours depends on the priority or topic being compared. Also, the requirement to include North Somerset renders these ONS analyses redundant as they do not include North Somerset.

Ultimately, the indicators were defined as time series metrics, with each metric having an identifier (unique ID), period start (date), period end (date) and value. This enables a standard approach to representing summary data for indicators and for data visualisation.

### Learnings

- Define the general shape of indicators early - this will help discount or confirm candidates.
- Including North Somerset meant that many pre - computed open datasets were unavailable for use in the work, which led to bespoke analysis. This may change post inclusion.
- Some aspects of indicator definition were not properly considered at the outset, for example: polarity and unit type. These needed to be added while the work was in progress which was not ideal.

## Analysis Skills for Code - First Approach

This section covers the skills needed by analysts to contribute to the work. The quarto workflow relies on analysts being able to:

- Install and configure non standard software
- Write analysis code in R or python
- Use git and github to version control their code
- Mix code and text in a literate programming environment (quarto)
- Use command line tools (git, bash, powershell) to configure R and manage the project

For three of the analysts this was a completely new way of working. Two others had some exposure to this approach but not for such a multi - featured project as this.

Learning R (or any programming language), Quarto and command line is extremely demanding and difficult. Becoming confident in analysing data with R can take years. Analysts have done extremely well to achieve the outcomes they have.

Steve Crawshaw developed several "boiler plate" functions to reduce complexity for analysts, so that their work could focus on the business logic and domain knowledge of the priorities. the boiler plate functions help with chart formatting, publishing workflows, summary tables and security.

### Training Materials

Steve developed training materials for [R and Quarto learning](https://r-quarto-learning.vercel.app/) and scheduled weekly meetings to deliver the training. The training was based on a [pedagogy](https://r-quarto-learning.vercel.app/overview/pedagogy.html) for new learners of code - first analysis. The training ran from April to July 2026.

### Learnings

#### General

- Group sessions relied on everyone having the required development environment. This was not the case, and two analysts were delayed in being able to participate due to software and hardware issues.
- The sessions were initially planned to be 4 hour sessions. This was optimistic and in reality these were a maximum of 90 minute sessions.
- Progress was slow - anticipated. Dedicated and protected time at the beginning of the project would have embedded learning more than the approach adopted.
- Churn in the analysis team meant that the place analyst (Tom) did not arrive in the team until July so was not able to receive the training.
- Working patterns of some analysts limited participation

#### Tech - Specific

- Git and github is conceptually difficult to understand for new users. Cryptic error messages erode confidence and despite comprehensive learning material being provided, the experience of using git and github can be demoralising.
- The teaching focussed heavily on developing R scripts and analysis. This was the right emphasis to get learners to produce visible output.
- The quarto work was largely templated, meaning that analysts could essentially copy and paste code and text artefacts from an existing index.qmd.
- The learning of git used bash commands rather than a GUI approach. A GUI is available in Rstudio, but is slow, and unless learners have an appreciation of the fundamentals is not likely to improve the workflow.
- AI support - learners used AI to varying degrees to support their work. There is vigorous debate about the merits of this, but it is unlikely that an MVP could have been achieved without it in the timescale needed. The risk is that learning is not embedded, but reliance on AI is. Verifying the code written by AI is not possible unless you understand the code.
