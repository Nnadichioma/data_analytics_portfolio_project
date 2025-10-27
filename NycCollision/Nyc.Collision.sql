-- Created the table structure
CREATE TABLE nyc_collision (
    crash_id INT PRIMARY KEY,
    crash_date DATE NOT NULL,
    crash_time TIME NOT NULL,
    borough VARCHAR(50),
    street_name VARCHAR(100),
    cross_street VARCHAR(100),
    latitude NUMERIC(10,6),
    longitude NUMERIC(10,6),
    contributing_factor VARCHAR(200),
    vehicle_type VARCHAR(50),
    persons_injured SMALLINT,
    persons_killed SMALLINT,
    pedestrians_injured SMALLINT,
    pedestrians_killed SMALLINT,
    cyclists_injured SMALLINT,
    cyclists_killed SMALLINT,
    motorists_injured SMALLINT,
    motorists_killed SMALLINT
);

-- Verified Data Importation
SELECT *
FROM nyc_collision;

-- Created a staging table
CREATE TABLE st_nyc_collision AS
SELECT *
FROM nyc_collision;

-- Data Cleaning
-- Created a staging table for cleaning
DROP TABLE IF EXISTS st_nyc_collision_clean;

CREATE TABLE st_nyc_collision_clean AS
SELECT
    crash_id,
    crash_date,
    crash_time,

    -- Text columns: trim spaces + capitalize first letters + default values
    INITCAP(TRIM(COALESCE(borough, 'Unknown'))) AS borough,
    INITCAP(TRIM(COALESCE(street_name, 'Not Provided'))) AS street_name,
    INITCAP(TRIM(COALESCE(cross_street, 'Not Provided'))) AS cross_street,
    INITCAP(TRIM(COALESCE(contributing_factor, 'Unknown'))) AS contributing_factor,
    INITCAP(TRIM(COALESCE(vehicle_type, 'Unspecified'))) AS vehicle_type,

    -- Numeric columns: preserved NULLs to distinguish missing vs zero
    latitude,
    longitude,
    persons_injured,
    persons_killed,
    pedestrians_injured,
    pedestrians_killed,
    cyclists_injured,
    cyclists_killed,
    motorists_injured,
    motorists_killed
FROM st_nyc_collision;

-- Checking and Removing Duplicates
WITH dup AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY crash_id ORDER BY crash_date, crash_time, borough, street_name, cross_street, latitude, longitude
        ) AS rn
    FROM st_nyc_collision_clean
)
SELECT *
FROM dup
WHERE rn > 1;
-- No Duplicates were found


-- Data Exploration
-- 1). Compare the % of total accidents by month. Do you notice any seasonal patterns? 
SELECT 
    TO_CHAR(crash_date, 'Month') AS month_name,
    COUNT(*) AS accident_count,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM st_nyc_collision_clean), 2) AS pct_of_total
FROM st_nyc_collision_clean
GROUP BY TO_CHAR(crash_date, 'Month')
ORDER BY accident_count DESC;

-- Per year + month (to check repeatability of patterns)
SELECT 
    EXTRACT(YEAR FROM crash_date) AS year,
    EXTRACT(MONTH FROM crash_date) AS month_num,
    TO_CHAR(crash_date, 'Month') AS month_name,
    COUNT(*) AS accident_count,
    ROUND(
        (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (PARTITION BY EXTRACT(YEAR FROM crash_date)), 
        2
    ) AS pct_of_year
FROM st_nyc_collision_clean
GROUP BY EXTRACT(YEAR FROM crash_date), EXTRACT(MONTH FROM crash_date), TO_CHAR(crash_date, 'Month')
ORDER BY year, month_num;

/* Insight: When comparing monthly accident percentages from 2021 to 2023, a clear seasonal pattern emerges.
Accidents generally rise during late spring and summer (May–July) in both 2021 and 2022, with a secondary peak observed in October 2021.
For 2023, data is available only for January–April, where March recorded the highest proportion of collisions.
Overall, motor vehicle accidents in NYC show a tendency to increase during warmer months,
indicating a possible link to higher traffic activity and mobility.
*/

-- 2). Break down accident frequency by day of week and hour of day. Based on this data, when do accidents occur most frequently?
SELECT
    TO_CHAR(crash_date, 'Day') AS day_of_week,
    EXTRACT(HOUR FROM crash_time) AS hour_of_day,
    COUNT(*) AS accident_count
FROM st_nyc_collision_clean
GROUP BY TO_CHAR(crash_date, 'Day'), EXTRACT(HOUR FROM crash_time)
ORDER BY accident_count DESC;

/* Insight: Accidents occur most frequently during weekday afternoons, particularly between 3 PM and 5 PM.
Friday consistently has the highest accident counts, followed by Wednesday, Thursday, and Tuesday.
Morning hours (7–9 AM) also show noticeable peaks, likely linked to commuting traffic.
Weekends have generally lower accident frequencies, except for specific times around noon and early evening.
Late-night hours (0–6 AM) have the fewest accidents.
*/

