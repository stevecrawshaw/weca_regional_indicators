# 2026 Project Review — Analyst Questionnaire

For everyone who authored a chapter: Heather (Transport), Tom (Place), Stuart (Economy),
Megan (Skills), Simon (Digital), and the child poverty chapter contributor.

Answer in as much or as little detail as useful — bullet points are fine. Free text under
each question; skip anything that doesn't apply. Responses will be attributed by name in
the review document.

**Name:**
**Chapter / indicator area:**

---

## 1. Getting started

1. How much prior experience did you have with git and Quarto before this project?
2. How long did it take you to get from "cloned the repo" to "successfully rendered my
   chapter locally"? What, if anything, slowed that down?
3. Was the chapter setup process (`_common.R`, `source(here::here(...))`, the shared
   helpers) clear, or did you need help to get going?

## 2. The FACT table contract

1. The workflow asks you to wrangle your data to exactly `period_start`, `period_end`,
   `value`, then run it through `build_fact()` / `save_fact()`. Was this contract clear
   from the documentation, or did you need it explained?
2. Did `build_fact()`'s validation (no duplicate `period_end`, dates must coerce, etc.)
   ever block you? Was the error useful when it did?
3. Did you understand what `polarity` was for and how to set it correctly for your
   indicators?

## 3. Data sourcing

1. Where did your raw data come from, and how much effort did it take to get it into a
   usable state in `data/raw/`?
2. Did you hit any gaps — indicators you wanted to include but couldn't get data for?
3. Did the Azure Blob sync process for raw data work smoothly for you?

## 4. The freeze cache and rendering

 1. Did you ever run into a situation where your chapter wouldn't re-render, or rendered
    stale content, and you weren't sure why?
 2. Did you understand *when* you needed to re-render and re-commit your `_freeze/`
    output versus when it wasn't necessary?
 3. Roughly how many times did you get stuck on a git/Quarto/rendering problem badly
    enough that you needed to ask for help?

## 5. Pace and workload

 1. Looking back over the project timeline, did your work feel evenly paced, or was it
    concentrated into a few crunch periods? If crunch, what triggered it (data
    availability, review cycles, deadline pressure, something else)?
 2. Roughly how much time (in total, rough order of magnitude is fine) did you spend on
    this across the project?
 3. Did you feel you had enough context on the overall report structure and what "good"
    looked like for a chapter, or were you working somewhat in the dark relative to the
    other chapters?

## 6. Coordination

 1. How did you find the level of communication/coordination from Steve as project
    lead — too much, too little, about right?
 2. Was it clear who to go to when you were stuck (technical vs. content questions)?

## 7. Looking forward

 1. If we run this again next year, what's the one thing that would make the biggest
    difference to your experience as a contributor?
 2. What worked well that we should definitely keep doing?
 3. Anything else you want to flag that isn't covered above?
