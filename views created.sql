set search_path to Forex_cascade;
select * from forex_master;
--the vews i create will sumarise my data which then i will
--import them to power bi for visualization


select symbol, round(min(close), 4) as min_close, round(max(close), 4) as max_close
from forex_master
group by symbol
order by symbol;


--view 1 — vw_daily_metrics (main fact table)
create or replace view vw_daily_metrics as
select symbol,day,open,high,low,close,event_name,
    -- daily range as % of open  (needed for volatility analysis)
    round(((high - low) / nullif(open,0) * 100)::numeric, 4)   as range_pct,
    -- daily return as %  (needed for direction & correlation)
    -- changed: close vs yesterday's close (was open -> close, which is flat on 36% of forex days)
    round(((close / lag(close) over (partition by symbol order by day) - 1) * 100)::numeric, 4) as ret_pct
from forex_master;

--calling the view
select * from vw_daily_metrics;


--view 2 — vw_event_impact
--one row per symbol + event_type. covers size, direction, and win-rate.
create or replace view vw_event_impact as
select symbol,
    -- split "CPI, FOMC" into separate rows
    unnest(string_to_array(event_name, ', '))as event_type,
    count(*) as n,
    round(avg(abs(ret_pct))::numeric, 4)as avg_move_pct,   -- size of move
    round(avg(ret_pct)::numeric, 4)as avg_ret_pct,    -- direction
    round(stddev(ret_pct)::numeric, 4)as std_ret_pct,    -- noise
    round(100.0 * sum(case when ret_pct > 0 then 1 else 0 end)
          / count(*), 2)as win_rate_pct    -- % of up days
from vw_daily_metrics
where event_name is not null and event_name <> 'None'
group by symbol, event_type;

--calling it
select * from vw_event_impact;


--view 3 — vw_monthly_performance
--one row per symbol per month. seasonality and trends.
create or replace view vw_monthly_performance as
select symbol,
    date_trunc('month', day)::date as month,
    (array_agg(open  order by day asc ))[1]as open,          -- first open
    (array_agg(close order by day desc))[1]as close,         -- last close
    max(high)as high,
    min(low)as low,
    round(
      ( (array_agg(close order by day desc))[1]
      - (array_agg(open  order by day asc ))[1] )
      / nullif((array_agg(open order by day asc))[1],0) * 100
      ::numeric, 4)as monthly_ret_pct
from vw_daily_metrics
group by symbol, month;

--calling it
select * from vw_monthly_performance;


--view 4 — vw_risk_metrics
--one row per symbol per day. rolling volatility + drawdown.
-- note: the peak resets every january, so drawdown is measured inside each calendar year.
-- for the all-time drawdown, change "partition by symbol, extract(year from day)" to "partition by symbol".
create or replace view vw_risk_metrics as
with base as (
    select symbol,day,ret_pct,close,
        stddev(ret_pct) over (
            partition by symbol
            order by day
            rows between 29 preceding and current row )as vol_30d,
        max(close) over (
            partition by symbol, extract(year from day)
            order by day
            rows between unbounded preceding and current row)as peak_close
    from vw_daily_metrics)
select symbol,day,
    round(vol_30d::numeric, 4) as vol_30d,
    round(((close - peak_close) / nullif(peak_close,0) * 100)::numeric, 4)as drawdown_pct
from base;

--calling the view
select * from vw_risk_metrics;