-- 3). On which particular street were the most accidents reported? What does that represent as a % of all reported accidents?
SELECT
    street_name AS street,
    COUNT(*) AS total_accidents,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_total
FROM st_nyc_collision_clean
WHERE street_name IS NOT NULL
GROUP BY street_name
ORDER BY total_accidents DESC
LIMIT 1;

/*
Insight: The street with the highest number of reported collisions is Belt Parkway, with 3,728 accidents,
representing approximately 1.56% of all reported collisions in the dataset.
This indicates that Belt Parkway experiences a high frequency of accidents,
likely due to its heavy traffic volume, high-speed limits, and its function as a major expressway in New York City.
*/

-- 4a). What was the most common contributing factor for the accidents reported in this sample (based on 
-- Vehicle 1)? 4b).What about fatal accidents specifically?

-- 4a).
SELECT
    contributing_factor AS factor,
    COUNT(*) AS total_accidents,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_total
FROM st_nyc_collision_clean
GROUP BY contributing_factor
ORDER BY total_accidents DESC
LIMIT 10;

-- Answer: Driver Inattention is the leading recorded cause with 58,308 accidents (24.46%).

-- In contrast to Nulls or Unknown
SELECT
	contributing_factor,
	count(*) AS total_accidents,
	ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER () , 2) AS percent_total
FROM st_nyc_collision_clean
WHERE contributing_factor = 'Unknown'
GROUP BY contributing_factor
ORDER by total_accidents DESC
LIMIT 1;
-- Answer: Unknown (missing/nulls/unknown) accounts for 1,287 accidents (100%)

/* Overall Insights:
Driver Inattention is the leading known cause of accidents, with 58,308 crashes (24.46%).
At the same time, “Unknown” accidents also account for 1287 crashes (100%), reflecting missing or unreported causes.
Considering only recorded causes, Driver Inattention clearly dominates,
highlighting the importance of safe driving and awareness efforts.
*/

-- 4b)
SELECT
    contributing_factor AS factor,
    COUNT(*) AS fatal_accidents,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_total
FROM st_nyc_collision_clean
WHERE persons_killed > 0 AND contributing_factor <> 'Unknow'
GROUP BY contributing_factor
ORDER BY fatal_accidents DESC
LIMIT 1;

/* Unsafe Speed is the leading contributing factor in fatal accidents, with 130 crashes (30.37%).
This shows that speeding is a major risk for deadly collisions
and emphasizes the importance of managing speed and enforcing traffic rules to improve road safety.
*/

/* Overall: The most common cause of accidents overall is Driver Inattention, responsible for 58,308 crashes (24.46%).
Looking at fatal crashes, the patterns are different: accidents with multiple fatalities (2–3 deaths)
are most often linked to Unsafe Speed, while single-fatality crashes are typically labeled Unspecified.
This shows that while driver inattention drives the majority of everyday collisions,
the more severe crashes tend to involve high-risk behaviors like
speeding or cases where the exact cause wasn’t clearly recorded.
*/

-- Total Fatalities
SELECT
    SUM(persons_killed) AS total_persons_killed,
    SUM(pedestrians_killed) AS total_pedestrians_killed,
    SUM(cyclists_killed) AS total_cyclists_killed,
    SUM(motorists_killed) AS total_motorists_killed,
    -- Overall total fatalities
    SUM(
        COALESCE(persons_killed, 0)
        + COALESCE(pedestrians_killed, 0)
        + COALESCE(cyclists_killed, 0)
        + COALESCE(motorists_killed, 0)
    ) AS total_fatalities
FROM st_nyc_collision_clean;

-- Collision by Vehicle Type
SELECT
    vehicle_type,
    COUNT(*) AS total_collisions
FROM st_nyc_collision_clean
GROUP BY vehicle_type
ORDER BY total_collisions DESC;

-- Fatal Collision by Vehicle type
SELECT
    vehicle_type,
    SUM(
        COALESCE(persons_killed, 0)
        + COALESCE(pedestrians_killed, 0)
        + COALESCE(cyclists_killed, 0)
        + COALESCE(motorists_killed, 0)
    ) AS total_fatalities
FROM st_nyc_collision_clean
WHERE LOWER(vehicle_type) = 'passenger vehicle'
GROUP BY vehicle_type;

/* Insight: Most collisions involve Passenger Vehicles (84.66%), while other types like
Transport vehicles, Taxis, Bicycles, and Buses make up far fewer crashes.
Motorcycles and Scooters, though less frequent, have relatively higher fatalities per crash,
highlighting the need for road safety measures for all vehicles,
especially vulnerable road users.
*/
