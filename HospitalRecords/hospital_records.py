import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

# Load dataset
encounters = pd.read_csv('encounters.csv')

# Understand the dataset
encounters.info()           # column info, non-null counts
print(encounters.shape)     # number of rows and columns
print(encounters.dtypes)    # column data types
print(encounters.head())    # first 5 rows
print(encounters.tail())    # last 5 rows
print(encounters.describe())# summary stats for numeric columns

# Check for missing values
missing_values = encounters.isnull().sum().sum()
print(missing_values)

# Get information about missing values per column
# Drop column (REASONCODE) with most missing values
encounters = encounters.drop(columns="REASONCODE")

# Fill missing values in REASONDESCRIPTION with 'Unknown'
encounters["REASONDESCRIPTION"] = encounters["REASONDESCRIPTION"].fillna("Unknown")
print(encounters.head())
encounters.info()
encounters = encounters.drop_duplicates()

# convert start and stop columns to datetime
encounters["START"] = pd.to_datetime(encounters["START"])
encounters["STOP"] = pd.to_datetime(encounters["STOP"])
print(encounters.dtypes)

# Load and understand second dataset
patients = pd.read_csv("patients.csv")
patients.info()
print(patients.shape)
print(patients.head())
print(patients.tail())

# Check for missing values in second dataset
missing_values_2 = patients.isnull().sum().sum()
print(missing_values_2)

# Convert BIRTHDATE AND DEATHDATE TO DATETIME
patients["BIRTHDATE"] = pd.to_datetime(patients["BIRTHDATE"])
patients["DEATHDATE"] = pd.to_datetime(patients["DEATHDATE"])
patients.info()

# Drop and Fill Missing Values
patients = patients.drop(columns="SUFFIX")
patients[["MAIDEN", "MARITAL"]] = patients[["MAIDEN", "MARITAL"]].fillna("Unknown")
patients["ZIP"] = patients["ZIP"].astype("Int64")   # first convert float → integer
patients["ZIP"] = patients["ZIP"].astype("string")  # then integer → string
patients["ZIP"] = patients["ZIP"].fillna("Unknown")
patients.info()

# Check for Duplicates
patients = patients.drop_duplicates()

# Load third dataset
procedures = pd.read_csv("procedures.csv")
procedures.info()
print(procedures.shape)
print(procedures.head())
print(procedures.tail())

# Check for missing values in third dataset
missing_values_3 = procedures.isnull().sum().sum()
print(missing_values_3)

# Drop and Fill with most missing values
procedures = procedures.drop(columns="REASONCODE")
procedures["REASONDESCRIPTION"] = procedures["REASONDESCRIPTION"].fillna("Unknown")
procedures = procedures.drop_duplicates()
procedures.info()

# Convert START AND STOP to Datetime
procedures["START"] = pd.to_datetime(procedures["START"])
procedures["STOP"] = pd.to_datetime(procedures["STOP"])
procedures.info()

# Load fourth dataset
payers = pd.read_csv("payers.csv")
payers.info()
print(payers.shape)
print(payers.head())
print(payers.tail())

# Check for missing values in fourth dataset
missing_values_4 = payers.isnull().sum().sum()
print(missing_values_4)

# Drop and Fill with most missing values
payers["ADDRESS"] = payers["ADDRESS"].fillna("Unknown")
payers["CITY"] = payers["CITY"].fillna("Unknown")
payers["STATE_HEADQUARTERED"] = payers["STATE_HEADQUARTERED"].fillna("Unknown")
payers["PHONE"] = payers["PHONE"].fillna("Unknown")

# Convert ZIP to string and fill missing
payers["ZIP"] = payers["ZIP"].astype("Int64").astype("string").fillna("Unknown")

# Check for duplicates
payers = payers.drop_duplicates()
payers.info()

# Load fifth dataset
organizations = pd.read_csv("organizations.csv")
organizations.info()
print(organizations.shape)
print(organizations.head())
print(organizations.tail())

# Check for missing values in fifth dataset
missing_values_5 = organizations.isnull().sum().sum()
print(missing_values_5)

# Convert ZIP to string
organizations["ZIP"] = organizations["ZIP"].astype("string")
organizations.info()

