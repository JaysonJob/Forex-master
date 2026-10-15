
--creating our schema and setting the search path to schema name so whenever we run the query it reflects to the schema
--created the table then importing the csv dataset manually then hitting the refresh button then it will display our results
create schema Forex_Cascade;
set search_path to Forex_Cascade;
 
create table forex_master(
    symbol   text,
    day      date,
    open     int,
    high     int,
    low      int,
    close     int,
    event_name text);
select * from forex_master;

--checking if we loaded all our data while imported before we begin cleaning
select symbol, count(*) as row_count,min(day) as first_day,max(day) as last_day
from forex_master
group by symbol
order by symbol;

--check the empty cells.every number should be 0.
select
    count(*) filter (where symbol is null) as null_symbol,
    count(*) filter (where day is null) as null_day,
    count(*) filter (where open is null) as null_open,
    count(*) filter (where high is null) as null_high,
    count(*) filter (where low is null) as null_low,
    count(*) filter (where close is null) as null_close,
    count(*) filter (where event_name is null) as null_event
from forex_master;--since the result generated is 0 then we have no missing vallues or nulls

--check for duplicates (same pair twice on the same day)
select symbol, day, count(*) as times_found
from forex_master
group by symbol,day
having count(*) > 1;--we have no duplicates either

--list the event labels.NFP, CPI, FOMC and "CPI, FOMC".
select event_name,count(*) as days
from forex_master
group by event_name
order by days desc;

--since our data is clean:no duplicates,nulls and wrong typo,we will move to analysis and answering busines questions in the next file
