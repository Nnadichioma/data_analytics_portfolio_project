-- Creating the Consumers's Table 
CREATE TABLE consumers (
    consumer_id VARCHAR(25) PRIMARY KEY,
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    smoker VARCHAR(10),
    drink_level VARCHAR(30),
    transportation_method VARCHAR(30),
    marital_status VARCHAR(20),
    children VARCHAR(15),
    age INT,
    occupation VARCHAR(50),
    budget VARCHAR(10)
);

-- Verifying the table has being imported using SELECT * FROM consumers;

-- for data cleaning
-- Inserting into the st_consumers's table (staging table)
TRUNCATE TABLE st_consumers;
INSERT INTO st_consumers
SELECT * FROM consumers;

-- Verifying the st_consumers's table using SELECT * FROM st_consumers;

-- Removing the Duplicates in st_consumers_clean's table
DROP TABLE IF EXISTS st_consumers_clean;
CREATE TABLE st_consumers_clean AS
WITH dedup AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY consumer_id ORDER BY consumer_id) AS rn
    FROM st_consumers
)
SELECT *
FROM dedup
WHERE rn = 1;
-- Verifying SELECT * FROM st_consumers_clean;

-- Standardizing st_consumers_clean table
UPDATE st_consumers_clean
SET city = INITCAP(TRIM(city)),
    state = INITCAP(TRIM(state)),
    country = INITCAP(TRIM(country)),
    occupation = INITCAP(TRIM(occupation)),
    transportation_method = INITCAP(TRIM(transportation_method)),
    marital_status = INITCAP(TRIM(marital_status));

UPDATE st_consumers_clean
SET smoker = CASE
    WHEN LOWER(smoker) IN ('yes','y') THEN 'Yes'
    WHEN LOWER(smoker) IN ('no','n') THEN 'No'
    ELSE 'Unknown'
END;

UPDATE st_consumers_clean
SET drink_level = CASE
    WHEN LOWER(drink_level) IN ('abstemious','none') THEN 'Abstemious'
    WHEN LOWER(drink_level) IN ('social drinker','social') THEN 'Social Drinker'
    WHEN LOWER(drink_level) IN ('casual drinker','casual') THEN 'Casual Drinker'
    ELSE 'Unknown'
END;

UPDATE st_consumers_clean
SET children = COALESCE(NULLIF(TRIM(children), ''), 'Unknown');

UPDATE st_consumers_clean
SET budget = COALESCE(INITCAP(TRIM(budget)), 'Unknown');

UPDATE st_consumers_clean
SET marital_status = COALESCE(marital_status, 'Unknown'),
    occupation = COALESCE(occupation, 'Unknown'),
    transportation_method = COALESCE(transportation_method, 'Unknown');

-- Creating the Consumers Preferences's Table
DROP TABLE IF EXISTS consumer_preferences;
CREATE TABLE consumer_preferences (
    consumer_id VARCHAR(10) NOT NULL,
    preferred_cuisine VARCHAR(50) NOT NULL,
    --PRIMARY KEY (consumer_id, preferred_cuisine),
    FOREIGN KEY (consumer_id) REFERENCES consumers(Consumer_ID)
);

-- Create a staging table for consumers_preferences's table
DROP TABLE IF EXISTS st_consumer_preferences;

CREATE TABLE st_consumer_preferences AS
SELECT *
FROM consumer_preferences;

--Verifying the st_consumer_preferences's table SELECT * FROM st_consumer_preferences;
-- Standardizing the st_consumers_preferences's table	
-- Removing Duplicates from st_consumer_preferences's table
DROP TABLE IF EXISTS st_consumer_preferences_clean;
CREATE TABLE st_consumer_preferences_clean AS
WITH dedup AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY consumer_id, preferred_cuisine
               ORDER BY consumer_id, preferred_cuisine
           ) AS rn
    FROM st_consumer_preferences
)
SELECT consumer_id, preferred_cuisine
FROM dedup
WHERE rn = 1;

-- Standardize st_consumer_preferences_clean table
UPDATE st_consumer_preferences_clean
SET 
    consumer_id = INITCAP(TRIM(consumer_id)),
    preferred_cuisine = INITCAP(TRIM(preferred_cuisine));
	
-- Verifying st_consumer_preferences_clean SELECT * FROM st_consumer_preferences_clean;

-- Creating the Restaurants's Table
DROP TABLE IF EXISTS restaurants;
CREATE TABLE restaurants (
    restaurant_ID INT PRIMARY KEY,
    name VARCHAR(150),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(50),
    zip_Code VARCHAR(20),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    alcohol_Service VARCHAR(50),
    smoking_Allowed VARCHAR(50),
    price VARCHAR(20),
    franchise VARCHAR(10),
    area VARCHAR(50),
    parking VARCHAR(50)
);
-- Verifying the Restaurants's Table SELECT * FROM st_restaurants;

-- Creating a staging table for restaurants table
DROP TABLE IF EXISTS st_restaurants;

