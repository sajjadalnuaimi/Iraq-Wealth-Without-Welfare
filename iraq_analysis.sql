DROP TABLE protests;

CREATE TABLE protests (
    country VARCHAR(100),
    month VARCHAR(20),
    year INT,
    events INT
);

COPY protests(country, month, year, events)
FROM 'C:\Users\sajja\OneDrive\Desktop\Iraq Corruption Data\iraq_demonstration_events_by_month-year_as-of-25jun2026(Data).csv'
WITH (FORMAT csv, HEADER true);

SELECT *
FROM protests;

DROP TABLE political_violence;

CREATE TABLE political_violence (
    country VARCHAR(100),
    month VARCHAR(20),
    year INT,
    events INT,
    fatalities INT
);

COPY political_violence(country, month, year, events, fatalities)
FROM 'C:\Users\sajja\OneDrive\Desktop\Iraq Corruption Data\iraq_political_violence_events_and_fatalities_by_month-year_as-of-25jun2026 (1)(Data).csv'
WITH (FORMAT csv, HEADER true);

SELECT * 
FROM political_violence 
LIMIT 5;

DROP TABLE protests;

CREATE TABLE protests (
    country VARCHAR(100),
    month VARCHAR(20),
    year INT,
    events INT,
    fatalities INT
);

COPY protests(country, month, year, events, fatalities)
FROM 'C:\Users\sajja\OneDrive\Desktop\Iraq Corruption Data\iraq_political_violence_events_and_fatalities_by_month-year_as-of-25jun2026 (1)(Data).csv'
WITH (FORMAT csv, HEADER true);

SELECT * FROM protests LIMIT 5;

CREATE TABLE oil_revenue (
    year INT,
    country_name VARCHAR(100),
    oil_rents_pct_gdp NUMERIC
);

COPY oil_revenue(year, country_name, oil_rents_pct_gdp)
FROM 'C:\Users\sajja\OneDrive\Desktop\Iraq Corruption Data\API_NY.GDP.PETR.RT.ZS_DS2_en_csv_v2_446381\iraq_oil_data.csv'
WITH (FORMAT csv, HEADER true);

SELECT * FROM oil_revenue LIMIT 5;

CREATE TABLE corruption (
    country VARCHAR(100),
    year INT,
    cpi_score NUMERIC
);

COPY corruption(country, year, cpi_score)
FROM 'C:\Users\sajja\OneDrive\Desktop\Iraq Corruption Data\iraq_cpi_data.csv'
WITH (FORMAT csv, HEADER true);

SELECT * FROM corruption LIMIT 5;

CREATE TABLE service_delivery (
    year INT,
    electricity_access NUMERIC,
    health_expenditure NUMERIC,
    water_access NUMERIC
);

COPY service_delivery(year, electricity_access, health_expenditure, water_access)
FROM 'C:\Users\sajja\OneDrive\Desktop\Iraq Corruption Data\P_Data_Extract_From_World_Development_Indicators\iraq.development_indicator.csv.csv'
WITH (FORMAT csv, HEADER true);

SELECT * FROM service_delivery LIMIT 5;

SELECT 
    o.year,
    o.oil_rents_pct_gdp,
    c.cpi_score
FROM oil_revenue o
JOIN corruption c ON o.year = c.year
ORDER BY o.year;

SELECT 
    o.year,
    ROUND(o.oil_rents_pct_gdp::numeric, 2) AS oil_rents,
    c.cpi_score,
    s.electricity_access,
    ROUND(s.health_expenditure::numeric, 2) AS health_exp,
    ROUND(s.water_access::numeric, 2) AS water_access
FROM oil_revenue o
JOIN corruption c ON o.year = c.year
JOIN service_delivery s ON o.year = s.year
ORDER BY o.year;

CREATE TABLE iraq_master_analysis AS
SELECT 
    o.year,
    ROUND(o.oil_rents_pct_gdp::numeric, 2) AS oil_rents,
    c.cpi_score,
    s.electricity_access,
    ROUND(s.health_expenditure::numeric, 2) AS health_exp,
    ROUND(s.water_access::numeric, 2) AS water_access
FROM oil_revenue o
JOIN corruption c ON o.year = c.year
JOIN service_delivery s ON o.year = s.year
ORDER BY o.year;

SELECT * FROM iraq_master_analysis;


SELECT
    year,
    oil_rents,
    cpi_score,
    oil_rents - LAG(oil_rents) OVER (ORDER BY year) AS oil_change,
    cpi_score - LAG(cpi_score) OVER (ORDER BY year) AS corruption_change
FROM iraq_master_analysis
ORDER BY year;


SELECT
    year,
    oil_rents,
    water_access,
    health_exp,
    ROUND((water_access - LAG(water_access) OVER (ORDER BY year))::numeric, 2) AS water_change,
    ROUND((health_exp - LAG(health_exp) OVER (ORDER BY year))::numeric, 2) AS health_change
FROM iraq_master_analysis
ORDER BY year;

SELECT
    year,
    oil_rents,
    cpi_score,
    ROUND((oil_rents / cpi_score)::numeric, 2) AS oil_per_corruption_unit,
    ROUND((water_access + health_exp + electricity_access)::numeric, 2) AS service_composite
FROM iraq_master_analysis
ORDER BY oil_per_corruption_unit DESC;


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