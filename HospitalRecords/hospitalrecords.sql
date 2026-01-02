-- Create and import patients table for the raw dataset

CREATE TABLE patients_raw (
    id VARCHAR(36) PRIMARY KEY,
    birthdate DATE,
    deathdate DATE,
    prefix VARCHAR(10),
    first VARCHAR(50),
    last VARCHAR(50),
    suffix VARCHAR(10),
    maiden VARCHAR(50),
    marital VARCHAR(20),
    race VARCHAR(20),
    ethnicity VARCHAR(20),
    gender CHAR(1),
    birthplace TEXT,
    address TEXT,
    city TEXT,
    state VARCHAR(50),
    county VARCHAR(50),
    zip VARCHAR(20),
    lat NUMERIC(10,8),
    lon NUMERIC(11,8)
);


-- Verify Table Importation
SELECT *
FROM patients_raw;

-- Create and import the payers for the raw dataset

CREATE TABLE payers_raw (
    id VARCHAR(36) PRIMARY KEY,
    name TEXT,
    address TEXT,
    city TEXT,
    state_headquartered VARCHAR(50),
    zip VARCHAR(20),
    phone VARCHAR(20)
);

-- Verify the payers table
SELECT *
FROM payers_raw;

-- Create and import the organization table for the raw dataset

CREATE TABLE organization_raw (
    id VARCHAR(36) PRIMARY KEY,
    name TEXT,
    address TEXT,
    city TEXT,
    state VARCHAR(50),
    zip VARCHAR(20),
    lat NUMERIC(10,8),
    lon NUMERIC(11,8)
);

-- Verify the organization table
SELECT *
FROM organization_raw;

-- Create and import the encounters table for the raw dataset

CREATE TABLE encounters_raw (
    id VARCHAR(36) PRIMARY KEY,
    start_time TIMESTAMP NOT NULL,
    stop_time TIMESTAMP,
    patient VARCHAR(36) NOT NULL,
    organization VARCHAR(36),
    payer VARCHAR(36),
    encounterclass VARCHAR(50),
    code VARCHAR(20),
    description TEXT,
    base_encounter_cost NUMERIC(10,2),
    total_claim_cost NUMERIC(10,2),
    payer_coverage NUMERIC(10,2),
    reasoncode VARCHAR(50),
    reasondescription TEXT,
    FOREIGN KEY (patient) REFERENCES patients_raw(id),
    FOREIGN KEY (payer) REFERENCES payers_raw(id),
    FOREIGN KEY (organization) REFERENCES organization_raw(id)
);

-- Verify the encounters table
SELECT *
FROM encounters_raw;

-- Create and import the procedures table

CREATE TABLE procedures_raw (
    start_time TEXT,
    stop_time TEXT,
    patient VARCHAR(36),
    encounter VARCHAR(36),
    code VARCHAR(20),
    description TEXT,
    base_cost TEXT,
    reasoncode TEXT,
    reasondescription TEXT
);

-- Verify the procedures table
SELECT *
FROM procedures_raw;

-- Create the patients staging table

CREATE TABLE patients_staging AS
SELECT *
FROM patients_raw;

-- Create the payers staging table

CREATE TABLE payers_staging AS
SELECT *
FROM payers_raw;

-- CREATE the organization staging table

CREATE TABLE organization_staging AS
SELECT *
FROM organization_raw;

-- Create the encounters staging table
CREATE TABLE encounters_staging AS
SELECT *
FROM encounters_raw;

-- Create the procedures staging table

CREATE TABLE procedures_staging AS
SELECT *
FROM procedures_raw;

-- Create the patients clean table
CREATE TABLE patients_clean AS
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY birthdate DESC) AS rn
    FROM patients_staging
)

SELECT
    id,
    birthdate::DATE AS birthdate,
    deathdate::DATE AS deathdate,
    prefix, first, last, suffix,
    maiden, marital, race, ethnicity, gender,
    birthplace, address, city, state, county,
    zip, lat::NUMERIC, lon::NUMERIC
FROM cte
WHERE rn = 1;

ALTER TABLE patients_clean
ADD PRIMARY KEY (id);

-- Create payers_clean table
CREATE TABLE payers_clean AS
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY name) AS rn
    FROM payers_staging
)

SELECT
    id, name, address, city, state_headquartered, zip, phone
FROM cte
WHERE rn = 1;