# All datasets are now cleaned and prepped for analysis.
#SAVE CLEANED DATASETS
encounters.to_csv('cleaned_encounters.csv', index=False)
patients.to_csv('cleaned_patients.csv', index=False)
procedures.to_csv('cleaned_procedures.csv', index=False)
payers.to_csv('cleaned_payers.csv', index=False)
organizations.to_csv('cleaned_organizations.csv', index=False)

# The cleaned datasets are saved as new CSV files for future analysis.
# Data Exploration
# Load cleaned datasets
enc = pd.read_csv('cleaned_encounters.csv', parse_dates=['START', 'STOP'])
pat = pd.read_csv('cleaned_patients.csv', parse_dates=['BIRTHDATE', 'DEATHDATE'])
proc = pd.read_csv('cleaned_procedures.csv', parse_dates=['START', 'STOP'])
pay = pd.read_csv('cleaned_payers.csv', dtype={'ZIP': 'string'})
org = pd.read_csv('cleaned_organizations.csv', dtype={'ZIP': 'string'})
pat.info()
enc.info()

# Objective 1: Enconters Overview
# Q1a. How many total encounters occurred each year?

# Extract year from START
enc['YEAR'] = enc['START'].dt.year

# Total encounters per year
yearly_encounters = enc.groupby('YEAR').size().reset_index(name='TOTAL_ENCOUNTERS')
print(yearly_encounters)

# Visualization

# Line plot
plt.figure(figsize=(10, 6))
plt.plot(
    yearly_encounters['YEAR'],
    yearly_encounters['TOTAL_ENCOUNTERS'],
    marker='o'
)

plt.xticks(yearly_encounters['YEAR'])
plt.title('Total Encounters per Year')
plt.xlabel('Year')
plt.ylabel('Number of Encounters')
plt.grid(True)
plt.tight_layout()
plt.show()

# INSIGHT:
# Total encounters increased steadily from 2011 to 2014, peaking in 2014.
# After 2014, encounter volume declined gradually and then stabilized
# between 2016 and 2019, with a slight increase again in 2021.
# This suggests an initial growth phase in healthcare utilization
# followed by a period of stabilization.


# Q1b. For each year, what percentage of all encounters belonged to each encounter class
# (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?

yearly_encounter_class = enc.groupby(['YEAR', 'ENCOUNTERCLASS']).size().reset_index(name='COUNT')

# Calculate percentage within each year
yearly_encounter_class['PERCENTAGE'] = (
    yearly_encounter_class.groupby('YEAR')['COUNT']
    .transform(lambda x: 100 * x / x.sum())
)

print(yearly_encounter_class.head(10))

# sort by year and percentage
yearly_encounter_class = yearly_encounter_class.sort_values(['YEAR', 'PERCENTAGE'], ascending=[True, False])

# Visualization
# Pivot table for stacked bar
pivot = yearly_encounter_class.pivot(index='YEAR', columns='ENCOUNTERCLASS', values='PERCENTAGE').fillna(0)

# Plot
pivot.plot(kind='bar', stacked=True, figsize=(10,6), colormap='tab20')
plt.ylabel('Percentage of Encounters')
plt.title('Encounter Class Percentage per Year')
plt.legend(title='Encounter Class', bbox_to_anchor=(1.05,1), loc='upper left')
plt.tight_layout()
plt.show()

# INSIGHT:
# Ambulatory encounters consistently account for the largest share of
# encounters each year, representing roughly 40–50% of total encounters.
# Outpatient encounters are the second most common, contributing about
# 20–25% annually.
# Emergency and inpatient encounters make up a relatively small but
# stable proportion of total encounters, while wellness and urgent care
# visits vary moderately across years.
# Overall, the encounter mix indicates a strong emphasis on routine
# and non-emergency care.


# Q1c. What percentage of encounters were over 24 hours versus under 24 hours?

# Duration in hours
enc['duration_hours'] = (enc['STOP'] - enc['START']).dt.total_seconds() / 3600

# Categorize
enc['duration_category'] = enc['duration_hours'].apply(lambda x: 'Over 24 Hours' if x > 24 else 'Under 24 Hours')

# Percentage
duration_pct = enc['duration_category'].value_counts(normalize=True) * 100
print(duration_pct)

