/*
Data exploration project: Covid 19 data SEP(2023)
-----------------------------------
Skills:
1. Aggregate Functions
2. CTE's (Common Table Expressions)
3. Creating Views
4. Data Querying and Retrieval
5. Data Type Alteration
6. Joins
7. String Functions
8. Temp Tables
9. Window Functions
*/

-- Query 1: SELECT top 5 records
SELECT TOP 5 * 
FROM Covid_Deaths
ORDER BY 3, 4

-- Query 2: SELECT data to be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid_Deaths
ORDER BY 1, 2

-- Query 3: ALTER column data types
ALTER TABLE Covid_Deaths
ALTER COLUMN total_deaths FLOAT

ALTER TABLE Covid_Deaths
ALTER COLUMN total_cases FLOAT

-- Query 4: Calculate percentage of deaths
SELECT location, date, total_cases, total_deaths, (CONCAT(total_deaths*100/total_cases,'%')) percentage_of_deaths
FROM Covid_Deaths
WHERE location LIKE '%mexico%'
ORDER BY 4 DESC

-- Query 5: Calculate likelihood of death by country
SELECT location, date, total_cases, total_deaths, (CONCAT(total_deaths/total_cases*100,'%')) percentage_of_deaths
FROM Covid_Deaths
WHERE location = 'Mexico'
ORDER BY 2 DESC

-- Query 6: Calculate percentage of population with COVID-19
SELECT location, date, population, total_cases, (total_cases/population)*100 case_percentages
FROM Covid_Deaths
WHERE location = 'Mexico'
ORDER BY 2 DESC

-- Query 7: Countries with highest infection rate
SELECT TOP 15 
location, population, MAX(total_cases) HighestCount, MAX((total_cases/population))*100 PercentInfected
FROM Covid_Deaths
GROUP BY location, population
ORDER BY PercentInfected DESC

-- Query 8: 2023 Cases and Deaths for Mexico
SELECT 
location, SUM(new_cases) AS "2023_cases", SUM(new_deaths) AS "2023_deaths", SUM(CAST(new_deaths AS FLOAT))/SUM(CAST(new_cases AS FLOAT))*100 AS "2023_DeathPercentage"
FROM Covid_Deaths
WHERE location='Mexico' AND  YEAR(date) = '2023'
GROUP BY location

-- Query 9: Countries with highest death count 
SELECT TOP 15
location, population, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestDeathCount DESC

-- Query 10: Countries with highest death rates
SELECT TOP 15
location, MAX(population), MAX(CAST(total_deaths AS INT)) HighestDeathCount, SUM(CAST(new_cases AS FLOAT))/SUM(CAST(new_deaths AS FLOAT))*100 PercentageOfDeaths
FROM Covid_Deaths
GROUP BY location
ORDER BY PercentageOfDeaths DESC

-- Query 11: Continents with highest death count 
SELECT continent, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC

-- Query 12: Global Numbers
SELECT
    date,
    SUM(new_cases) AS GlobalCases,
    SUM(CAST(new_deaths AS INT)) AS GlobalDeaths,
    CASE
        WHEN SUM(new_cases) > 0 THEN (SUM(CAST(new_deaths AS INT)) * 100) / SUM(new_cases)
        ELSE 0
    END AS GlobalDeathPercentage
FROM Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

-- Query 13: Global Summary
SELECT
    SUM(new_cases) GlobalCases,
    SUM(CAST(new_deaths AS INT)) GlobalDeaths,
    CASE
        WHEN  SUM(new_cases) > 0 THEN (SUM(CAST(new_deaths AS FLOAT))*100) / SUM(new_cases)
        ELSE 0
    END AS GlobalDeathPercentage
FROM Covid_Deaths
WHERE continent IS NOT NULL

-- Query 14: Joining Covid_Deaths and Covid_Vaccinations
SELECT *
FROM Covid_Deaths CD
JOIN Covid_Vaccinations CV
    ON CD.location = CV.location
    AND CD.date = CV.date

-- Query 15: Total Vaccinations for Mexico
SELECT
CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
FROM Covid_Deaths CD
JOIN Covid_Vaccinations CV
    ON CD.location = CV.location
    AND CD.date = CV.date
WHERE CD.continent IS NOT NULL AND CD.location = 'Mexico'
ORDER BY 1, 2, 3

-- Query 16: Rolling Vaccination Count
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
 SUM(CONVERT(FLOAT, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS Rolling_Vaccinated_Count
 FROM Covid_Deaths CD
 JOIN Covid_Vaccinations CV
    ON CD.location = CV.location
    AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2, 3

-- Using CTE to perform calculations
-- Query 17: Percentage of Population Vaccinated
WITH rolling_v_count AS (
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS FLOAT)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rollingcount
FROM Covid_Deaths CD
JOIN Covid_Vaccinations CV
    ON CD.location = CV.location
    AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
)
SELECT *, ROUND((rollingcount/population)*100 , 2 )
FROM rolling_v_count
WHERE new_vaccinations IS NOT NULL
ORDER BY 2, 3

-- Query 18: Max Vaccination Percentages
WITH rolling_v_count AS (
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS FLOAT)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rollingcount
FROM Covid_Deaths CD
JOIN Covid_Vaccinations CV
    ON CD.location = CV.location
    AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
)
SELECT continent, location, MAX(population) Maxpop, ROUND(MAX(rollingcount/population)*100,2) maxvaccinations
FROM rolling_v_count
WHERE new_vaccinations IS NOT NULL
GROUP BY continent, location
ORDER BY 1,2

-- Query 19: Creating a temporary table for future use in visualizations
DROP TABLE IF EXISTS #temp_PercentPopulationVac

CREATE TABLE #temp_PercentPopulationVac (
    Continent VARCHAR(50),
    Location VARCHAR(50),
    Date DATE,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    Rollingcount NUMERIC
)

-- Query 20: Inserting data into the temporary table
INSERT INTO #temp_PercentPopulationVac
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS FLOAT)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rollingcount
FROM Covid_Deaths CD
JOIN Covid_Vaccinations CV
    ON CD.location = CV.location
    AND CD.date = CV.date

-- Query 21: Retrieve data from the temporary table
SELECT TOP 10 * 
FROM #temp_PercentPopulationVac
ORDER BY date DESC

-- Query 22: Max Vaccination Percentages from Temporary Table
SELECT Continent, Location,MAX(Population) Maxpop, MAX(CAST((Rollingcount/Population)*100 AS FLOAT)) maxvaccinations
FROM #temp_PercentPopulationVac
WHERE New_Vaccinations IS NOT NULL AND Continent IS NOT NULL
GROUP BY Continent, Location
ORDER BY 1,2

-- Query 23: Create a view for TotalCasesAndDeaths
CREATE VIEW TotalCasesAndDeaths AS
SELECT
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM Covid_Deaths

-- Query 24: Create a view for DeathRateByLocationAndDate
CREATE VIEW DeathRateByLocationAndDate AS
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    CONCAT(ROUND((total_deaths * 100.0) / total_cases, 2), '%') AS DeathPercentage
FROM Covid_Deaths