ALTER TABLE payers_clean
ADD PRIMARY KEY (id);

-- Create the organization clean table
CREATE TABLE organization_clean AS
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY name) AS rn
    FROM organization_staging
)
SELECT
    id, name, address, city, state, zip, lat::NUMERIC, lon::NUMERIC
FROM cte
WHERE rn = 1;

ALTER TABLE organization_clean
ADD PRIMARY KEY (id);

-- Create the encounters clean table

CREATE TABLE encounters_clean AS
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY start_time) AS rn
    FROM encounters_staging
)
SELECT
    id,
    start_time::TIMESTAMPTZ AS start_time,
    stop_time::TIMESTAMPTZ AS stop_time,
    patient,
    organization,
    payer,
    encounterclass,
    code,
    description,
    base_encounter_cost::NUMERIC(10,2) AS base_encounter_cost,
    total_claim_cost::NUMERIC(10,2) AS total_claim_cost,
    payer_coverage::NUMERIC(10,2) AS payer_coverage,
    reasoncode,
    reasondescription
FROM cte
WHERE rn = 1;

ALTER TABLE encounters_clean
ADD PRIMARY KEY (id);

-- Foreign Keys
ALTER TABLE encounters_clean
ADD CONSTRAINT fk_patient
    FOREIGN KEY (patient) REFERENCES patients_clean(id);

ALTER TABLE encounters_clean
ADD CONSTRAINT fk_organization
    FOREIGN KEY (organization) REFERENCES organization_clean(id);

ALTER TABLE encounters_clean
ADD CONSTRAINT fk_payer
    FOREIGN KEY (payer) REFERENCES payers_clean(id);

-- Create the procedures clean table

CREATE TABLE procedures_clean AS
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY encounter, code ORDER BY start_time) AS rn
    FROM procedures_staging
)
SELECT
    start_time::TIMESTAMPTZ AS start_time,
    stop_time::TIMESTAMPTZ AS stop_time,
    patient,
    encounter,
    code,
    description,
    base_cost::NUMERIC(10,2) AS base_cost,
    reasoncode,
    reasondescription
FROM cte
WHERE rn = 1;

ALTER TABLE procedures_clean
ADD PRIMARY KEY (encounter, code);

-- Foreign Keys
ALTER TABLE procedures_clean
ADD CONSTRAINT fk_patient
    FOREIGN KEY (patient) REFERENCES patients_clean(id);

ALTER TABLE procedures_clean
ADD CONSTRAINT fk_encounter
    FOREIGN KEY (encounter) REFERENCES encounters_clean(id);

-- Data Cleaning
-- Patients Table
-- Drop SUFFIX
ALTER TABLE patients_clean DROP COLUMN IF EXISTS suffix;

-- Fill missing categorical/text values
UPDATE patients_clean
SET maiden = COALESCE(maiden, 'Unknown'),
    marital = COALESCE(marital, 'Unknown'),
    race = COALESCE(race, 'Unknown'),
    ethnicity = COALESCE(ethnicity, 'Unknown'),
    gender = COALESCE(gender, 'Unknown');

-- ZIP as string
UPDATE patients_clean
SET zip = COALESCE(zip::TEXT, 'Unknown');

-- Trim text columns
UPDATE patients_clean
SET first = TRIM(first),
    last = TRIM(last),
    birthplace = TRIM(birthplace),
    address = TRIM(address),
    city = TRIM(city),
    state = TRIM(state),
    county = TRIM(county);

-- Clean the encounters table
-- Drop REASONCODE
ALTER TABLE encounters_clean DROP COLUMN IF EXISTS reasoncode;

-- Fill missing REASONDESCRIPTION
UPDATE encounters_clean
SET reasondescription = COALESCE(reasondescription, 'Unknown');

-- Trim text columns
UPDATE encounters_clean
SET description = TRIM(description),
    reasondescription = TRIM(reasondescription),
    encounterclass = TRIM(encounterclass);

-- Clean the procedures table
ALTER TABLE procedures_clean DROP COLUMN IF EXISTS reasoncode;

-- Fill missing REASONDESCRIPTION
UPDATE procedures_clean
SET reasondescription = COALESCE(reasondescription, 'Unknown');

-- Trim text columns
UPDATE procedures_clean
SET description = TRIM(description),
    reasondescription = TRIM(reasondescription);

