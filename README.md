<p align="center">

<a href="README.md">US <b>English</b></a> |
<a href="README_AR.md">AR العربية</a>

</p>

---

# Iraq: Wealth Without Welfare
### An SQL Analysis of Oil Revenue, Corruption, and Service Delivery Collapse (2012–2021)
### By: Sajjad Alnuaimi

---

## Introduction

Iraq is one of the most oil-rich countries in the world. For years following the 2003 invasion, oil rents accounted for over 40–60% of its GDP. Yet basic services like clean water, reliable electricity, and healthcare remained critically underdeveloped. As an Iraqi, this contradiction is not abstract to me. This project uses SQL to investigate the relationship between oil revenue, corruption, and service delivery outcomes in Iraq, asking a simple but loaded question: **Where did the money go?**

<img width="943" height="490" alt="corruption-iraq" src="https://github.com/user-attachments/assets/66bc4998-d869-4365-a076-f0a98b61e69c" />

## Background

The "resource curse" is a well-documented phenomenon in political economy, the paradox where nations rich in natural resources often experience weaker governance, slower development, and higher corruption than resource-poor peers. Iraq after 2003 is one of the most striking modern examples. Oil revenues flooded state budgets while public infrastructure crumbled, culminating in mass civil unrest in 2019 as citizens demanded electricity, water, and basic dignity.

This project was built to go beyond the headlines and interrogate the data directly. By connecting oil revenue flows, corruption perception scores, and service delivery indicators across a decade, the analysis reveals a consistent pattern: resource wealth and governance quality in Iraq move independently of each other and ordinary Iraqis pay the price.

<img width="943" height="490" alt="oil" src="https://github.com/user-attachments/assets/13ff48b7-ffcb-4f85-8325-002a76d63e58" />

## Tools I Used

- **PostgreSQL** - designed and built a relational database from scratch, wrote all analytical queries including window functions, joins across five tables, and derived metrics
- **VS Code + SQLTools** - primary development environment for query writing and execution
- **Excel** - reshaped wide-format World Bank and CPI exports into clean long-format CSVs ready for database ingestion
- **GitHub** - version control and public portfolio hosting

## Data Sources

| Dataset | Source | Years Covered |
|--------|--------|--------------|
| Oil rents (% of GDP) | World Bank World Development Indicators | 2003–2021 |
| Corruption Perceptions Index | Transparency International | 2012–2023 |
| Electricity, water, and health access | World Bank World Development Indicators | 2003–2023 |
| Political violence and fatalities | ACLED via UN OCHA Humanitarian Data Exchange | 2016–2021 |

All datasets are publicly available and widely cited in academic and policy research. Data was sourced directly from institutional repositories rather than third-party aggregators to ensure accuracy and credibility.

---

## Data Cleaning

Raw data from the World Bank and Transparency International arrives in wide format: years as columns, countries as rows and includes metadata rows, junk headers, and empty cells. Before any analysis could begin, every dataset required significant preparation:

- Filtered all datasets to Iraq only
- Converted wide-format exports to long-format CSVs with year as the primary key
- Removed metadata and junk rows from World Bank exports
- Manually reconstructed clean timeseries CSVs for oil revenue and CPI scores
- Standardized column names across all five tables for clean joining in PostgreSQL
- Handled missing years across datasets using LEFT JOINs and COALESCE in SQL

---

## The Analysis

### 1. Oil Revenue vs Corruption Over Time

The first question: does Iraq's corruption improve when oil revenues are high?

```sql
SELECT
    year,
    oil_rents,
    cpi_score,
    oil_rents - LAG(oil_rents) OVER (ORDER BY year) AS oil_change,
    cpi_score - LAG(cpi_score) OVER (ORDER BY year) AS corruption_change
FROM iraq_master_analysis
ORDER BY year;
```

<img width="800" height="450" alt="yearly_changes_visualization_1" src="https://github.com/user-attachments/assets/363d7196-52fa-44eb-89cc-9d45a18e3561" />

**Finding:** Oil revenue and corruption scores move independently. In years where oil revenue dropped sharply, corruption did not worsen. In years where oil revenue surged, corruption did not improve. The two variables are effectively decoupled.

---

### 2. Service Delivery Change Year Over Year

Does oil revenue drive improvements in water, health, or electricity access?

```sql
SELECT
    year,
    oil_rents,
    water_access,
    health_exp,
    ROUND((water_access - LAG(water_access) OVER (ORDER BY year))::numeric, 2) AS water_change,
    ROUND((health_exp - LAG(health_exp) OVER (ORDER BY year))::numeric, 2) AS health_change
FROM iraq_master_analysis
ORDER BY year;
```
<img width="800" height="450" alt="service_delivery_change_yoy_2" src="https://github.com/user-attachments/assets/aee30601-6a7f-46ca-99de-9dea70bc41b4" />


