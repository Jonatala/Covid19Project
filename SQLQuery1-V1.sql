SELECT *
From Covid19Project.dbo.['owid-covid-deaths$']
ORDER BY 3, 4 DESC;



SELECT *
From Covid19Project.dbo.['owid-covid-vaccinations$']
ORDER BY 3, 4


-- select data to be used
SELECT LOCATION, DATE, total_cases, new_cases, total_deaths, population
FROM Covid19Project..['owid-covid-deaths$']


-- total cases vs total deaths
SELECT LOCATION, DATE, total_cases, total_deaths, (total_deaths/total_cases)*100 as percentage_deaths
FROM Covid19Project..['owid-covid-deaths$']
where location like '%kingdom%'
order by total_cases DESC;

---- total cases vs population
---- shows what % of the population got infected with covid
SELECT LOCATION, DATE, total_cases, population, (total_cases/population)*100 as percentage_cases
FROM Covid19Project..['owid-covid-deaths$']
 where location like '%kingdom%'
 order by total_cases DESC;

-- looking at countries with the highest rate of infection 
SELECT LOCATION, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as percentage_casesinPopulation
FROM Covid19Project..['owid-covid-deaths$']
Group by location,population
order by percentage_casesinPopulation desc;

-- showing countries with highest death count per population
SELECT LOCATION, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM Covid19Project..['owid-covid-deaths$']
where continent is not null
Group by location
order by TotalDeathCount desc;

--- showing continents with highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM Covid19Project..['owid-covid-deaths$']
where continent is not null
Group by continent
order by TotalDeathCount desc;

-- Global Numbers

Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from Covid19Project..['owid-covid-deaths$']
where continent is not null
---- Group by date
--order by TotalCases DESC;

-- looking at Total Population vs Vaccinations



 -- Filtering out 2020 dates for quick query results
SELECT *
FROM Covid19Project..['owid-covid-deaths$']
WHERE date like '%2021%'
-- order by location DESC;

-- Create a new table for only 2021 data for deaths and vaccinations
SELECT * 
INTO NewCovid19Deaths 
FROM Covid19Project..['owid-covid-deaths$']
WHERE date like '%2021%'

SELECT * 
FROM Covid19Project..NewCovid19Deaths
ORDER BY location, date DESC;

 Creating a View 

CREATE VIEW [HighestInfectionRate] AS
SELECT LOCATION, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as percentage_casesinPopulation
FROM Covid19Project..['owid-covid-deaths$']
where continent is not null
Group by location,population
--order by percentage_casesinPopulation desc;

--- GLOBAL NUMBERS

SELECT SUM (new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Deathpercentage
FROM Covid19Project..['owid-covid-deaths$']
WHERE continent is not null
-- GROUP BY date
ORDER BY 1, 2

-- looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From Covid19Project.dbo.['owid-covid-deaths$'] dea
join Covid19Project.dbo.['owid-covid-vaccinations$'] vac
    on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3

-- change data type in column
ALTER TABLE Covid19Project.dbo.['owid-covid-vaccinations$']
ALTER COLUMN new_vaccinations bigint;



SELECT location, new_vaccinations
FROM Covid19Project.dbo.['owid-covid-vaccinations$']
ORDER BY location

-- Rolling vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM (vac.new_vaccinations) OVER (partition by dea.location) as RollingPeopleVaccinated -- order by dea.location, dea.date)
From Covid19Project.dbo.['owid-covid-deaths$'] dea
join Covid19Project.dbo.['owid-covid-vaccinations$'] vac
    on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY 2, 3 DESC
order by dea.location, dea.date

-- USING A (common table expression) CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location) as RollingPeopleVaccinated 
From Covid19Project.dbo.['owid-covid-deaths$'] dea
join Covid19Project.dbo.['owid-covid-vaccinations$'] vac
    on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY 2, 3 DESC
-- order by dea.location, dea.date
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

-- Temp Table

DROP TABLE IF exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations bigint,
RollingPeopleVaccinated numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location) as RollingPeopleVaccinated 
From Covid19Project.dbo.['owid-covid-deaths$'] dea
join Covid19Project.dbo.['owid-covid-vaccinations$'] vac
    on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY 2, 3 DESC
-- order by dea.location, dea.date

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Create View


CREATE VIEW ContinentDeathCount AS
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM Covid19Project..['owid-covid-deaths$']
where continent is not null
Group by continent
-- order by TotalDeathCount desc;

Create View [PercentPopulationVaccinated] as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location) as RollingPeopleVaccinated 
From Covid19Project.dbo.['owid-covid-deaths$'] dea
join Covid19Project.dbo.['owid-covid-vaccinations$'] vac
    on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