# Pie chart
plt.figure(figsize=(6,6))
plt.pie(duration_pct, labels=duration_pct.index, autopct='%1.1f%%', colors=['#66b3ff','#ff9999'])
plt.title('Percentage of Encounters Over vs Under 24 Hours')
plt.show()

# INSIGHT:
# The vast majority of encounters (over 99%) lasted less than 24 hours.
# Encounters exceeding 24 hours represent less than 1% of all visits,
# indicating that long hospital stays are rare in this dataset.
# This suggests that most patient interactions are short-term visits,
# such as outpatient, ambulatory, or same-day services.

# OBJECTIVE 2: COST & COVERAGE INSIGHTS
# Q2a. How many encounters had zero payer coverage, and what percentage of total encounters does this represent?

# Count encounters where payer coverage is 0
zero_coverage_count = (enc['PAYER_COVERAGE'] == 0).sum()

# Total encounters
total_encounters = len(enc)

# Percentage of total encounters
zero_coverage_pct = (zero_coverage_count / total_encounters) * 100

print(f"Encounters with zero coverage: {zero_coverage_count}")
print(f"Percentage of total encounters: {zero_coverage_pct:.2f}%")

# Insight:
# Out of all encounters, 13,586 (48.71%) had zero payer coverage.
# This indicates that nearly half of all healthcare encounters were not covered by insurance,
# suggesting a substantial burden of out-of-pocket costs or uninsured care within the dataset.


# Q2b. What are the top 10 most frequent procedures performed and the average base cost for each?

top_procedures = (
    proc
    .groupby('DESCRIPTION')
    .agg(
        frequency=('DESCRIPTION', 'count'),
        avg_base_cost=('BASE_COST', 'mean')
    )
    .sort_values(by='frequency', ascending=False)
    .head(10)
    .reset_index()
)

print(top_procedures)

# Visualization
plt.figure(figsize=(10,6))
sns.barplot(
    data=top_procedures,
    x='frequency',
    y='DESCRIPTION'
)
plt.title('Top 10 Most Frequent Procedures')
plt.xlabel('Number of Times Performed')
plt.ylabel('Procedure')
plt.tight_layout()
plt.show()

# Insight:
# The most frequently performed procedures are primarily routine assessments and screenings,
# such as health and social care assessments, depression screenings, and substance use evaluations.
# Most of these high-volume procedures have a relatively low and consistent average base cost (~$431),
# indicating standardized pricing for common preventive and diagnostic services.
# Renal dialysis stands out as a frequent procedure with a significantly higher average base cost,
# reflecting the higher resource intensity of this treatment.


# Q2c. What are the top 10 procedures with the highest average base cost and the number of times they were performed?

expensive_procedures = (
    proc
    .groupby('DESCRIPTION')
    .agg(
        avg_base_cost=('BASE_COST', 'mean'),
        frequency=('DESCRIPTION', 'count')
    )
    .sort_values(by='avg_base_cost', ascending=False)
    .head(10)
    .reset_index()
)

print(expensive_procedures)

# Visualization
plt.figure(figsize=(10,6))
sns.barplot(
    data=expensive_procedures,
    x='avg_base_cost',
    y='DESCRIPTION'
)
plt.title('Top 10 Most Expensive Procedures (Average Base Cost)')
plt.xlabel('Average Base Cost')
plt.ylabel('Procedure')
plt.tight_layout()
plt.show()

# Insight:
# The procedures with the highest average base cost are highly specialized and intensive treatments,
# such as ICU admission, coronary artery bypass grafting, and advanced cardiovascular interventions.
# Although these procedures occur far less frequently than routine assessments,
# their high individual costs contribute disproportionately to overall healthcare spending.
# Electrical cardioversion appears both high-cost and relatively frequent,
# making it a notable driver of total procedural expenditure.

# Q2d. What is the average total claim cost for encounters, broken down by payer?

avg_claim_by_payer = (
    enc.groupby('PAYER')['TOTAL_CLAIM_COST']
       .mean()
       .reset_index(name='avg_total_claim_cost')
       .sort_values(by='avg_total_claim_cost', ascending=False)
)

print(avg_claim_by_payer)

# Visualization

plt.figure(figsize=(10,6))

