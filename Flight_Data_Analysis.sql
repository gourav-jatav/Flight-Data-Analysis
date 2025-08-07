USE airport_database;

-- QUERY 1: ROUTE PASSENGER VOLUME ANALYSIS
-- Calculates total passengers for each origin-destination airport pair
-- Results are ordered by passenger volume in descending order
SELECT 
    origin_airport, 
    destination_airport, 
    SUM(passengers) AS total_passengers
FROM 
    AirportData
GROUP BY 
    destination_airport, 
    origin_airport
ORDER BY 
    SUM(passengers) DESC; 

-- QUERY 2: SEAT UTILIZATION ANALYSIS
-- Calculates average seat utilization percentage for each flight route
-- Shows which routes have the highest percentage of seats filled
SELECT 
    origin_airport, 
    destination_airport, 
    AVG(CAST(passengers AS FLOAT) / NULLIF(seats, 0)) * 100 AS average_seat_utilization
FROM 
    AirportData
GROUP BY 
    destination_airport, 
    origin_airport
ORDER BY 
    average_seat_utilization DESC; 

-- QUERY 3: TOP BUSIEST ROUTES
-- Identifies the top 3 busiest routes based on total passenger volume
SELECT 
    origin_airport, 
    destination_airport, 
    SUM(passengers) AS total_passengers
FROM 
    AirportData
GROUP BY 
    destination_airport, 
    origin_airport
ORDER BY 
    total_passengers DESC
LIMIT 3; 

-- QUERY 4: CITY FLIGHT ACTIVITY OVERVIEW
-- First shows sample data (2 rows) for reference
SELECT * FROM airportdata LIMIT 2;

-- Main query showing total flights and passengers by origin city
SELECT 
    SUM(flights) AS total_flights, 
    SUM(passengers) AS total_passengers, 
    origin_city
FROM 
    airportdata
GROUP BY 
    origin_city
ORDER BY 
    total_passengers DESC;

-- QUERY 5: DISTANCE ANALYSIS BY CITY
-- Calculates total distance flown by aircraft originating from each city
SELECT 
    origin_city, 
    SUM(Distance) AS total_distance
FROM 
    airportdata
GROUP BY 
    origin_city
ORDER BY 
    total_distance DESC;

-- QUERY 6: MONTHLY ROUTE PERFORMANCE
-- Analyzes passenger volume by route broken down by month and year
SELECT 
    origin_airport, 
    destination_airport, 
    YEAR(fly_date) AS year, 
    MONTH(fly_date) AS month, 
    SUM(Flights) AS total_flights, 
    SUM(passengers) AS total_passengers 
FROM 
    AirportData
GROUP BY 
    origin_airport, 
    destination_airport,  
    YEAR(fly_date), 
    MONTH(fly_date)
ORDER BY 
    SUM(passengers) DESC;

-- QUERY 7: UNDERPERFORMING FLIGHT ROUTES
-- Identifies routes with consistently low seat utilization (<50%)
SELECT 
    origin_airport, 
    destination_airport, 
    AVG((passengers * 0.1)/NULLIF(seats,0)) AS underperforming_flights
FROM 
    airportdata
GROUP BY 
    origin_airport, 
    destination_airport
HAVING 
    (AVG((passengers)/(seats))) < 0.5
ORDER BY 
    underperforming_flights ASC;

-- QUERY 8: BUSIEST ORIGIN AIRPORTS
-- Finds top 3 airports by number of departing flights
SELECT 
    origin_airport, 
    SUM(flights) AS total_flights
FROM 
    airportdata
GROUP BY 
    origin_airport
ORDER BY 
    SUM(flights) DESC
LIMIT 3;

-- QUERY 9: TOP CITIES CONNECTING TO BEND, OR
-- Identifies the top 3 origin cities (excluding Bend itself) with most flights to Bend, OR
SELECT 
    origin_city,
    COUNT(flights) AS total_flights,
    SUM(passengers) AS total_passengers
FROM 
    airportdata
WHERE 
    destination_city = 'Bend, OR' AND
    origin_city <> 'Bend, OR'
GROUP BY 
    origin_city
ORDER BY 
    total_flights DESC,
    total_passengers DESC
LIMIT 3;

-- QUERY 10: LONGEST FLIGHT ROUTES ANALYSIS
-- Approach 1: Uses subquery to find maximum flight distance
SELECT MAX(max_dist) FROM (
    SELECT 
        origin_airport, 
        destination_airport, 
        MAX(distance) AS max_dist
    FROM 
        airportdata
    GROUP BY 
        origin_airport, 
        destination_airport
) AS maxx;

-- Approach 2: Directly finds the single longest route
SELECT 
    origin_airport, 
    destination_airport, 
    MAX(distance) AS max_distance
FROM 
    airportdata
GROUP BY 
    origin_airport, 
    destination_airport
ORDER BY 
    MAX(distance) DESC
LIMIT 1;

