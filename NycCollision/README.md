# NYC Motor Vehicle Collisions Analysis (Jan–Aug 2020)

This project analyzes **motor vehicle collisions reported by the New York City Police Department** from January to August 2020. The dataset includes individual collision records with information on **date, time, location (borough, zip code, street, latitude/longitude), vehicles and victims involved, and contributing factors**.  

The goal is to **clean, explore, and visualize the data** to answer questions about collision trends, high-risk times and locations, and causes of accidents.

---

## Dataset

The dataset was obtained from **Kaggle**:  
[Motor Vehicle Collisions - Crashes](https://www.kaggle.com/datasets/mysarahmadbhat/nyc-traffic-accidents)  

---

## Tools & Workflow

- **SQL (`Nyc.Collision.sql`)** – Querying and aggregating the raw dataset.  
- **Excel & Power Query (`NYC Collisions.xlsx`)** – Data cleaning, handling missing values, creating derived columns (Year, Month, Day, Hour, Vehicle Type, Fatal Flag), and pivot table analysis.  
- **Power BI (`Nyc.Collision.Dashboard.pbix`)** – Interactive visualizations of monthly trends, accident distribution by day/hour, top streets, borough hotspots, and vehicle type analysis.  
- **Visuals (`Nyc_Collision_Dashboard.png`)** – Snapshot image of the dashboard.  

*Workflow: SQL → Excel → Pivot Tables → Power BI → Visuals.*

---

## Key Insights

- **Monthly Trends:** Accidents peak in late spring and summer months (May–July).  
- **Time of Day / Day of Week:** Collisions occur most frequently during weekday afternoons (3–5 PM), with Friday being the highest.  
- **High-Risk Streets:** **Belt Parkway** had the highest number of collisions (3,728; 1.56% of total).  
- **Contributing Factors:** **Driver Inattention** is the leading cause, while **Unsafe Speed** is the top factor in multi-fatality crashes.  
- **Vehicle Type:** Most collisions involve **Passenger Vehicles (84.66%)**, while **Motorcycles and Scooters** have relatively higher fatalities per crash.  
- **Borough Distribution:** Brooklyn and Manhattan experience the highest number of collisions, visualized via map charts.  

---

## Project Files

- **Nyc.Collision.sql** – SQL queries for filtering and aggregating data.  
- **NYC Collisions.xlsx** – Cleaned dataset and pivot table analysis.  
- **Nyc.Collision.Dashboard.pbix** – Power BI dashboard with interactive visualizations.  
- **Nyc_Collision_Dashboard.png** – Image snapshot of the dashboard.

---

## How to Use

1. Open **NYC Collisions.xlsx** to explore the cleaned dataset and pivot table analyses.  
2. Run queries in **Nyc.Collision.sql** for custom filtering or aggregations.  
3. Open **Nyc.Collision.Dashboard.pbix** in Power BI to interact with visualizations.  
4. View **Nyc_Collision_Dashboard.png** for a snapshot of the dashboard.