sns.barplot(
    data=avg_claim_by_payer.head(10),
    x='avg_total_claim_cost',
    y='PAYER'
)

plt.title('Top 10 Payers by Average Total Claim Cost')
plt.xlabel('Average Total Claim Cost')
plt.ylabel('Payer')
plt.tight_layout()
plt.show()

# Insight:
# Average total claim costs vary significantly by payer.
# The payer (Medicaid) with ID 7c4411ce-02f1-39b5-b9ec-dfbea9ad3c1a has the highest average total claim cost (~$6,205),
# indicating more expensive encounters or higher reimbursement rates.
# Several payers cluster between $2,500–$4,000, suggesting relatively similar cost structures.
# The lowest average total claim cost (~$1,696) may reflect coverage focused on less intensive or lower-cost care.
# Overall, payer type appears to play a meaningful role in total encounter costs.


# OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS
# Q3a. How many unique patients were admitted each quarter over time?

# Ensure START is datetime
enc['START'] = pd.to_datetime(enc['START'])

# Extract year-quarter
enc['YEAR'] = enc['START'].dt.year
enc['QUARTER'] = enc['START'].dt.to_period('Q')

# Count unique patients per quarter
patients_per_quarter = (
    enc.groupby('QUARTER')['PATIENT']
       .nunique()
       .reset_index(name='unique_patients')
)

print(patients_per_quarter)

# Visualization
plt.figure(figsize=(12,6))
plt.plot(
    patients_per_quarter['QUARTER'].astype(str),
    patients_per_quarter['unique_patients'],
    marker='o'
)
plt.xticks(rotation=45)
plt.title('Unique Patients Admitted per Quarter')
plt.xlabel('Quarter')
plt.ylabel('Number of Unique Patients')
plt.tight_layout()
plt.show()

# Insight:
# The number of unique patients admitted per quarter generally increases from 2011 through 2014,
# peaking around 2014, which may indicate expanded healthcare utilization or population growth.
# From 2015 to 2020, quarterly admissions remain relatively stable, fluctuating within a narrow range.
# A notable spike occurs in early 2021, followed by a decline toward 2022,
# which could reflect external factors such as healthcare disruptions or dataset coverage changes.
# Overall, admissions show long-term growth with short-term seasonal and annual variation.

# Q3b. How many patients were readmitted within 30 days of a previous encounter?

# Sort by patient and start time
enc = enc.sort_values(['PATIENT', 'START'])

# Previous encounter start date
enc['prev_start'] = enc.groupby('PATIENT')['START'].shift(1)

# Readmission within 30 days
enc['readmitted_30d'] = (
    (enc['START'] - enc['prev_start']).dt.days <= 30
)

# Count unique patients with at least one readmission
readmitted_patients = enc[enc['readmitted_30d']]['PATIENT'].nunique()

print("Number of patients readmitted within 30 days:", readmitted_patients)

# Insight:
# A total of 772 patients were readmitted within 30 days of a previous encounter.
# This indicates a non-trivial level of short-term readmissions,
# which may suggest chronic conditions, complications, or gaps in post-discharge care.
# Monitoring 30-day readmissions is important, as they are often used as a quality-of-care metric.


# Q3c. Which patients had the most readmissions?

top_readmissions = (
    enc[enc['readmitted_30d']]
    .groupby('PATIENT')
    .size()
    .reset_index(name='readmission_count')
    .sort_values(by='readmission_count', ascending=False)
    .head(10)
)

print(top_readmissions)

# Visualization
plt.figure(figsize=(10,6))

sns.barplot(
    data=top_readmissions,
    x='readmission_count',
    y='PATIENT'
)

plt.title('Top 10 Patients with Most Readmissions (Within 30 Days)')
plt.xlabel('Number of Readmissions')
plt.ylabel('Patient ID')
plt.tight_layout()
plt.show()

# Insight:
# A small number of patients account for a disproportionately high number of readmissions.
# The top patient experienced over 1,300 readmissions, far exceeding others.
# This concentration suggests the presence of high-utilization patients,
# potentially driven by chronic illness, long-term care needs, or frequent treatment regimens.
# Targeted care management or intervention programs for these patients could significantly reduce overall readmission volume.
