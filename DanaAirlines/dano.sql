-- Created the main table for raw survey data
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

-- Created a working copy / staging table
CREATE TABLE st_dano_airline AS
SELECT *
FROM dano_airline;

-- Remove duplicates based on all columns (keeping one copy per ID)
WITH dup AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY ID
               ORDER BY gender, age, customer_type, type_of_travel, class,
                        flight_distance, departure_delay, arrival_delay,
                        departure_arrival_time_convenience, ease_of_online_booking,
                        check_in_service, online_boarding, gate_location, on_board_service,
                        seat_comfort, leg_room_service, cleanliness, food_and_drink,
                        in_flight_service, in_flight_wifi_service, in_flight_entertainment,
                        baggage_handling, satisfaction
           ) AS rn
    FROM st_dano_airline
)
DELETE FROM dup
WHERE rn > 1;

-- Data Standardization
-- Checked for NULLS; Only arrival_delay had NULL values
SELECT *
FROM st_dano_airline
WHERE arrival_delay IS NULL;

-- Data Exploration
-- Average delays and service ratings by satisfaction
SELECT 
    CASE 
        WHEN satisfaction LIKE '%Satisfied%' THEN 'Satisfied'
        ELSE 'Unsatisfied'
    END AS sat_group,
    ROUND(AVG(departure_delay),2) AS avg_departure_delay,
    ROUND(AVG(arrival_delay),2) AS avg_arrival_delay,
    ROUND(AVG(departure_arrival_time_convenience),2) AS avg_dep_arr_time_convenience,
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
FROM st_dano_airline
GROUP BY 
    CASE 
        WHEN satisfaction LIKE '%Satisfied%' THEN 'Satisfied'
        ELSE 'Unsatisfied'
    END
ORDER BY sat_group DESC;

-- Operational Experience: Average delays only
SELECT 
    CASE 
        WHEN satisfaction LIKE '%Satisfied%' THEN 'Satisfied'
        ELSE 'Unsatisfied'
    END AS sat_group,
    ROUND(AVG(departure_delay),2) AS avg_departure_delay,
    ROUND(AVG(arrival_delay),2) AS avg_arrival_delay
FROM st_dano_airline
GROUP BY 
    CASE 
        WHEN satisfaction LIKE '%Satisfied%' THEN 'Satisfied'
        ELSE 'Unsatisfied'
    END;