**Finding:** Service delivery improves at a slow, flat rate regardless of oil revenue levels. Water access improved by approximately 0.88-0.90% every year whether oil was at 27% or 49% of GDP. Revenue fluctuations had no meaningful impact on service delivery pace.

---

### 3. The Inefficiency Index

Which years saw the most oil wealth relative to governance quality?

```sql
SELECT
    year,
    oil_rents,
    cpi_score,
    ROUND((oil_rents / cpi_score)::numeric, 2) AS oil_per_corruption_unit,
    ROUND((water_access + health_exp + electricity_access)::numeric, 2) AS service_composite
FROM iraq_master_analysis
ORDER BY oil_per_corruption_unit DESC;
```
<img width="1024" height="447" alt="The_Inefficiency_Index_3" src="https://github.com/user-attachments/assets/50a8d466-a125-4d30-b6f7-9b63452bb90e" />

**Finding:** 2014 was Iraq's most inefficient year, the highest ratio of oil wealth to governance quality. Ironically, the years with the lowest inefficiency scores (2020-2021) correspond to oil price crashes, suggesting the government became marginally more accountable when resources were constrained.

---

### 4. Violence, Oil, and Governance

How does political violence relate to oil revenue and corruption?

```sql
SELECT
    p.year,
    SUM(p.events) AS total_violence_events,
    SUM(p.fatalities) AS total_fatalities,
    m.oil_rents,
    m.cpi_score
FROM political_violence p
JOIN iraq_master_analysis m ON p.year = m.year
GROUP BY p.year, m.oil_rents, m.cpi_score
ORDER BY p.year;
```
<img width="1024" height="576" alt="Security_trends_04" src="https://github.com/user-attachments/assets/ab1670e1-3801-494a-b13c-d7f8962a5cf1" />

**Finding:** Violence peaked in 2016 at 9,761 events and 56,032 fatalities, the tail end of the ISIS conflict. By 2019, violence had dropped significantly as the military situation stabilized. However, violence rebounded in 2021 despite modest improvements in corruption scores, suggesting that security without governance reform is not sufficient to achieve stability.

---

### 5. The Full Picture

A single table connecting all variables:

```sql
SELECT
    m.year,
    m.oil_rents,
    m.cpi_score,
    m.water_access,
    m.health_exp,
    COALESCE(SUM(p.events), 0) AS violence_events,
    COALESCE(SUM(p.fatalities), 0) AS fatalities,
    ROUND((m.oil_rents / m.cpi_score)::numeric, 2) AS inefficiency_index
FROM iraq_master_analysis m
LEFT JOIN political_violence p ON m.year = p.year
GROUP BY m.year, m.oil_rents, m.cpi_score, m.water_access, m.health_exp
ORDER BY m.year;
```

---

## What I Learned

**Technically:**
- Designed a multi-table relational database from scratch using PostgreSQL
- Applied window functions (LAG, OVER, PARTITION BY) for time-series analysis
- Used LEFT JOINs and COALESCE to handle mismatched date ranges across datasets
- Built derived metrics like the inefficiency index to surface non-obvious patterns
- Cleaned and reshaped real-world institutional data from the World Bank, Transparency International, and ACLED

**Analytically:**
- Learned that official access statistics (like electricity access at 99%) can be deeply misleading without qualitative context, Iraq had connections but suffered daily blackouts
- The findings are consistent with the resource curse hypothesis through data: oil wealth and governance quality are decoupled in Iraq
- Discovered that service delivery improvements follow a mechanical, flat trajectory regardless of revenue shocks suggesting structural, not financial, barriers to development

---

## Conclusions

Iraq's data tells a clear story. Oil revenues fluctuated dramatically between 2012 and 2021 from a high of 49.61% of GDP to a low of 27.04% yet corruption scores barely moved, services improved at a crawl, and political violence remained severe.

The inefficiency index created in this analysis shows that Iraq's worst years for governance-to-revenue ratio were its richest oil years. More money flowed in, more was lost before reaching citizens. When revenues collapsed in 2020, the government became marginally more accountable not because things improved, but because there was less to steal.

For Iraq to break this cycle, the answer is not higher oil prices. It is the structural reform of institutions that have learned to survive on extraction rather than accountability, and that is exactly what i wish for my country in the upcoming years.

<img width="943" height="490" alt="iraq-flag" src="https://github.com/user-attachments/assets/d5c20cce-623a-4bfa-b11e-788a24c2e551" />