-- Clean the payers table
UPDATE payers_clean
SET address = COALESCE(address, 'Unknown'),
    city = COALESCE(city, 'Unknown'),
    state_headquartered = COALESCE(state_headquartered, 'Unknown'),
    phone = COALESCE(phone, 'Unknown'),
    zip = COALESCE(zip::TEXT, 'Unknown');

-- Trim text columns
UPDATE payers_clean
SET name = TRIM(name),
    address = TRIM(address),
    city = TRIM(city),
    state_headquartered = TRIM(state_headquartered);

-- Clean the organization table
UPDATE organization_clean
SET zip = COALESCE(zip::TEXT, 'Unknown'),
    name = TRIM(name),
    address = TRIM(address),
    city = TRIM(city),
    state = TRIM(state);

-- Data Analysis
-- Q1a. How many total encounters occurred each year?

SELECT
	EXTRACT(YEAR FROM start_time) AS year,
	COUNT(*) AS total_encounters
FROM encounters_clean
GROUP BY year
ORDER BY year;

-- INSIGHT:
-- Total encounters increased steadily from 2011 to 2014, peaking in 2014.
-- After 2014, encounter volume declined gradually and then stabilized
-- between 2016 and 2019, with a slight increase again in 2021.
-- This suggests an initial growth phase in healthcare utilization
-- followed by a period of stabilization.


-- Q1b. For each year, what percentage of all encounters belonged to each encounter class
-- (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?

SELECT
    encounterclass,
    EXTRACT(YEAR FROM start_time) AS year,
    COUNT(*) AS total_encounters,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY EXTRACT(YEAR FROM start_time)),
        2
    ) AS percentage
FROM encounters_clean
GROUP BY encounterclass, year
ORDER BY year, percentage DESC;

-- INSIGHT:
-- Ambulatory encounters consistently account for the largest share of
-- encounters each year, representing roughly 40–50% of total encounters.
-- Outpatient encounters are the second most common, contributing about
-- 20–25% annually.
-- Emergency and inpatient encounters make up a relatively small but
-- stable proportion of total encounters, while wellness and urgent care
-- visits vary moderately across years.
-- Overall, the encounter mix indicates a strong emphasis on routine
-- and non-emergency care.

-- Q1c. What percentage of encounters were over 24 hours versus under 24 hours?
SELECT
    CASE 
        WHEN (stop_time - start_time) > INTERVAL '24 hours' 
        THEN 'Over 24 Hours' 
        ELSE 'Under 24 Hours' 
    END AS duration_category,
    COUNT(*) AS encounters,
    ROUND( COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM encounters_clean
GROUP BY duration_category;

-- INSIGHT:
-- The vast majority of encounters (over 99%) lasted less than 24 hours.
-- Encounters exceeding 24 hours represent less than 1% of all visits,
-- indicating that long hospital stays are rare in this dataset.
-- This suggests that most patient interactions are short-term visits,
-- such as outpatient, ambulatory, or same-day services.

-- Q2a.  How many encounters had zero payer coverage,
-- and what percentage of total encounters does this represent?
SELECT
    COUNT(*) AS zero_coverage_encounters,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM encounters_clean),
        2
    ) AS percentage_of_total
FROM encounters_clean
WHERE payer_coverage = 0;

-- Insight:
-- Out of all encounters, 13,586 (48.71%) had zero payer coverage.
-- This indicates that nearly half of all healthcare encounters were not covered by insurance,
-- suggesting a substantial burden of out-of-pocket costs or uninsured care within the dataset.

-- Q2b. b. What are the top 10 most frequent procedures
-- performed and the average base cost for each?

SELECT description,
       COUNT(*) AS frequency,
       ROUND(AVG(base_cost), 2) AS avg_base_cost
FROM procedures_clean
GROUP BY description
ORDER BY frequency DESC, description ASC
LIMIT 10;

-- Insight:
-- The most frequently performed procedures are primarily routine assessments and screenings,
-- such as health and social care assessments, depression screenings, and substance use evaluations.
-- Most of these high-volume procedures have a relatively low and consistent average base cost (~$431),
-- indicating standardized pricing for common preventive and diagnostic services.
-- Renal dialysis stands out as a frequent procedure with a significantly higher average base cost,
-- reflecting the higher resource intensity of this treatment.

-- Q2c. What are the top 10 procedures with the highest average base cost
-- and the number of times they were performed?

