# issues

1. build check so that period start < period_end in build_fact()
2. Include chapter level indicator summary tables like in chapters/05-environment/index.qmd:

   # | label: priority_summary

   # | eval: true

   # | code-summary: "Priority 5 indicator summary table"

    format_priority_summary(
      indicator_fact_tbl,
      core_dim_data_tbl,
      priority = 5,
      title = "Green Jobs and Growth: Indicator Summary"
    )

    **done**

3. re - order indicators per chapter in the same order as they appear in the summary tables. This needs to be manual. So check that analysts are happy before we commit
**done**

4. Move the employment indicator from skills to economy - **done**
5. Implement geom_point() for all line charts with a standard size
**done**
6. Check style guide is adhered to
7. remove references to chapters - replace with summaries
**done**
8. check labelling as per requirements in index qmds as well as what is imported from indicators_master.xlsx
