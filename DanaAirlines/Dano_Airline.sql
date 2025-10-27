-- Create main table for raw survey data

CREATE TABLE dano_airline (
    ID INT PRIMARY KEY,
    gender VARCHAR(10),
    age INT,
    customer_type VARCHAR(50),
    type_of_travel VARCHAR(25),
    class VARCHAR(30),
    flight_distance INT,
    departure_delay INT,
    arrival_delay INT,
    departure_arrival_time_convenience TINYINT,
    ease_of_online_booking TINYINT,
    check_in_service TINYINT,
    online_boarding TINYINT,
    gate_location TINYINT,
    on_board_service TINYINT,
    seat_comfort TINYINT,
    leg_room_service TINYINT,
    cleanliness TINYINT,
    food_and_drink TINYINT,
    in_flight_service TINYINT,
    in_flight_wifi_service TINYINT,
    in_flight_entertainment TINYINT,
    baggage_handling TINYINT,
    satisfaction VARCHAR(30)
);

-- Verify table importation using SELECT * FROM dano_airline;

-- Create staging table (working copy)
DROP TABLE IF EXISTS st_dano_airline;

CREATE TABLE st_dano_airline AS
SELECT *
FROM dano_airline;

-- Remove duplicates
CREATE TABLE st_dano_airlines_clean AS
WITH dup AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY ID
               ORDER BY gender, age, customer_type, type_of_travel, class,
                        flight_distance, departure_delay, arrival_delay,
                        departure_and_arrival_time_convenience, ease_of_online_booking,
                        check_in_service, online_boarding, gate_location, on_board_service,
                        seat_comfort, leg_room_service, cleanliness, food_and_drink,
                        in_flight_service, in_flight_wifi_service, in_flight_entertainment,
                        baggage_handling, satisfaction
           ) AS rn
    FROM st_dano_airline
)
SELECT *
FROM dup
WHERE rn = 1;

-- Verify SELECT * FROM st_dano_airlines_clean;

-- Check for NULL values

SELECT *
FROM st_dano_airlines_clean
WHERE arrival_delay IS NULL;

-- Standardize satisfaction group
ALTER TABLE st_dano_airlines_clean
ADD sat_group VARCHAR(20);

UPDATE st_dano_airlines_clean
SET sat_group = CASE 
                    WHEN satisfaction LIKE '%Satisfied%' THEN 'Satisfied'
                    ELSE 'Unsatisfied'
                END;

-- Data Exploration
-- Summary stats by satisfaction group
SELECT 
    sat_group,
    ROUND(AVG(departure_delay),2) AS avg_departure_delay,
    ROUND(AVG(arrival_delay),2) AS avg_arrival_delay,
    ROUND(AVG(departure_and_arrival_time_convenience),2) AS avg_dep_arr_time_convenience,
    ROUND(AVG(ease_of_online_booking),2) AS avg_online_booking,
    ROUND(AVG(check_in_service),2) AS avg_check_in,
    ROUND(AVG(online_boarding),2) AS avg_online_boarding,
    ROUND(AVG(gate_location),2) AS avg_gate_location,
    ROUND(AVG(on_board_service),2) AS avg_onboard_service,
    ROUND(AVG(seat_comfort),2) AS avg_seat_comfort,
    ROUND(AVG(leg_room_service),2) AS avg_leg_room,
    ROUND(AVG(cleanliness),2) AS avg_cleanliness,
    ROUND(AVG(food_and_drink),2) AS avg_food,
    ROUND(AVG(in_flight_service),2) AS avg_inflight_service,
    ROUND(AVG(in_flight_wifi_service),2) AS avg_wifi,
    ROUND(AVG(in_flight_entertainment),2) AS avg_entertainment,
    ROUND(AVG(baggage_handling),2) AS avg_baggage
FROM st_dano_airlines_clean
GROUP BY sat_group
ORDER BY sat_group DESC;

