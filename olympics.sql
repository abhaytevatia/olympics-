--1.) How many olympics games have been held?
select count (distinct games) as total_olympic_games
from olympics_history


--2.) List down all Olympics games held so far.
select distinct games, city
from olympics_history
order by games


--3.) Mention the total no of nations who participated in each olympics game?
select oh.games, count (distinct ohnr.region) as total_nations
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
group by oh.games
order by oh.games


--4.) Which year saw the highest and lowest no of countries participating in olympics?
with cte as ( select oh.games, count (distinct ohnr.region) as total_nations,
dense_rank() over(order by count (distinct ohnr.region)) as row_1
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
group by oh.games
order by count (distinct ohnr.region) )
select cte.games as lowest_country, table1.games as highest_country
from cte
join ( select oh.games, count (distinct ohnr.region) as total_nations,
dense_rank() over(order by count (distinct ohnr.region) desc) as row_3
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
group by oh.games
order by count (distinct ohnr.region) desc ) table1
on table1.row_3 = cte.row_1
limit 1
-- with different method
with cte as ( select oh.games, count (distinct ohnr.region) as total_nations,
dense_rank() over(order by count (distinct ohnr.region)) as row_
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
group by oh.games
order by count (distinct ohnr.region)
limit 1 ),
cte1 as (  select oh.games, count (distinct ohnr.region) as total_nations,
dense_rank() over(order by count (distinct ohnr.region) desc) as row_1
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
group by oh.games
order by count (distinct ohnr.region) desc
limit 1)
select cte.games as lowest_country, cte1.games as highest_country
from cte
join cte1 on cte.row_ = cte1.row_1


--5.) Which nation has participated in all of the olympic games?
with cte as ( select ohnr.region as countries, count( distinct oh.games) as total_games_participated
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
group by ohnr.region ),
cte1 as ( select count( distinct oh.games) as total_games_in_olympics
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc )
select *
from cte
join cte1 on cte.total_games_participated = cte1.total_games_in_olympics
--with different method
select ohnr.region as countries, count( distinct oh.games) as total_games_participated, count(distinct games) as total_games_in_olympics
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
group by ohnr.region 
having count ( distinct games) = ( select count(distinct games) from olympics_history  )

/* SELECT country        ( dummy syntax for finding the participants in all years)
FROM my_table
GROUP BY country
HAVING COUNT(DISTINCT year) = (SELECT COUNT(DISTINCT year) FROM my_table)*/


--6.) Identify the sport which was played in all summer olympics.
with cte as ( select sport, count (distinct games) as participated_games
from olympics_history 
where season = 'Summer'
group by sport
having count ( distinct games) = ( select count(distinct games) from olympics_history where season = 'Summer' ) ),
cte1 as ( select count (distinct games) as total_games
from olympics_history 
where season = 'Summer' )
select *
from cte
join cte1 on cte.participated_games = cte1.total_games


--7.) Which Sports were just played only once in the olympics?
with cte as ( select sport, count(distinct games) as no_of_games
from olympics_history
group by sport
having count(distinct games ) = 1
order by count(distinct games) ),
cte1 as ( select sport, games
from olympics_history
group by sport, games
having count(distinct games) = 1 )
select cte.*, cte1.games
from cte
join cte1 on cte.sport = cte1.sport


--8.) Fetch the total no of sports played in each olympic games.
select games, count (distinct sport) as total_sports
from olympics_history
group by games
order by count (distinct sport) desc, games


--9.) Fetch details of the oldest athletes to win a gold medal.
with cte as ( select name, sex, age,team, games,city, sport,event, medal, dense_rank() over(order by age desc) as row_
from olympics_history
where medal = 'Gold' and age <> 'NA'
order by age  desc, name )
select *
from cte
where row_ = 1


--10.) Find the Ratio of male and female athletes participated in all olympic games.
with cte as ( select coalesce( case when sex ilike '%M%' then count(sex) end,0) as male,
coalesce( case when sex ilike '%F%' then count(sex) end,0) as female
from olympics_history
where sex is not null and sex <> 'NA'
group by sex )
select
'1:' || round( sum(male)/ sum(female),2) as male_to_female_ratio
from cte



