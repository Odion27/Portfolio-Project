-- Covid 19 Data Exploration
-- Skills used: Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

-- 1. Display all records from CovidDeaths and CovidVaccination tables
SELECT * FROM CovidDeaths ORDER BY 3;
SELECT * FROM CovidVaccination ORDER BY 3;

-- 2. Continents, countries, and population
SELECT DISTINCT location, continent, population 
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY continent, population DESC;

-- 3. Show percentage of people who died of Covid in Nigeria
SELECT location, date, 
       CAST(total_cases AS INT) AS total_cases, 
       new_cases, total_deaths,  
       ROUND((CAST(total_deaths AS INT) / CAST(total_cases AS INT)) * 100, 2) AS DeathsPercentage  
FROM CovidDeaths
WHERE location = 'Nigeria'
ORDER BY date;

-- 4. Show the percentage of population diagnosed with Covid in Nigeria
SELECT location, date, population, total_cases,
       ROUND((total_cases / population) * 100, 2) AS PercentagePopulation  
FROM CovidDeaths
WHERE location = 'Nigeria' AND continent IS NOT NULL
ORDER BY date;

-- 5. Countries with the highest infection rate compared to population
SELECT location AS Country, Population, 
       MAX(total_cases) AS HighestInfectionCount, 
       ROUND(MAX((total_cases / population)) * 100, 2) AS PercentagePopulationInfected  
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC;

-- 6. Countries with the highest death count per population
SELECT location AS Country, Population, 
       MAX(CAST(total_deaths AS INT)) AS Highest_DeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Highest_DeathCount DESC;

-- 7. Continent with the highest death count
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- 8. World numbers
SELECT date, 
       SUM(COALESCE(new_cases, 0)) AS Total_Cases, 
       SUM(CAST(COALESCE(new_deaths, 0) AS INT)) AS Total_Deaths,  
       ROUND(
           CASE 
               WHEN SUM(COALESCE(new_cases, 0)) = 0 THEN 0
               ELSE SUM(CAST(COALESCE(new_deaths, 0) AS INT)) / SUM(COALESCE(new_cases, 0)) * 100
           END, 
       5) AS DeathsPercentage  
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;


-- 9. Total population of vaccinated people
SELECT CVD.continent, CVD.location, CVD.date, CVD.population, CVV.new_vaccinations, 
       SUM(CAST(CVV.new_vaccinations AS BIGINT)) OVER (PARTITION BY CVV.location ORDER BY CVV.location, CVV.date) AS RollingPeopleVaccinated
FROM CovidDeaths CVD
JOIN CovidVaccination CVV ON CVD.location = CVV.location AND CVD.date = CVV.date
WHERE CVD.continent IS NOT NULL
ORDER BY CVD.location, CVD.date;

-- 10. Percentage of total vaccinated people per day using CTE
WITH Vaccinated_People AS (
    SELECT CVD.continent, CVD.location, CVD.date, CVD.population, CVV.new_vaccinations, 
           SUM(CONVERT(BIGINT, CVV.new_vaccinations)) OVER (PARTITION BY CVV.location ORDER BY CVV.location, CVV.date) AS RollingPeopleVaccinated
    FROM CovidDeaths CVD
    JOIN CovidVaccination CVV ON CVD.location = CVV.location AND CVD.date = CVV.date
    WHERE CVD.continent IS NOT NULL
)
SELECT *, ROUND((RollingPeopleVaccinated / Population) * 100, 5) AS Total_Vaccinated_People
FROM Vaccinated_People;

-- 11. Percentage of total vaccinated people per day using temporary tables
DROP TABLE IF EXISTS #Vaccinated_People;
CREATE TABLE #Vaccinated_People(
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #Vaccinated_People
SELECT CVD.continent, CVD.location, CVD.date, CVD.population, CVV.new_vaccinations, 
       SUM(CONVERT(BIGINT, CVV.new_vaccinations)) OVER (PARTITION BY CVV.location ORDER BY CVV.location, CVV.date) AS RollingPeopleVaccinated
FROM CovidDeaths CVD
JOIN CovidVaccination CVV ON CVD.location = CVV.location AND CVD.date = CVV.date
WHERE CVD.continent IS NOT NULL;

SELECT *, ROUND((RollingPeopleVaccinated / Population) * 100, 5) AS Total_Vaccinated_People
FROM #Vaccinated_People
ORDER BY location, date;

-- 13. Creating view for data visualization
CREATE VIEW PercentPopulationVaccinated AS 
SELECT CVD.continent, CVD.location, CVD.date, CVD.population, CVV.new_vaccinations, 
       SUM(CONVERT(BIGINT, CVV.new_vaccinations)) OVER (PARTITION BY CVV.location ORDER BY CVV.location, CVV.date) AS RollingPeopleVaccinated
FROM CovidDeaths CVD
JOIN CovidVaccination CVV ON CVD.location = CVV.location AND CVD.date = CVV.date
WHERE CVD.continent IS NOT NULL;

-- Query the view
SELECT * FROM PercentPopulationVaccinated;