-- Top drivers of dissatisfaction
-- Rank factors by difference in mean scores between satisfied and unsatisfied
WITH 
s AS (
    SELECT 
        AVG(departure_and_arrival_time_convenience) AS dep_arr_time_convenience,
        AVG(ease_of_online_booking) AS online_booking,
        AVG(check_in_service) AS check_in,
        AVG(online_boarding) AS online_boarding,
        AVG(gate_location) AS gate_location,
        AVG(on_board_service) AS onboard_service,
        AVG(seat_comfort) AS seat_comfort,
        AVG(leg_room_service) AS leg_room,
        AVG(cleanliness) AS cleanliness,
        AVG(food_and_drink) AS food,
        AVG(in_flight_service) AS inflight_service,
        AVG(in_flight_wifi_service) AS wifi,
        AVG(in_flight_entertainment) AS entertainment,
        AVG(baggage_handling) AS baggage
    FROM st_dano_airlines_clean
    WHERE sat_group = 'Satisfied'
),
u AS (
    SELECT 
        AVG(departure_and_arrival_time_convenience) AS dep_arr_time_convenience,
        AVG(ease_of_online_booking) AS online_booking,
        AVG(check_in_service) AS check_in,
        AVG(online_boarding) AS online_boarding,
        AVG(gate_location) AS gate_location,
        AVG(on_board_service) AS onboard_service,
        AVG(seat_comfort) AS seat_comfort,
        AVG(leg_room_service) AS leg_room,
        AVG(cleanliness) AS cleanliness,
        AVG(food_and_drink) AS food,
        AVG(in_flight_service) AS inflight_service,
        AVG(in_flight_wifi_service) AS wifi,
        AVG(in_flight_entertainment) AS entertainment,
        AVG(baggage_handling) AS baggage
    FROM st_dano_airlines_clean
    WHERE sat_group = 'Unsatisfied'
)
SELECT *
FROM (
    SELECT 
        'Departure & Arrival Convenience' AS factor, s.dep_arr_time_convenience - u.dep_arr_time_convenience AS diff
    FROM s CROSS JOIN u
    UNION ALL
    SELECT 'Ease of Online Booking', s.online_booking - u.online_booking FROM s CROSS JOIN u
    UNION ALL
    SELECT 'Check-In Service', s.check_in - u.check_in FROM s CROSS JOIN u
    UNION ALL
    SELECT 'Online Boarding', s.online_boarding - u.online_boarding FROM s CROSS JOIN u
    UNION ALL
    SELECT 'Gate Location', s.gate_location - u.gate_location FROM s CROSS JOIN u
    UNION ALL
    SELECT 'Onboard Service', s.onboard_service - u.onboard_service FROM s CROSS JOIN u
    UNION ALL
    SELECT 'Seat Comfort', s.seat_comfort - u.seat_comfort FROM s CROSS JOIN u
    UNION ALL
    SELECT 'Leg Room', s.leg_room - u.leg_room FROM s CROSS JOIN u
    UNION ALL
    SELECT 'Cleanliness', s.cleanliness - u.cleanliness FROM s CROSS JOIN u
    UNION ALL
    SELECT 'Food & Drink', s.food - u.food FROM s CROSS JOIN u
    UNION ALL
    SELECT 'In-flight Service', s.inflight_service - u.inflight_service FROM s CROSS JOIN u
    UNION ALL
    SELECT 'WiFi', s.wifi - u.wifi FROM s CROSS JOIN u
    UNION ALL
    SELECT 'Entertainment', s.entertainment - u.entertainment FROM s CROSS JOIN u
    UNION ALL
    SELECT 'Baggage Handling', s.baggage - u.baggage FROM s CROSS JOIN u
) AS comparison
ORDER BY diff DESC;


-- Departure Delay vs Satisfaction
SELECT
  CASE 
    WHEN Departure_Delay = 0 THEN 'On-time'
    WHEN Departure_Delay <= 15 THEN 'Short'
    WHEN Departure_Delay <= 60 THEN 'Moderate'
    ELSE 'Severe' 
  END AS dep_delay_bucket,
  COUNT(*) AS total_passengers,
  SUM(CASE WHEN Satisfaction = 'Satisfied' THEN 1 ELSE 0 END) AS satisfied_passengers,
  SUM(CASE WHEN Satisfaction <> 'Satisfied' THEN 1 ELSE 0 END) AS unsatisfied_passengers,
  ROUND(SUM(CASE WHEN Satisfaction = 'Satisfied' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_satisfied
FROM st_dano_airlines_clean
GROUP BY dep_delay_bucket
ORDER BY pct_satisfied DESC;


-- Arrival Delay vs Satisfaction
SELECT
  CASE 
    WHEN arrival_delay = 0 THEN 'On-time'
    WHEN arrival_delay <= 15 THEN 'Short'
    WHEN arrival_delay <= 60 THEN 'Moderate'
    WHEN arrival_delay IS NULL THEN 'Unknown'
    ELSE 'Severe' 
  END AS arr_delay_bucket,
  COUNT(*) AS total_passengers,
  SUM(CASE WHEN TRIM(LOWER(Satisfaction)) = 'satisfied' THEN 1 ELSE 0 END) AS satisfied_passengers,
  SUM(CASE WHEN TRIM(LOWER(Satisfaction)) <> 'satisfied' THEN 1 ELSE 0 END) AS unsatisfied_passengers,
  ROUND(SUM(CASE WHEN TRIM(LOWER(Satisfaction)) = 'satisfied' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_satisfied
FROM st_dano_airlines_clean
GROUP BY arr_delay_bucket
ORDER BY pct_satisfied DESC;