--11.) Fetch the top 5 athletes who have won the most gold medals.
with cte as ( select name, team, count(medal) as no_of_gold_medals,
dense_rank() over(order by count(medal) desc) as row_
from olympics_history
where medal = 'Gold'
group by name, team
order by count(medal) desc )
select name, team, no_of_gold_medals, row_ as rank_
from cte
where row_ <=5


--12.) Top 5 athletes who have won the most medals (gold/silver/bronze)
with cte as ( select name, team, count(medal) as no_of_medals,
dense_rank() over(order by count(medal) desc) as row_
from olympics_history
where medal <> 'NA' 
group by name, team
order by count(medal) desc )
select name, team, no_of_medals, row_ as rank_
from cte
where row_ <=5


--13.) Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
with cte as ( select ohnr.region as countries, count(oh.medal) as no_of_medals
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where oh.medal <> 'NA'
group  by ohnr.region
order by count(oh.medal) desc ),
cte1 as ( select *,
dense_rank() over(order by no_of_medals desc) as row_
from cte )
select *
from cte1
where row_<=5


--14.) List down total gold, silver and broze medals won by each country.
with cte as ( select ohnr.region as countries,
case
when oh.medal = 'Gold' then sum(count (oh.medal)) over(partition by ohnr.region,oh.medal) end  as gold_,
case when oh.medal = 'Silver' then sum(count (oh.medal)) over(partition by ohnr.region, oh.medal) end  as silver_,
case when oh.medal = 'Bronze' then sum(count (oh.medal)) over(partition by ohnr.region, oh.medal) end  as bronze_
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where oh.medal <> 'NA'
group by ohnr.region, oh.medal
order by ohnr.region ),
cte1 as ( select countries, coalesce(gold_,0) as gold__, coalesce(silver_,0) as silver__, coalesce(bronze_,0) as bronze__,
sum(coalesce(gold_,0)) over(partition by countries) as Gold,
sum(coalesce(silver_,0)) over(partition by countries) as Silver,
sum(coalesce(bronze_,0)) over(partition by countries) as Bronze
from cte ),
cte3 as ( select *,
row_number() over(partition by countries) as row_
from cte1 )
select coalesce(countries,'NA') as countries, gold, silver,bronze
from cte3
where row_ = 1 
order by gold + silver + bronze desc


--15.) List down total gold, silver and broze medals won by each country corresponding to each olympic games.
with cte as ( select oh.games as games, ohnr.region as countries,
coalesce(case when oh.medal = 'Gold' then sum(count (oh.medal)) over(partition by oh.games, ohnr.region,oh.medal) end,0)  as gold_,
coalesce(case when oh.medal = 'Silver' then sum(count (oh.medal)) over(partition by oh.games, ohnr.region, oh.medal) end,0)  as silver_,
coalesce(case when oh.medal = 'Bronze' then sum(count (oh.medal)) over(partition by oh.games, ohnr.region, oh.medal) end,0)  as bronze_
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where oh.medal <> 'NA' 
group by oh.games, ohnr.region, oh.medal
order by oh.games, ohnr.region ),
cte1 as ( select games, countries, 
sum(coalesce(gold_,0)) over(partition by games, countries) as Gold,
sum(coalesce(silver_,0)) over(partition by games, countries) as Silver,
sum(coalesce(bronze_,0)) over(partition by games, countries) as Bronze
from cte ),
cte3 as ( select *,
row_number() over(partition by games, countries) as row_
from cte1 )
select games, coalesce(countries,'NA') as countries, gold, silver,bronze
from cte3
where row_ = 1  
order by games, countries


