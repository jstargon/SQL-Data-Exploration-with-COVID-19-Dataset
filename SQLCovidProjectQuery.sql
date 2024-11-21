--Ordering the Data by country, and date
SELECT *
From CovidDeaths 
Order by 3,4

--Addition: Viewing the Data in the CovidVacccinations Table
SELECT *
From CovidVaccinations

--Addition: Displaying Data of the Continents
Select * 
From CovidDeaths
Where continent is null
Order by 3,4

--Displaying certain data, Ordered By location and date
Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Order By 1,2


--Creating a Column of the death percentage and Filtering to get the United States data using a Substring and Wildcards
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
Where Location like '%states%'
Order By 1,2

--Creating a Column of percentage ingected and Filtering to get the United States data using a Substring and Wildcards
Select Location, date, total_cases, Population, (total_cases/Population)*100 as PercentageInfected
From CovidDeaths
Where Location like '%states%'
Order By 1,2


--Showing HighestInfectionCount and MaxPercentPopulationInfected by country using Group By
Select Location, Population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/Population))*100 as MaxPercentPopulationInfected
From CovidDeaths
Group by Location, Population
Order By MaxPercentPopulationInfected desc

--Displaying total deaths by country descending, Typecasting to Sort correctly and Filtering to avoid showing the continents
Select Location, Max(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null
Group by Location, Population
Order By TotalDeathCount desc

--Displaying total deaths by a different group than country (continent, workd, EU, International) descending
Select location, Max(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is null
Group by location
Order By TotalDeathCount desc

--Addition: Getting the continents in the dataset
Select continent
From CovidDeaths
Where continent is not null
Group by continent

--Addition: Getting the total deaths by continent and country
Select continent, location, Max(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null
Group by continent, location
Order By TotalDeathCount desc

--Addition: Getting the total deaths by country by using the previous query as a Common Table Expression (CTE)
WITH CTE_continent_location as (
Select continent, location, Max(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null
Group by continent, location)
SELECT continent, Sum(cast(TotalDeathCount as int)) as CountryDeathCount
From CTE_continent_location
Group by continent


--Getting the global case count, death count, and death percentage using SUM and Casting, and Filtering Larger Groups
Select SUM(New_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage	
From CovidDeaths
Where continent is not null
Order By 1,2

--Getting vaccination data using Joins, Convert for Data Types, and Partition By to get a rolling count of vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) 
	OVER (Partition by dea.Location Order by dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Using the previous table as a CTE and adding a column for Percent Vaccinated
With PopvsVac(Continent,Location,Date,Population,new_vaccinations,RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) 
	OVER (Partition by dea.Location Order by dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentVaccinated 
From PopvsVac


--Addition: Previous table, but filtering when there are new_vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) 
	OVER (Partition by dea.Location Order by dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
	AND new_vaccinations is not null
order by 2,3

--Addition: Getting the start date of vaccinations for each country ascending using Aggregate Functions, Joins, Filtering, and Group By; using Case statements to describe human development index categorically
Select dea.continent, dea.location, Min(dea.date) as VaccinationStart, avg(dea.population) as Population, avg(vac.human_development_index) as HumanDevelopmentIndex, 
CASE 
	WHEN avg(vac.human_development_index) < 0.550 THEN 'Low'
	WHEN avg(vac.human_development_index) <= 0.699 THEN 'Medium'
	WHEN avg(vac.human_development_index) <= 0.799 THEN 'High'
	ELSE 'Very High'
END AS HumanDevelopmentLevel
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
	AND new_vaccinations is not null
Group by dea.continent, dea.location
Order by 3



--Creating, Inserting, and Accessing a Temp Table (inserting a past Query of vaccination data)
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) 
	OVER (Partition by dea.Location Order by dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null


Select * From #PercentPopulationVaccinated



--Creating a View to Store Data to be accessed another time
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) 
	OVER (Partition by dea.Location Order by dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

Select * From PercentPopulationVaccinated;