# Chapter 05: Green Jobs and Growth

**Lead analyst:** SC  
**Priority:** Making the West of England the home for green jobs and growth

---

## Indicators

| ID | Name | Status | Data source | Refresh |
|----|------|--------|-------------|---------|
| RI_5_ghg_emissions | Greenhouse Gas Emissions | Live | DESNZ LSOA-level emissions | Annual |
| RI_5A1_renewable | Renewable Energy Capacity | Live | Renewable Energy Planning Database | Annual |
| RI_5B1_nondom_epc_a | Non-domestic EPC A ratings | Live | DLUHC EPC register | Quarterly |
| RI_5E1_heat_stress_deaths | Heat Stress Deaths | Live | ONS / UKHSA | Annual |
| RI_5E2_flood_warning_index | Flood Warning Index | Live | Environment Agency | As published |

---

## Data Sources

| Source | URL / Location | Licence | Notes |
|--------|----------------|---------|-------|
| DESNZ local emissions | DESNZ LSOA emissions tables | OGL | Kt CO2e by sector |
| Renewable Energy Planning DB | BEIS/DESNZ REPD | OGL | Capacity in MW |
| DLUHC EPC register | DLUHC Open Data | OGL | Non-domestic certificates |
| ONS / UKHSA heat mortality | ONS health data | OGL | Age-standardised rates |
| EA Flood Warnings | Environment Agency API | OGL | Warning counts by area |

---

## Known Gaps and Caveats

- GHG emissions data has a ~2 year lag
- EPC data excludes properties not yet assessed
- Flood warning index is a proxy; does not reflect actual flood events

---

## Technical Dependencies

- R packages beyond `tidyverse`: `gt`, `here`
- Python: none

---

## Refresh Process

1. Re-run the relevant indicator script in `scripts/R/05-environment/`
2. Fact table is written to `data/fact/` (committed)
3. Re-render chapter: `quarto render chapters/05-environment/index.qmd`
4. Commit updated freeze files and `data/fact/` outputs