CREATE TABLE st_restaurants AS
SELECT *
FROM restaurants;

-- Removing Duplicates in st_restaurants_clean Table
DROP TABLE IF EXISTS st_restaurants_clean;
CREATE TABLE st_restaurants_clean AS
WITH dedup AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY restaurant_id ORDER BY restaurant_id) AS rn
    FROM st_restaurants
)
SELECT *
FROM dedup
WHERE rn = 1;

-- Standardizing the st_restaurants_clean table
UPDATE st_restaurants_clean
SET 
    Name = INITCAP(REGEXP_REPLACE(TRIM(Name), '\s+', ' ', 'g')),
    City = INITCAP(REGEXP_REPLACE(TRIM(City), '\s+', ' ', 'g')),
    State = INITCAP(REGEXP_REPLACE(TRIM(State), '\s+', ' ', 'g')),
    Country = INITCAP(REGEXP_REPLACE(TRIM(Country), '\s+', ' ', 'g')),
    Alcohol_Service = INITCAP(REGEXP_REPLACE(TRIM(Alcohol_Service), '\s+', ' ', 'g')),
    Smoking_Allowed = INITCAP(REGEXP_REPLACE(TRIM(Smoking_Allowed), '\s+', ' ', 'g')),
    Price = INITCAP(REGEXP_REPLACE(TRIM(Price), '\s+', ' ', 'g')),
    Franchise = INITCAP(REGEXP_REPLACE(TRIM(Franchise), '\s+', ' ', 'g')),
    Area = INITCAP(REGEXP_REPLACE(TRIM(Area), '\s+', ' ', 'g')),
    Parking = INITCAP(REGEXP_REPLACE(TRIM(Parking), '\s+', ' ', 'g'));

--Verifying the st_restaurants_clean table using SELECT * FROM st_restaurants_clean;

-- Creating the Ratings's Table
DROP TABLE IF EXISTS ratings;
CREATE TABLE Ratings (
    consumer_id VARCHAR(10) NOT NULL,
    restaurant_id INT NOT NULL,
    overall_rating INT NOT NULL,
    food_rating INT NOT NULL,
    service_rating INT NOT NULL,
    PRIMARY KEY (consumer_id, restaurant_id),
	FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    FOREIGN KEY (consumer_id) REFERENCES consumers(consumer_id)
);
--Verifying ratings table with SELECT * FROM ratings;

-- Creating a staging table for ratings table
DROP TABLE IF EXISTS st_ratings;

CREATE TABLE st_ratings AS
SELECT *
FROM ratings;

-- Removing Duplicatesin st_ratings's table
DROP TABLE IF EXISTS st_ratings_clean;
CREATE TABLE st_ratings_clean AS
WITH dedup AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY consumer_id, restaurant_id
               ORDER BY consumer_id, restaurant_id
           ) AS rn
    FROM st_ratings
)
SELECT consumer_id, restaurant_id, overall_rating, food_rating, service_rating
FROM dedup
WHERE rn = 1;

-- Standardizing the consumer_id's field
UPDATE st_ratings_clean
SET consumer_id = INITCAP(TRIM(consumer_id));

-- Verifying the st_ratings_clean table SELECT * FROM st_ratings_clean;

-- Creating the Restaurant_Cuisine Table
DROP TABLE IF EXISTS restaurant_cuisine;
CREATE TABLE restaurant_cuisine (
    restaurant_id INT NOT NULL,
    cuisine VARCHAR(50) NOT NULL,
    PRIMARY KEY (restaurant_id, cuisine),
	FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);

-- Verifying the Restaurant Cuisine's Table with SELECT * FROM restaurant_cuisine;

-- Creating staging table for restaurant cuisines
DROP TABLE IF EXISTS st_restaurant_cuisine;

CREATE TABLE st_restaurant_cuisine AS
SELECT *
FROM restaurant_cuisine;


-- Removing the Duplicates in st_restaurant_cuisine's Table
-- Create a clean staging table without duplicates
DROP TABLE IF EXISTS st_restaurant_cuisine_clean;

CREATE TABLE st_restaurant_cuisine_clean AS
WITH dup AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY restaurant_id, cuisine 
               ORDER BY restaurant_id, cuisine
           ) AS rn
    FROM st_restaurant_cuisine
)
SELECT *
FROM dup
WHERE rn = 1;

--Standardizing the st_restaurant_cusine_clean table
UPDATE st_restaurant_cuisine_clean
SET cuisine = INITCAP(TRIM(cuisine));

--Verifying the st_restaurant_clean table with SELECT * FROM st_restaurant_cuisine_clean;

-- DATA EXPLORATION

-- Q1a: Finding the highest-rated restaurants
-- Insight: Top-rated restaurants include Emilianos and Michiko,
-- showing that quality service and dining experience drive satisfaction more than price.
SELECT 
    res.restaurant_id,
    res.name,
    res.city,
    res.price,
    ROUND(AVG(r.overall_rating), 2) AS avg_overall_rating,
    COUNT(r.consumer_id) AS total_reviews
