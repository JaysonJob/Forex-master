set search_path to Forex_cascade;
select * from forex_master;


--are event days more volatile than normal days?
--we have to split days into "event" and "non-event" then compare range size
--why?? if fomc/nfp/cpi days are wilder,we need to flag them in any strategy.
--if avg_range_pct on event days is bigger than on no-event days, events drive volatility.
with tagged as (
    select
        symbol,
        (high - low) / nullif(open,0) * 100 as range_pct,  -- daily range as % of open
        case when event_name is null or event_name = 'None'
             then 'no_event' else 'event' end as day_type   
    from forex_master)
select symbol,day_type,
    count(*) as days,--number of days in each bucket
    round(avg(range_pct)::numeric,4) as avg_range_pct --average daily range %
from tagged
group by symbol,day_type
order by symbol,day_type;


--which event moves each asset the most?
--top rows = the news that moves that instrument most.
-- explode multi-event rows (e.g. "CPI, FOMC" becomes 2 rows)
select symbol,
    unnest(string_to_array(event_name, ', ')) as event_type,-- split on comma
    count(*)as n,
    round(avg(abs((close - open)/nullif(open,0))*100)::numeric, 4)as avg_move_pct 
from forex_master
where event_name is not null and event_name <> 'None'
group by symbol, event_type
order by symbol, avg_move_pct desc;


--on event days, does price tend to go up or down?(bulish or bearish)
--shows directional bias — e.g. "gold usually sells off on fomc".
-- positive avg_ret_pct = bullish bias on that event. win_rate_pct > 55 = weak edge.
select symbol,
    unnest(string_to_array(event_name, ', '))as event_type,
    count(*) as n,
    round(avg((close - open)/nullif(open,0)*100)::numeric, 4)as avg_ret_pct,   -- positive = up bias
    round(100.0 * sum(case when close > open then 1 else 0 end)
          / count(*), 2)as win_rate_pct   -- % of up days
from forex_master
where event_name is not null and event_name <> 'None'
group by symbol, event_type
order by symbol, avg_ret_pct desc;


--correlation between the 4 assets
--are they diversifiers or do they move together?
--> 0.5 = strongly linked,~0 = diversifying,negative = hedges.
-- pivot returns into columns per symbol, one row per day
with wide as (
    select day,
        max(case when symbol='XAUUSD' then (close-open)/nullif(open,0)*100 end) as xauusd,
        max(case when symbol='BTCUSD' then (close-open)/nullif(open,0)*100 end) as btcusd,
        max(case when symbol='AUDCAD' then (close-open)/nullif(open,0)*100 end) as audcad,
        max(case when symbol='EURAUD' then (close-open)/nullif(open,0)*100 end) as euraud
    from forex_master
    group by day)
-- pairwise correlations (nulls automatically skipped by corr)
select
    round(corr(xauusd, btcusd)::numeric,4) as xau_btc,
    round(corr(xauusd, audcad)::numeric,4) as xau_audcad,
    round(corr(btcusd, euraud)::numeric,4) as btc_euraud,
    round(corr(audcad, euraud)::numeric,4) as audcad_euraud
from wide;


--monthly performance
-- first open, last close, and min/max per month
select symbol,
    date_trunc('month', day)::date as month,
    (array_agg(open  order by day))[1] as open,   -- first day's open
    (array_agg(close order by day desc))[1] as close,  -- last day's close
    round((( (array_agg(close order by day desc))[1]
           - (array_agg(open  order by day))[1] )
           / nullif((array_agg(open order by day))[1],0) * 100)::numeric, 4)as monthly_ret_pct
from forex_master
group by symbol, month
order by symbol, month;


--event count per year
--we normalises everything else (some years have more fomc meetings)
-- fomc ~8/yr,nfp & cpi ~12/yr.exceptions flag special years (e.g. 2020 emergency cuts).
select
    extract(year from day)::int as yr,
    unnest(string_to_array(event_name, ', '))as event_type,
    count(*)as n
from forex_master
where event_name is not null and event_name <> 'None'
group by yr, event_type
order by yr, event_type;

