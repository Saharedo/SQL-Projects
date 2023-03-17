SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

SELECT *
FROM CovidVaccinations
ORDER BY 3, 4

-- Selecting data to be used

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Looking at total cases vs total deaths
-- Shows likelihood of dying if contract covid in US

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location like '%states%' AND continent IS NOT NULL
ORDER BY 1, 2

-- total cases vs population
-- Shows percentage of population that contracted covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS CovidPercentage
FROM CovidDeaths
WHERE location like '%states%' AND continent IS NOT NULL
ORDER BY 1, 2

-- Countries with highest infection rate compared to population

SELECT location, MAX(total_cases) AS HighestInfectCount, population, MAX((total_cases/population))*100 AS PercentPopInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopInfected DESC


-- Countries with highest death count per population

SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Continents with highest death count

SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global Numbers
-- death percentage per day
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, (SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1


-- Avg death percentage 
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, (SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL


-- Total Pop vs Total Vaccinations

SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, SUM(CONVERT(int, vax.new_vaccinations)) OVER 
(PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS death
JOIN CovidVaccinations AS vax
	ON death.location = vax.location AND death.date = vax.date
WHERE death.continent IS NOT NULL
ORDER BY 2, 3

---- Using CTE
WITH PopvsVax (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, SUM(CONVERT(int, vax.new_vaccinations)) OVER 
(PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS death
JOIN CovidVaccinations AS vax
	ON death.location = vax.location AND death.date = vax.date
WHERE death.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVax


---- Temp Table
DROP TABLE IF EXISTS #PercentPopVaccinated
CREATE TABLE #PercentPopVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations int,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopVaccinated
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, SUM(CONVERT(int, vax.new_vaccinations)) OVER 
(PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS death
JOIN CovidVaccinations AS vax
	ON death.location = vax.location AND death.date = vax.date
WHERE death.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopVaccinated

--Creating Views to store data for later visualizations
---- PercentPeopleVaccinated
CREATE VIEW PercentPeopleVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, SUM(CONVERT(int, vax.new_vaccinations)) OVER 
(PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS death
JOIN CovidVaccinations AS vax
	ON death.location = vax.location AND death.date = vax.date
WHERE death.continent IS NOT NULL

SELECT *
FROM PercentPeopleVaccinated

---- Death Percentage per day
CREATE VIEW DeathPercentage AS
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, (SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
