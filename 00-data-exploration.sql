-- View All Data (Only Countries, Not Continents)
SELECT *
FROM PortfolioProject..CovidDeathsMain
WHERE continent IS NOT NULL
ORDER BY location, date;


-- Select Key Columns for Analysis
SELECT 
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM PortfolioProject..CovidDeathsMain
WHERE continent IS NOT NULL
ORDER BY location, date;


-- Total Cases vs Total Deaths
-- Likelihood of dying if you contract COVID in Unites States as an Example

SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)) * 100 AS DeathPercentageRate
FROM PortfolioProject..CovidDeathsMain
WHERE location LIKE '%states%'
  AND continent IS NOT NULL
ORDER BY location, date;


-- Total Cases vs Population
-- Percentage of population infected
SELECT 
    location,
    date,
    population,
    total_cases,
    (CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS InfectionRatePercent
FROM PortfolioProject..CovidDeathsMain
ORDER BY location, date;


-- Countries with Highest Infection Rate compared to Population
SELECT 
    location,
    population,
    MAX(CAST(total_cases AS FLOAT)) AS HighestInfectionCount,
    MAX((CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100) AS HighestInfectionRatePercent
FROM PortfolioProject..CovidDeathsMain
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestInfectionRatePercent DESC;

-- Countries with Highest Death Count per Population
SELECT 
    location,
    MAX(CAST(total_deaths AS INT)) AS PeakTotalDeaths
FROM PortfolioProject..CovidDeathsMain
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY PeakTotalDeaths DESC;

-- BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent,
    MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeathsMain
--Where location like '%states%'
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- Across the globe
SELECT 
    SUM(CAST(new_cases AS FLOAT)) AS total_cases,
    SUM(CAST(new_deaths AS FLOAT)) AS total_deaths,
    (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeathsMain
WHERE continent IS NOT NULL
ORDER BY total_cases, total_deaths;

-- Looking at Total Vaccinations Vs Population USING CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        CAST(dea.population AS BIGINT) AS population, 
        CAST(vac.new_vaccinations AS BIGINT) AS new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS BIGINT)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated
    FROM PortfolioProject..CovidDeathsMain AS dea
    JOIN PortfolioProject..CovidVaccinationsMain AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT 
    *,
    (CAST(rolling_people_vaccinated AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS percent_vaccinated
FROM PopVsVac;


-- USE TEMP TABLE

DROP TABLE IF EXISTS #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated (
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    rolling_people_vaccinated numeric
);

INSERT INTO #PercentagePopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    TRY_CAST(dea.date AS datetime) AS date, 
    CAST(dea.population AS BIGINT) AS population, 
    CAST(vac.new_vaccinations AS BIGINT) AS new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) 
        OVER (PARTITION BY dea.location ORDER BY TRY_CAST(dea.date AS datetime)) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeathsMain AS dea
JOIN PortfolioProject..CovidVaccinationsMain AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT 
    *,
    (CAST(rolling_people_vaccinated AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS percent_vaccinated
FROM #PercentagePopulationVaccinated;

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    CAST(dea.population AS BIGINT) AS population, 
    CAST(vac.new_vaccinations AS BIGINT) AS new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeathsMain AS dea
JOIN PortfolioProject..CovidVaccinationsMain AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *
FROM PercentPopulationVaccinated;