--16.) Identify which country won the most gold, most silver and most bronze medals in each olympic games.
with gold as ( select oh.games, ohnr.region as region_g, count(oh.medal) as max_gold,
row_number() over(partition by oh.games order by count(oh.medal) desc, ohnr.region) as row_g
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where oh.medal = 'Gold'
group by oh.games, ohnr.region
order by oh.games, count(oh.medal) desc, ohnr.region ),
silver as ( select oh.games, ohnr.region as region_s, count(oh.medal) as max_silver,
row_number() over(partition by oh.games order by count(oh.medal) desc, ohnr.region) as row_s
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where oh.medal = 'Silver'
group by oh.games, ohnr.region
order by oh.games, count(oh.medal) desc, ohnr.region ),
bronze as ( select oh.games, ohnr.region as region_b, count(oh.medal) as max_bronze,
row_number() over(partition by oh.games order by count(oh.medal) desc, ohnr.region) as row_b
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where oh.medal = 'Bronze'
group by oh.games, ohnr.region
order by oh.games, count(oh.medal) desc, ohnr.region )
select gold.games, region_g || '-' || max_gold as max_gold,
region_s || '-' || max_silver as max_silver,
region_b || '-' || max_bronze as max_bronze
from gold
join silver on gold.games = silver.games
join bronze on gold.games = bronze.games
where row_g = 1 and row_s =1 and row_b = 1 


--17.) Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
with gold as ( select oh.games, ohnr.region as region_g, count(oh.medal) as max_gold,
row_number() over(partition by oh.games order by count(oh.medal) desc, ohnr.region) as row_g
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where oh.medal = 'Gold'
group by oh.games, ohnr.region
order by oh.games, count(oh.medal) desc, ohnr.region ),
silver as ( select oh.games, ohnr.region as region_s, count(oh.medal) as max_silver,
row_number() over(partition by oh.games order by count(oh.medal) desc, ohnr.region) as row_s
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where oh.medal = 'Silver'
group by oh.games, ohnr.region
order by oh.games, count(oh.medal) desc, ohnr.region ),
bronze as ( select oh.games, ohnr.region as region_b, count(oh.medal) as max_bronze,
row_number() over(partition by oh.games order by count(oh.medal) desc, ohnr.region) as row_b
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where oh.medal = 'Bronze'
group by oh.games, ohnr.region
order by oh.games, count(oh.medal) desc, ohnr.region ),
total as ( select oh.games, 
ohnr.region || '-' || count(oh.medal) as total_medals,
row_number() over(partition by oh.games order by count(oh.medal) desc, ohnr.region) as row_
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where oh.medal <> 'NA'
group by oh.games, ohnr.region
order by oh.games, count(oh.medal) desc, ohnr.region )
select gold.games, region_g || '-' || max_gold as max_gold,
region_s || '-' || max_silver as max_silver,
region_b || '-' || max_bronze as max_bronze, total.total_medals
from gold
join silver on gold.games = silver.games
join bronze on gold.games = bronze.games
join total on gold.games = total.games
where row_g = 1 and row_s =1 and row_b = 1 and row_ = 1


--18.) Which countries have never won gold medal but have won silver/bronze medals?
with cte3 as ( with cte1 as ( with cte as ( select ohnr.region, oh.medal,
coalesce( case when medal = 'Gold' then count(medal) end,0) as gold,
coalesce( case when medal = 'Silver' then count(medal) end,0)  as silver,
coalesce( case when medal = 'Bronze' then count(medal) end,0) as bronze
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where oh.medal <> 'NA' and ohnr.region is not null 
group by region, medal
order by region )
select region,
sum(gold) over(partition by region) as gold,
sum(silver) over(partition by region) as silver ,
sum(bronze) over(partition by region) as bronze 
from cte )
select *,
row_number() over(partition by region) as row_
from cte1 )
select region, gold, silver, bronze
from cte3
where row_ = 1 and gold = 0
order by gold + silver + bronze desc


--19.) In which Sport/event, India has won highest medals.
select oh.sport, count(oh.medal) as total_medals
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where ohnr.region = 'India' and oh.medal <> 'NA'
group by oh.sport
order by count(medal) desc
limit 1


--20.Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.
select ohnr.region, oh.sport, oh.games, count(oh.medal) as total_medals
from olympics_history oh
left join olympics_history_noc_regions ohnr on oh.noc = ohnr.noc
where ohnr.region = 'India' and oh.medal <> 'NA' and oh.sport = 'Hockey'
group by ohnr.region, oh.sport, oh.games
order by count(medal) desc
