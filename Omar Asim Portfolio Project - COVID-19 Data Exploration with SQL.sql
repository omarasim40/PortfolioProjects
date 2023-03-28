/*
COVID-19 Data Exploration with SQL

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


--Briefly looking at both tables
SELECT *
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY location, date

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
ORDER BY location, date

-- Starting with the first table, CovidDeaths
-- Selecting the relevant data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in Saudi Arabia
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS percentage_of_population_dead
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL AND location LIKE '%arabia%'
ORDER BY location, date


-- Looking at Total Cases vs Population
-- Shows what percentage of the KSA's population contracted COVID
SELECT location, date, population, total_cases, (total_cases/population)*100 AS percentage_of_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL AND location LIKE '%arabia%'
ORDER BY location, date


-- Looking at countries with Total Percentage of Population Infected compared to Population
SELECT location, population, MAX(total_cases) AS total_infected_count, MAX((total_cases/population))*100 AS total_percentage_of_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY total_percentage_of_population_infected DESC


-- Showing countries with Largest Death Count
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC


-- Showing continents with Largest Death Count
SELECT continent, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC


-- Global numbers 01
SELECT
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS int)) AS total_deaths,
	(SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS percentage_of_population_dead
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY total_cases


-- Global numbers 02
SELECT
	date,
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS int)) AS total_deaths,
	(SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS percentage_of_population_dead
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, total_cases




-- Now looking at CovidVaccinations table as well
SELECT *
FROM PortfolioProject.dbo.CovidVaccinations




-- Looking at Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3




-- Using CTE to perform Calculation on Partition By in previous query
WITH PopVsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS (
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (rolling_people_vaccinated/population)*100 AS percent_of_population_vaccinated
FROM PopVsVac
ORDER BY 2,3




-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (rolling_people_vaccinated/population)*100  AS percent_of_population_vaccinated
FROM #PercentPopulationVaccinated
ORDER BY 2,3




-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3




-- Viewing the view
SELECT *
FROM PercentPopulationVaccinated
ORDER BY 2,3