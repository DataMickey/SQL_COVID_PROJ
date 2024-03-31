--Select * from 
--covid_analysis..CovidDeaths
--order by 3,4



--Select * from 
--covid_analysis..CovidVaccinations
--order by 3,4

-- select data that is needed to work on

select location, date, total_cases, new_cases, total_deaths, population
from covid_analysis..CovidDeaths
Order by 1

-- total cases vs total deaths

--Select  location, date, total_deaths, total_Cases, (total_deaths/total_cases) as death_rate
--from covid_analysis..CovidDeaths
--Order by 1
--replace empty cell with NULL values

-- update CovidDeaths Set continent = NULL where continent = ' '
-- check if there is any spaces left
--Select continent, location from CovidDeaths
--where continent = ' '
--update CovidDeaths Set iso_code = NULL where iso_code = ' '
--update CovidDeaths Set location = NULL where location = ' '
--update CovidDeaths Set date = NULL where date = ' '
--update CovidDeaths Set total_cases = NULL where total_cases = ' '
--update CovidDeaths Set new_cases = NULL where new_cases = ' '
--update CovidDeaths Set total_deaths = NULL where total_deaths = ' '

-- to save the results of an sql query in new table
--select * into Table_data_updated
--from INFORMATION_SCHEMA.COLUMNS
--where TABLE_NAME='CovidDeaths'

-- change data type of a column in SQL
select * From covid_analysis..CovidDeaths

---------alter data type---------------------------------------------------------------------------

ALTER TABLE covid_analysis..CovidDeaths 
	ALTER COLUMN total_deaths decimal(10,0)

ALTER TABLE covid_analysis..CovidDeaths 
	ALTER COLUMN total_cases decimal(10,0)

ALTER TABLE covid_analysis..CovidDeaths 
	ALTER COLUMN population decimal(10,0)

-- percentage of deaths, location
-- likelehood of death by covid
Select  location, date, total_deaths, total_Cases, (total_deaths/total_cases)*100 as death_percentage
from covid_analysis..CovidDeaths
where location like '%India%'
Order by 1

-- total cases vs population
Select  location, population, date, total_deaths, total_Cases, (total_cases/population)*100 as death_percentage
from covid_analysis..CovidDeaths
where location like '%states%'
Order by 1

-- highest infection rate in country

Select  location, population, MAX(total_Cases) as Max_Cases , MAX(cast(total_cases/population as int))*100 as max_pop_infected
from covid_analysis..CovidDeaths
Group by location, population
Order by max_pop_infected

-- countries with highest death count per pop

Select  location, MAX(cast (total_deaths as int)) as Max_deaths
from covid_analysis..CovidDeaths
where continent is not null
Group by location
Order by Max_deaths desc

-- by continent
Select  location, continent, MAX(cast (total_deaths as int)) as Max_deaths
from covid_analysis..CovidDeaths
where continent is not null
Group by continent, location
Order by Max_deaths desc

-- other way to do it

--Select  location, MAX(cast (total_deaths as int)) as Max_deaths
--from covid_analysis..CovidDeaths
--where continent is null
--Group by location
--Order by Max_deaths desc

-- global numbers

Select date, (total_Cases), continent, location, population, (total_deaths), ((total_cases/population))*100 as death_percentage
from covid_analysis..CovidDeaths
-- where location like '%states%'
where continent is not null
--Group by date
Order by 1

------------------------------------------------------------

Select date, sum(total_Cases), SUM(cast(new_deaths as int)), SUM(cast(new_deaths as int))/SUM(cast(new_cases as int))*100 as death_percentage
from covid_analysis..CovidDeaths
-- where location like '%states%'
where continent is not null
Group by date
Order by 1,2

---------------------------------

Select sum(total_Cases), SUM(cast(new_deaths as int)), SUM((new_deaths))/SUM((new_cases))*100 as death_percentage
from covid_analysis..CovidDeaths
-- where location like '%states%'
where continent is not null
--Group by date
Order by 1,2

------------- joins--------------------------------------------
Select * 
from covid_analysis..CovidDeaths dea
join covid_analysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

---------------------total pop vs vaccinations--------------------------------------------

Select dea.continent, dea. location,  dea.date, dea.population, vac.new_vaccinations
from covid_analysis..CovidDeaths dea
join covid_analysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 1,2,3
order by 2,3
-----------------------sum new vacc over partition by ---------------

Select dea.continent, dea. location,  dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as int))
	over (Partition by dea.location) --, other way to change datatype SUM(Convert(int, vac.new_vaccinations))
from covid_analysis..CovidDeaths dea
join covid_analysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 1,2,3
order by 2,3

-----------------------sum new vacc over partition by and order by together ---------------

Select dea.continent, dea. location,  dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations))
	over (Partition by dea.location order by dea.location, dea.date) as rolling_vacc_count
from covid_analysis..CovidDeaths dea
join covid_analysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 1,2,3
order by 2,3

--------------------------------cte common table expression/temp tables-------------------------------------------------
--by CTE

With vacvspop (continent, location, date, population, new_vaccinations, rolling_vacc_count)
as
(
Select dea.continent, dea. location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations))
	over (Partition by dea.location order by dea.location, dea.date) as rolling_vacc_count --, other way to change datatype SUM(Convert(int, vac.new_vaccinations))
from covid_analysis..CovidDeaths dea
join covid_analysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 1,2
)
select *, (rolling_vacc_count/population)*100
from vacvspop

---------temp table--------------
Drop table if exists #percentpopvaccinated
Create table #percentpopvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_vaccinations numeric,
rolling_vacc_count numeric
)

insert into #percentpopvaccinated

Select dea.continent, dea. location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations))
	over (Partition by dea.location order by dea.location, dea.date) as rolling_vacc_count --, other way to change datatype SUM(Convert(int, vac.new_vaccinations))
from covid_analysis..CovidDeaths dea
join covid_analysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null

select * , (rolling_vacc_count/population)*100
from #percentpopvaccinated

-------------create views-----------------------------

create view firstvacpopview 
as

Select dea.continent, dea. location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations))
	over (Partition by dea.location order by dea.location, dea.date) as rolling_vacc_count --, other way to change datatype SUM(Convert(int, vac.new_vaccinations))
from covid_analysis..CovidDeaths dea
join covid_analysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null