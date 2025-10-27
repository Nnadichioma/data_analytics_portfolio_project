# Dano Airlines Passenger Satisfaction Analysis

This project investigates **over 120,000 passenger survey records for Dano Airlines**, a UK-based airline headquartered in London. The dataset includes information on **passenger demographics, flight details, travel type, class, delays, and ratings for various aspects of the flight experience**.  

The goal is to **clean, analyze, and visualize the data** to identify key drivers of passenger satisfaction and provide **data-driven recommendations** to improve service.

---

## Dataset

The dataset was obtained from **Kaggle**:  
[Dano Airlines Passenger Satisfaction (MavenAnalytics)](https://mavenanalytics.io/data-playground/airline-passenger-satisfaction)

---

## Tools & Workflow

- **Excel (`DanaAirline/`)** – Data cleaning, handling missing values, creating derived columns (age brackets, delay bins, satisfaction categories), and pivot table analysis.  
- **SQL (`Dana_Airline/`)** – Queries for analyzing flight delays, passenger satisfaction, demographics, and overall trends.  
- **Power BI (`DanaAirline/`)** – Interactive dashboards showing KPIs, delay vs satisfaction, demographics, and class-based analysis.  
- **Visuals (`Dana_Airline_Dashboard/`)** – Snapshot image of the Power BI dashboard.

*Workflow: SQL → Excel → Pivot Tables → Power BI → Visuals.*

---

## Key Insights

- **Satisfaction Trends:** On-time flights have the **highest satisfaction**, while severe delays significantly reduce satisfaction rates.  
- **Passenger Demographics:** Majority of passengers are **young adults**, **students**, and **unmarried**, which may indicate sample bias.  
- **Travel Type & Class:** Business and loyal customers show higher satisfaction compared to Economy and first-time travelers.  
- **Improvement Opportunities:** Key areas for enhancement include **departure/arrival time convenience, in-flight service, and online booking experience**.  
- **Recommendations:** Focus on reducing delays, improving check-in and boarding services, and enhancing in-flight comfort to increase overall satisfaction.

---

## Project Files

- **DanaAirline/** – Excel workflows for cleaning and pivot analysis.  
- **Dana_Airline/** – SQL scripts for querying and aggregating passenger satisfaction data.  
- **DanaAirline/** – Power BI dashboards with interactive visuals and KPIs.  
- **Dana_Airline_Dashboard/** – Image snapshot of the dashboard.

---

## How to Use

1. Explore the cleaned dataset and pivot tables in **DanaAirline/** (Excel).  
2. Run queries in **Dana_Airline/** (SQL) to generate custom insights.  
3. Open **DanaAirline/** (Power BI) to interact with dashboards and KPIs.  
4. View **Dana_Airline_Dashboard/** for a snapshot of the visualizations.
