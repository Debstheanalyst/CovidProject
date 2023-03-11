select *
from dbo.CovidDeaths$
order by 3,4



--select *
--from dbo.CovidVaccinations$_xlnm#_FilterDatabase
--order by 3,4

--Data selections to be used --


select Location, date, Total_cases, New_cases, total_deaths, population 
from dbo.CovidDeaths$
order by 1,2


--Looking at total cases versus Total deaths--

select Location, date, Total_cases, total_deaths, (total_deaths / total_cases) * 100 as DeathPercentage
from dbo.CovidDeaths$
where continent is not null
order by 1,2
-- Narrowing down to nigeria--(to show likelihood of dying if you contract covid)--


select Location, date, Total_cases, total_deaths, (total_deaths / total_cases) * 100 as DeathPercentage
from dbo.CovidDeaths$
Where Location like '%Nigeria%'
order by 1,2


-- looking at the total cases versus Population --

-- to show what percentage actually got covid--


select date, location, population, Total_cases, total_deaths, (total_cases / population) * 100 as Covidinfected
from dbo.CovidDeaths$
Where Location like '%Nigeria%'
order by 1,2

--Country with highest infection rates vs population--


select location, population, Max(Total_cases) as Highestinfectioncount, MAX(total_cases / population) * 100 as Percentageinfectedworldwide
from dbo.CovidDeaths$
where continent is not null
group by location, population
order by Percentageinfectedworldwide desc

--country with the highest deat counts per population --(Casting the total daeths as integer as there was a problem with the data varchar instead of int--


select location, population, Max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths$
where continent is not null
group by location, population
order by TotalDeathCount desc

--Drilling down by Continent--Writing two queries for this--
--1--


select continent, Max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths$
where continent is  not null
group by continent
order by TotalDeathCount desc


--2--

select location, Max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths$
where continent is null
group by location
order by TotalDeathCount desc


--showing continent with the highest deathcount--


select continent, Max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount desc

--Global Numbers death % across the world how covid affected the rest of the world--

Select date, Sum(new_cases), Sum(cast(new_deaths as int)) * 100 as DeathPercentage
from dbo.CovidDeaths$
where continent is not null
group by date, total_deaths
order by 1,2


Select Sum(new_cases) as total_cases, Sum(cast(new_deaths as int)) as total_deaths, Sum(cast(new_deaths as int))/Sum(new_cases) * 100 as DeathPercentage
from dbo.CovidDeaths$
where continent is not null
--group by date, total_deaths
order by 1,2


--joining both tables to further query the data...joining on location and date--

Select *
from dbo.CovidDeaths$  dea
join dbo.CovidVaccinations$_xlnm#_FilterDatabase  vac
on dea.location = vac.location 
and dea.date = vac.date

--Looking at total population versus vaccinations --

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from dbo.CovidDeaths$ dea
join dbo.CovidVaccinations$_xlnm#_FilterDatabase vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
order by 2,3


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum (cast (vac.new_vaccinations as int)) over (partition by dea.location)
from dbo.CovidDeaths$ dea
join dbo.CovidVaccinations$_xlnm#_FilterDatabase vac
on dea.location = vac.location 
and dea.date = vac.date
Where dea.continent is not null 
order by 2,3

--Use cte--

with PopvsVac (Continent, Location, date, population, New_vaccinations, Rollingpeoplevaccinated)
as
(

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum (cast (vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) 
as Rollingpeoplevaccinated
from dbo.CovidDeaths$ dea
join dbo.CovidVaccinations$_xlnm#_FilterDatabase vac
on dea.location = vac.location 
and dea.date = vac.date
Where dea.continent is not null 
--order by 2,3
)

select * , (Rollingpeoplevaccinated/population)* 100
from PopvsVac



--Creating a temp table to hold the data--

Drop table if exists #PercentagePopulationVaccinated
Create Table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location  nvarchar (255),
Date  datetime,
Population numeric, 
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentagePopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum (cast (vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) 
as Rollingpeoplevaccinated
from dbo.CovidDeaths$ dea
join dbo.CovidVaccinations$_xlnm#_FilterDatabase vac
on dea.location = vac.location 
and dea.date = vac.date
--Where dea.continent is not null 
--order by 2,3


select * , (Rollingpeoplevaccinated/population)* 100
from #PercentagePopulationVaccinated

--create views for visualization--

Create view PercentagePopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum (cast (vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) 
as Rollingpeoplevaccinated
from dbo.CovidDeaths$ dea
join dbo.CovidVaccinations$_xlnm#_FilterDatabase vac
on dea.location = vac.location 
and dea.date = vac.date
Where dea.continent is not null 
--order by 2,3


Create View DeathPercentage as
Select date, Sum(new_cases), Sum(cast(new_deaths as int)) as DeathPercentage
from dbo.CovidDeaths$
where continent is not null
group by date, total_deaths
--order by 1,2


Create view TotalDeathContinentPercentage as
select continent, Max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths$
where continent is not null
group by continent
--order by TotalDeathCount desc

Create View TotalDeathPercentageNigeria as
select Location, date, Total_cases, total_deaths, (total_deaths / total_cases) * 100 as DeathPercentage
from dbo.CovidDeaths$
Where Location like '%Nigeria%'
--order by 1,2

--Creating Views for infection worldwide-

Create view PercentageInfectedWordwide as
select location, population, Max(Total_cases) as Highestinfectioncount, MAX(total_cases / population) * 100 as Percentageinfectedworldwide
from dbo.CovidDeaths$
where continent is not null
group by location, population
--order by Percentageinfectedworldwide desc


--select location, Max(cast(total_deaths as int)) as TotalDeathCount
--(from dbo.CovidDeaths$
--where continent is null
--group by location
--order by TotalDeathCount desc
--select location, Max(cast(total_deaths as int)) as TotalDeathCount
--from dbo.CovidDeaths$
--where continent is null
--group by location
--order by TotalDeathCount desc)
