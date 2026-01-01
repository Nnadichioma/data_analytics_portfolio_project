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

# Q1. How many patients have been admitted or readmitted over time?

# Sort by patient and admission date
enc = enc.sort_values(['PATIENT', 'START'])

# Identify readmissions (any admission after the first for the patient)
enc['previous_admission'] = enc.groupby('PATIENT')['START'].shift(1)
enc['is_readmission'] = enc['previous_admission'].notnull()

# Extract year-month for monthly aggregation
enc['year_month'] = enc['START'].dt.to_period('M').dt.to_timestamp()

# Monthly unique patients admitted
monthly_unique_admissions = (
    enc.groupby('year_month')['PATIENT']
       .nunique()
       .reset_index(name='unique_patients_admitted')
)

# Monthly unique readmitted patients
monthly_unique_readmissions = (
    enc[enc['is_readmission']]
       .groupby('year_month')['PATIENT']
       .nunique()
       .reset_index(name='unique_patients_readmitted')
)

# Display top rows
print(monthly_unique_admissions.head())
print(monthly_unique_readmissions.head())


# Plot Admissions vs Readmissions per month

plt.figure(figsize=(12,6))

sns.lineplot(
    data=monthly_unique_admissions,
    x='year_month',
    y='unique_patients_admitted',
    marker='o',
    color='blue',
    linewidth=2,
    label='Admissions'
)

sns.lineplot(
    data=monthly_unique_readmissions,
    x='year_month',
    y='unique_patients_readmitted',
    marker='o',
    color='red',
    linewidth=2,
    label='Readmissions'
)

plt.title('Unique Patients: Admissions vs Readmissions per Month')
plt.xlabel('Month')
plt.ylabel('Number of Patients')
plt.xticks(rotation=45)

ax = plt.gca()
ax.xaxis.set_major_locator(mdates.MonthLocator(interval=6))  # every 6 months
ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))

plt.legend()
plt.tight_layout()
plt.show()


# -----------------------------
# Graph 2: Yearly Admissions & Readmissions (overview)
# -----------------------------
# Aggregate by year
monthly_unique_admissions['year'] = monthly_unique_admissions['year_month'].dt.year
monthly_unique_readmissions['year'] = monthly_unique_readmissions['year_month'].dt.year

yearly_admissions = monthly_unique_admissions.groupby('year')['unique_patients_admitted'].sum().reset_index()
yearly_readmissions = monthly_unique_readmissions.groupby('year')['unique_patients_readmitted'].sum().reset_index()

plt.figure(figsize=(10,5))

sns.barplot(
    data=yearly_admissions,
    x='year',
    y='unique_patients_admitted',
    color='blue',
    label='Admissions'
)

sns.barplot(
    data=yearly_readmissions,
    x='year',
    y='unique_patients_readmitted',
    color='red',
    label='Readmissions'
)

plt.title('Unique Patients: Admissions vs Readmissions per Year')
plt.xlabel('Year')
plt.ylabel('Number of Patients')
plt.legend()
plt.tight_layout()
plt.show()

# How much is the average cost per visit? 

# How many procedures are covered by insurance?