FROM restaurants AS res
JOIN ratings AS r
    ON res.restaurant_id = r.restaurant_id
GROUP BY res.restaurant_id, res.name, res.city, res.price
ORDER BY avg_overall_rating DESC, total_reviews DESC
LIMIT 10;

-- Q1b: Checking if consumer preferences affect ratings
-- Insight: Japanese cuisine has the highest average satisfaction,
-- indicating consumers who prefer Japanese food tend to rate it better.
SELECT 
    cp.preferred_cuisine, 
    ROUND(AVG(r.overall_rating),2) AS avg_rating,
    COUNT(r.consumer_id) AS num_ratings
FROM st_ratings_clean r
JOIN st_consumer_preferences_clean cp
    ON r.consumer_id = cp.consumer_id
GROUP BY cp.preferred_cuisine
ORDER BY avg_rating DESC;

-- Q2: Consumer Demographics Analysis to check for biases
-- Insight: The majority consumers are Young Adults, followed by Old.
-- Non-smokers and Abstemious (light) drinkers make up the largest lifestyle group.
-- Most are Students and Unmarried, indicating a youthful, health-conscious customer base.
-- Age distribution
ALTER TABLE st_consumers_clean
ADD age_bracket VARCHAR(20);

UPDATE st_consumers_clean
SET age_bracket = CASE
    WHEN age <= 12 THEN 'Children'
    WHEN age BETWEEN 13 AND 19 THEN 'Teenagers'
    WHEN age BETWEEN 20 AND 49 THEN 'Young Adult'
    WHEN age >= 50 THEN 'Old'
    ELSE 'Unknown'
END;

SELECT
    age_bracket,
    COUNT(*) AS age_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS age_percentage
FROM st_consumers_clean
GROUP BY age_bracket
ORDER BY age_count DESC;

-- Smokers Distribution
SELECT
	smoker, 
	COUNT(*) AS smokers_count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS smokers_percentage
FROM st_consumers_
GROUP BY smoker
ORDER BY smokers_count DESC;

-- Drink level
SELECT 
	drink_level,
	COUNT(*) AS num_drinkers,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS drinkers_percentage
FROM st_consumers
GROUP BY drink_level
ORDER BY num_drinkers DESC;

-- Occupation
SELECT 
    occupation,
    COUNT(*) AS consumers_occupation,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS occupation_percentage
FROM st_consumers
GROUP BY occupation
ORDER BY consumers_occupation DESC;

-- Q3: Demand and Supply Gap by Cuisine
-- Insight: Mexican cuisine shows the largest demand–supply gap, 
-- with high consumer interest but limited restaurant availability.
-- American and Pizzeria cuisines follow, indicating untapped market opportunities.
WITH supply AS (
    SELECT LOWER(rc.cuisine) AS cuisine,
           COUNT(*) AS num_restaurants
    FROM st_restaurant_cuisine_clean rc
    GROUP BY LOWER(rc.cuisine)
),
demand AS (
    SELECT LOWER(preferred_cuisine) AS preferred_cuisine,
           COUNT(*) AS num_consumers
    FROM st_consumer_preferences_clean
    GROUP BY LOWER(preferred_cuisine)
)
SELECT 
    d.preferred_cuisine,
    d.num_consumers,
    COALESCE(s.num_restaurants, 0) AS num_restaurants,
    d.num_consumers - COALESCE(s.num_restaurants, 0) AS cuisine_gap
FROM demand d
LEFT JOIN supply s
    ON d.preferred_cuisine = s.cuisine
ORDER BY d.num_consumers DESC;


-- Q4: Investment Recommendation - Top Performing Restaurants
-- Insight: Restaurant Las Mañanitas achieved the highest average overall rating,
-- offering high-priced international cuisine.
-- It is followed by Michiko (Japanese, medium price) and Emilianos (Brewery, low price).
-- Investors should focus on restaurants with consistently high service and food ratings,
-- ideally in cuisines with strong consumer demand.
SELECT
    r.restaurant_id,
    r.name,
	rc.cuisine,
    r.city,
    r.state,
    r.price,
    ROUND(AVG(rt.overall_rating), 2) AS avg_overall_rating,
    ROUND(AVG(rt.food_rating), 2) AS avg_food_rating,
    ROUND(AVG(rt.service_rating), 2) AS avg_service_rating,
    COUNT(DISTINCT cp.consumer_id) AS cuisine_demand_score
FROM st_restaurants_clean r
JOIN st_ratings_clean rt
    ON r.restaurant_id = rt.restaurant_id
JOIN st_restaurant_cuisine_clean rc
    ON r.restaurant_id = rc.restaurant_id
LEFT JOIN st_consumer_preferences_clean cp
    ON rc.cuisine = cp.preferred_cuisine
GROUP BY r.restaurant_id, r.name, r.city, r.state, r.price, rc.cuisine
ORDER BY avg_overall_rating DESC, avg_food_rating DESC, avg_service_rating DESC, cuisine_demand_score DESC
LIMIT 10;