-- QUERY 10 CONTINUED: MONTHLY BUSYNESS CLASSIFICATION
-- Categorizes months as 'Most Busy' or 'Less Busy' based on flight volume
SELECT 
    MONTH(fly_date) AS month_num,
    SUM(flights) AS total_flights,
    CASE 
        WHEN SUM(flights) >= 340000 THEN 'Most Busy'
        ELSE 'Less Busy'
    END AS busy_label
FROM 
    airportdata
GROUP BY 
    MONTH(fly_date)
ORDER BY 
    total_flights DESC;

-- QUERY 11: PEAK AND VALLEY MONTHS IDENTIFICATION
-- Identifies the most and least busy months based on flight volume
WITH monthly_flights AS (
    SELECT 
        MONTH(fly_date) AS month, 
        SUM(flights) AS total_flights
    FROM 
        Airportdata
    GROUP BY 
        MONTH(fly_date)
)
SELECT 
    month, 
    total_flights,
    CASE
        WHEN total_flights = (SELECT MAX(total_flights) FROM monthly_flights) THEN 'Most_Busy'
        WHEN total_flights = (SELECT MIN(total_flights) FROM monthly_flights) THEN 'Least_Busy'
        ELSE NULL
    END AS status
FROM 
    monthly_flights
WHERE 
    total_flights = (SELECT MAX(total_flights) FROM monthly_flights) OR
    total_flights = (SELECT MIN(total_flights) FROM monthly_flights);
    
-- QUERY 12: YEAR-OVER-YEAR PASSENGER GROWTH
-- Analyzes passenger growth trends by route with percentage change calculations
WITH yearly_data AS (    
    SELECT 
        origin_airport, 
        destination_airport, 
        YEAR(fly_date) AS year, 
        SUM(passengers) AS total_passengers
    FROM 
        airportdata
    GROUP BY 
        origin_airport, 
        destination_airport, 
        YEAR(fly_date)
),
passenger_growth AS (
    SELECT 
        origin_airport, 
        destination_airport, 
        year, 
        total_passengers,
        LAG(total_passengers) OVER(PARTITION BY origin_airport, destination_airport ORDER BY year) AS previous_years
    FROM 
        yearly_data
)
SELECT 
    origin_airport, 
    destination_airport, 
    year,  
    total_passengers, 
    CASE
        WHEN previous_years IS NOT NULL THEN ((total_passengers/ previous_years)*100)
    END AS percent_change,
    CASE
        WHEN total_passengers > previous_years THEN 'Increase'
        WHEN total_passengers < previous_years THEN 'Decrease'
    END AS status
FROM 
    passenger_growth
WHERE 
    total_passengers > previous_years;

-- QUERY 13: FLIGHT GROWTH RATE ANALYSIS
-- Calculates growth rates for flights by route with min/max growth metrics
WITH flight_summary AS (
    SELECT 
        origin_airport, 
        destination_airport,
        YEAR(fly_date) AS year,
        SUM(flights) AS total_flights
    FROM 
        airportdata
    GROUP BY
        origin_airport, 
        destination_airport,
        YEAR(fly_date)
),
flight_growth AS ( 
    SELECT 
        origin_airport, 
        destination_airport,
        year,
        total_flights,
        LAG(total_flights) OVER (PARTITION BY origin_airport, destination_airport ORDER BY year) AS previous_year_flights
    FROM 
        flight_summary
),
growth_rates AS (
    SELECT 
        origin_airport, 
        destination_airport,
        year,
        total_flights,
        previous_year_flights,
        CASE
            WHEN (previous_year_flights IS NOT NULL AND previous_year_flights != 0) 
            THEN ((total_flights-previous_year_flights)*100/previous_year_flights)
            ELSE NULL
        END AS growth_rate,
        CASE 
            WHEN (previous_year_flights IS NOT NULL AND total_flights > previous_year_flights) THEN 1
            ELSE 0
        END AS growth_indicator
    FROM 
        flight_growth
)       
SELECT 
    origin_airport, 
    destination_airport,
    MIN(growth_rate) AS min_growth_rate,
    MAX(growth_rate) AS max_growth_rate
FROM 
    growth_rates
WHERE
    growth_indicator = 1
GROUP BY
    origin_airport, 
    destination_airport;
    
-- QUERY 14: WEIGHTED SEAT UTILIZATION
-- Calculates weighted seat utilization metrics to identify most efficiently used airports
WITH utilization_ratio AS (
    SELECT
        origin_airport,
        SUM(passengers) AS total_passengers,
        SUM(seats) AS total_seats,
        SUM(flights) AS total_flights,
        (SUM(passengers)*0.1)/(SUM(seats)) AS passengers_seat_ratio
    FROM 
        airportdata
    GROUP BY 
        origin_airport
),
weighted_utilization AS ( 
    SELECT
        origin_airport,
        total_passengers,
        total_seats,
        total_flights,
        passengers_seat_ratio,
        (passengers_seat_ratio * total_seats)/SUM(total_seats) OVER() AS weighted_utilization
    FROM 
        utilization_ratio
)
SELECT
    origin_airport,
    total_passengers,
    total_seats,
    total_flights,
    weighted_utilization
FROM 
    weighted_utilization
ORDER BY 
    weighted_utilization DESC
LIMIT 3;
    