SELECT
	description,
	ROUND(AVG(base_cost), 2) AS avg_base_cost,
	COUNT(*) AS frequency
FROM procedures_clean
GROUP by description
ORDER BY avg_base_cost DESC
LIMIT 10;
	
-- Insight:
-- The procedures with the highest average base cost are highly specialized and intensive treatments,
-- such as ICU admission, coronary artery bypass grafting, and advanced cardiovascular interventions.
-- Although these procedures occur far less frequently than routine assessments,
-- their high individual costs contribute disproportionately to overall healthcare spending.
-- Electrical cardioversion appears both high-cost and relatively frequent,
-- making it a notable driver of total procedural expenditure.

-- Q2d. What is the average total claim cost for encounters, broken down by payer?

SELECT
    p.name AS payer_name,
    ROUND(AVG(e.total_claim_cost), 2) AS avg_total_claim_cost,
    COUNT(*) AS encounter_count
FROM encounters_clean e
LEFT JOIN payers_clean p
    ON e.payer = p.id
GROUP BY p.name
ORDER BY avg_total_claim_cost DESC;

-- Insight: 
-- Average total claim costs vary significantly by payer.
-- The payer with ID 7c4411ce-02f1-39b5-b9ec-dfbea9ad3c1a has the highest average total claim cost (~$6,205),
-- indicating more expensive encounters or higher reimbursement rates.
-- Several payers cluster between $2,500–$4,000, suggesting relatively similar cost structures.
-- The lowest average total claim cost (~$1,696) may reflect coverage focused on less intensive or lower-cost care.
-- Overall, payer type appears to play a meaningful role in total encounter costs.

-- Q3a. How many unique patients were admitted each quarter over time?
SELECT
    EXTRACT(YEAR FROM start_time) AS year,
    EXTRACT(QUARTER FROM start_time) AS quarter,
    COUNT(DISTINCT patient) AS unique_patients_admitted
FROM encounters_clean
GROUP BY
    EXTRACT(YEAR FROM start_time),
    EXTRACT(QUARTER FROM start_time)
ORDER BY year, quarter;

-- Insight:
-- The number of unique patients admitted per quarter generally increases from 2011
-- through 2014, peaking around 2014, which may indicate expanded healthcare utilization
-- or population growth.
-- From 2015 to 2020, quarterly admissions remain relatively stable, fluctuating within a narrow range.
-- A notable spike occurs in early 2021, followed by a decline toward 2022,
-- which could reflect external factors such as healthcare disruptions or dataset coverage changes.
-- Overall, admissions show long-term growth with short-term seasonal and annual variation.

-- Q3b. How many patients were readmitted within 30 days of a previous encounter?

WITH ordered_encounters AS (
    SELECT
        patient,
        start_time,
        LAG(start_time) OVER (
            PARTITION BY patient
            ORDER BY start_time
        ) AS previous_start
    FROM encounters_clean
)

SELECT
    COUNT(DISTINCT patient) AS patients_readmitted_within_30_days
FROM ordered_encounters
WHERE
    previous_start IS NOT NULL
    AND start_time - previous_start <= INTERVAL '30 days';

-- Insight:
-- A total of 772 patients were readmitted within 30 days of a previous encounter.
-- This indicates a non-trivial level of short-term readmissions,
-- which may suggest chronic conditions, complications, or gaps in post-discharge care.
-- Monitoring 30-day readmissions is important, as they are often used as a quality-of-care metric.

-- Q3c. Which patients had the most readmissions?

WITH ordered_encounters AS (
    SELECT
        patient,
        start_time,
        LAG(start_time) OVER (
            PARTITION BY patient
            ORDER BY start_time
        ) AS previous_start
    FROM encounters_clean
),
readmissions AS (
    SELECT
        patient
    FROM ordered_encounters
    WHERE
        previous_start IS NOT NULL
        AND start_time - previous_start <= INTERVAL '30 days'
)

SELECT
    patient,
    COUNT(*) AS readmission_count
FROM readmissions
GROUP BY patient
ORDER BY readmission_count DESC;

-- Insight:
-- A small number of patients account for a disproportionately high number of readmissions.
-- The top patient experienced over 1,300 readmissions, far exceeding others.
-- This concentration suggests the presence of high-utilization patients,
-- potentially driven by chronic illness, long-term care needs, or frequent treatment regimens.
-- Targeted care management or intervention programs for these patients
-- could significantly reduce overall readmission volume.