-- QUERY 15: PEAK PASSENGER MONTHS
-- Identifies the peak month for each city based on passenger volume
WITH monthly_passenger_count AS (
    SELECT 
        origin_city,
        YEAR(fly_date) AS year,
        MONTH(fly_date) AS month,
        SUM(passengers) AS total_passengers
    FROM 
        airportdata
    GROUP BY 
        origin_city,
        YEAR(fly_date),
        MONTH(fly_date)
),
max_passenger_count AS (
    SELECT 
        origin_city,
        MAX(total_passengers) AS peak_passengers
    FROM 
        monthly_passenger_count
    GROUP BY 
        origin_city
)
SELECT 
    mpc.origin_city,
    mpc.year, 
    mpc.month,
    mpc.total_passengers
FROM 
    monthly_passenger_count AS mpc
JOIN 
    max_passenger_count AS mp
    ON mpc.origin_city = mp.origin_city 
    AND mpc.total_passengers = mp.peak_passengers
ORDER BY 
    mpc.origin_city,
    mpc.year DESC,
    mpc.month;

-- QUERY 16: DECLINING ROUTES ANALYSIS
-- Identifies routes with year-over-year passenger declines
WITH yearly_airport AS (
    SELECT 
        origin_airport, 
        destination_airport,
        YEAR(fly_date) AS year,
        SUM(passengers) AS total_passengers
    FROM 
        airportdata
    GROUP BY
        origin_airport, 
        destination_airport,
        YEAR(fly_date)
),
yearly_decline AS (
    SELECT 		
        y1.origin_airport AS o_airport, 
        y1.destination_airport AS d_airport,
        y1.year AS current_year,
        y1.total_passengers AS current_passengers,
        y2.year AS previous_year,
        y2.total_passengers AS previous_passengers,
        (y2.total_passengers-y1.total_passengers)*100/NULLIF(y1.total_passengers,0) AS percentage_change
    FROM 
        yearly_airport y1
    JOIN
        yearly_airport y2
        ON y1.origin_airport = y2.origin_airport 
        AND y1.destination_airport = y2.destination_airport 
        AND y1.year = y2.year+1
)
SELECT 
    o_airport, 
    d_airport,
    current_year,
    current_passengers,
    previous_year,
    previous_passengers,
    percentage_change
FROM 
    yearly_decline 
WHERE    
    percentage_change < 1;

-- QUERY 17: LOW UTILIZATION HIGH VOLUME AIRPORTS
-- Finds airports with high flight volume but low seat utilization
WITH utilization_ratio AS (
    SELECT 
        origin_airport,
        SUM(passengers) AS total_passengers,
        SUM(seats) AS total_seats,
        SUM(flights) AS total_flights,
        (SUM(passengers) * 1.0)*100 / SUM(seats) AS avg_seat_utilization_percentage
    FROM 
        airportdata
    GROUP BY 
        origin_airport
)
SELECT *
FROM 
    utilization_ratio
WHERE 
    total_flights >= 100 AND
    avg_seat_utilization_percentage < 50
ORDER BY 
    avg_seat_utilization_percentage
LIMIT 5;    
    
-- QUERY 19: YEAR-OVER-YEAR FLIGHT CHANGES
-- Detailed analysis of changes in flights and passengers year-over-year
WITH year_data AS (
    SELECT	
        origin_airport,
        destination_airport,
        YEAR(fly_date) AS year,
        SUM(flights) AS total_flights, 
        SUM(passengers) AS total_passengers
    FROM 
        airportdata
    GROUP BY
        origin_airport,
        destination_airport,
        YEAR(fly_date)
)
SELECT     
    cyd.origin_airport,
    cyd.destination_airport,
    cyd.year AS cur_year,
    cyd.total_flights, 
    cyd.total_passengers,
    pyd.year AS prev_year,
    pyd.total_flights, 
    pyd.total_passengers,
    ((cyd.total_flights-pyd.total_flights)*100)/pyd.total_flights AS percentage_change_flights,
    COALESCE(((cyd.total_passengers - pyd.total_passengers) * 100) / NULLIF(pyd.total_passengers, 0), 0) AS percentage_change_passengers
FROM 
    year_data cyd
JOIN 
    year_data pyd
    ON cyd.origin_airport = pyd.origin_airport 
    AND cyd.destination_airport = pyd.destination_airport 
    AND cyd.year = pyd.year+1
LIMIT 30
OFFSET 31; 

-- QUERY 20: WEIGHTED DISTANCE METRICS
-- Calculates weighted distance metrics to identify most significant routes
WITH route_flights AS (
    SELECT 
        origin_airport, 
        destination_airport,
        SUM(flights) AS total_flights,
        SUM(distance) AS total_distance
    FROM 
        airportdata
    GROUP BY 
        origin_airport,
        destination_airport
)
SELECT  
    origin_airport, 
    destination_airport,
    total_flights,
    total_distance,
    total_flights * total_distance AS weighted_distance
FROM 
    route_flights
GROUP BY 
    origin_airport,
    destination_airport
ORDER BY 
    weighted_distance DESC
LIMIT 10;
