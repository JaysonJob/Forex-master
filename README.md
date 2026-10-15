# Forex-master
Forex analysis from October 10th 2016 to October 10th 2026 

**Python (API) → CSV → PostgreSQL → Power BI**

A trading desk wants to know whether it should treat big US news days differently. This project tests whether the **NFP jobs report, CPI inflation and Federal Reserve FOMC decisions** make four markets move more: **gold (XAUUSD), Bitcoin (BTCUSD), AUDCAD and EURAUD**. It covers **10 years of daily data (10 Oct 2016 to 10 Oct 2026) and 11,375 trading days**.

> **Real data,not simulated.** The NFP and CPI release dates are pulled from the **FRED API**, run by the **Federal Reserve Bank of St. Louis** ([api.stlouisfed.org](https://fred.stlouisfed.org/docs/api/fred/)). Daily prices come from Yahoo Finance (`yfinance`; gold is the COMEX gold futures series, `GC=F`, used as a proxy for spot gold), and the FOMC meeting dates come from the Federal Reserve's published meeting calendar.
---

## Contents

1. [Business questions and hypotheses](#business-questions-and-hypotheses)
2. [Tech stack](#tech-stack)
3. [Setup / installation](#setup--installation)
4. [Workflow](#workflow)
5. [Key findings](#key-findings)
6. [Repository structure](#repository-structure)
7. [Data dictionary](#data-dictionary)
8. [Limitations and next steps](#limitations-and-next-steps)

---

## Business questions and hypotheses

Each hypothesis below was tested with SQL.A hypothesis does not have to be true: the data decides.

| # | Hypothesis | Verdict | Evidence |
|---|---|---|---|
| H1 | News days are more volatile than normal days | **Partly true** | Daily range is 1.1x to 1.2x wider for gold, Bitcoin and AUDCAD. EURAUD shows no difference |
| H2 | Gold reacts most to Fed decisions | **True** | Gold's range is 1.21x wider on FOMC days and 1.18x on NFP days |
| H3 | Wider ranges mean bigger moves by the close | **Mostly false** | Gold's average close-to-close move on FOMC days is 0.56%, against 0.74% on a normal day |
| H4 | Prices have a predictable direction on news days | **False** | Best win rate is about 59%, on only 80 to 126 days. That is within normal luck |
| H5 | Gold and Bitcoin move together | **False** | Correlation of daily returns is 0.11 |
| H6 | Bitcoin gives the best return for the risk taken | **True, with a catch** | Sharpe ratio 1.07 (gold 0.80), but a worst fall of 83% |
| H7 | Bitcoin is strongest in October | **True in this sample** | Average +16.1%, up in 8 of 11 Octobers, but only about 10 observations per month |

---

## Tech stack

| Layer | Tools |
|---|---|
| Data collection | Python, `requests`, `yfinance`, **FRED API** (Federal Reserve Bank of St. Louis), Jupyternotebook |
| Storage and analysis | PostgreSQL, pgAdmin (SQL: window functions, CTEs, views) |
| Visualisation | Power BI Desktop (DAX measures, data model) |
---

## Setup / installation

### 1. Prerequisites

- **PostgreSQL** (with pgAdmin) to run the SQL
- **Power BI Desktop** (offline, Windows) to open the report. Power BI Service (online) can also view it, see step 5
- *Optional, only to pull fresh data:* Python 3.10+ and a free **FRED API key** from [fred.stlouisfed.org](https://fred.stlouisfed.org) (*My Account > API Keys*)

### 2. Installation steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/forex-news-impact-analysis.git
   ```

2. **Create a database.** In pgAdmin, right-click *Databases > Create > Database*, name it `forex_master`and open its Query Tool. (The `.pbix` was built on the default `postgres` database. If you create your own, point Power BI at it in step 5.)

3. **Load the data.** Pick one option:
   - **Option A, one step:** open and run `sql/00_one_step_setup.sql`. It creates the schema `forex_cascade`, the table `forex_master`, and loads all 11,375 rows. No CSV import is needed.
   - **Option B, manual import:** run `sql/01_load_and_check.sql` up to the `create table` block, then right-click `forex_master > Import/Export Data`, choose `data/forex_master.csv` with Header on and delimiter `,`, then run the rest of the file (the data checks).

4. **Create the views and run the analysis.** Run `sql/02_views.sql`, then `sql/03_analysis.sql` one query at a time. The row count should be **11,375**.

   in the screenshot below left side you can see the 4 views generated
6. ![alt text](https://github.com/JaysonJob/Forex-master/blob/c4b75b23c310d6db81df184d6186e07cfb73b4c8/screenshots/views.png)

7. **Open the Power BI report** (`powerbi/power_bi.pbix`):
   - **Offline (Power BI Desktop):** open the file. If it asks for credentials or can't find the data, go to *Home > Transform data > Data source settings > Change Source*, enter server `localhost:5432` and your database name, then enter your PostgreSQL username and password on the *Database* tab and click **Refresh**.
   - **Online (Power BI Service, app.powerbi.com):** sign in, open a workspace, choose *Upload > Browse this computer* and select the `.pbix`. The report opens with the data saved in the file. Refreshing it from a local PostgreSQL database needs an on-premises data gateway.
   - **No PostgreSQL or Power BI installed?** Look at the screenshots in `screenshots/`.

8. *(Optional)* **Pull fresh data.** Set your key as an environment variable, then run the two scripts (they also work as Jupyter notebooks). Never write the key into a script or notebook.
   ```bash
   pip install -r requirements.txt
   setx FRED_API_KEY "your_32_character_key"        # Windows
   export FRED_API_KEY="your_32_character_key"      # Mac / Linux
   # reopen the terminal after setx, then run from the project folder:
   python python/01_pull_data.py      # downloads prices and event dates into data/
   python python/02_check_and_merge.py   # checks, cleans and writes data/forex_master.csv
   ```

---

## Workflow

```
Yahoo Finance (prices) ─┐
FRED API (NFP, CPI)    ─┼─►  Python scripts    ─►  CSV  ─►  PostgreSQL  ─►  Power BI
Fed calendar (FOMC)    ─┘    (pull, check, clean)   data/    (tables, views)   (4 pages)
```

### Step 1: Pull the data with Python (`python/01_pull_data.py`)

An **API** is a public window a website offers: you send a request with some parameters and it replies with data. Three sources are used:
![Alt text](https://github.com/JaysonJob/Forex-master/blob/5dcc45917f63ca987a7a25a3bfb8ec4f6fff3098/screenshots/api.png)

| Data | Source | How |
|---|---|---|
| Daily prices (gold, Bitcoin, AUDCAD, EURAUD) | Yahoo Finance | `yfinance`, tickers `GC=F` (gold futures, labelled XAUUSD), `BTC-USD`, `AUDCAD=X`, `EURAUD=X` |
| NFP and CPI release dates | **FRED API** (St. Louis Fed) | `api.stlouisfed.org/fred/release/dates`, release IDs NFP = 50 and CPI = 10 |
| FOMC meeting dates | Federal Reserve calendar | 81 decision dates typed into the script, because FRED's FOMC release lists almost every day and can't be used |

![Pulling daily prices with yfinance](images/python_pull_prices.png)
*Goal: download 10 years of daily prices for the four assets and save them untouched as `data/prices_raw.csv`.*

![Pulling release dates from the FRED API](images/python_fred_api_events.png)
*Goal: call the FRED API for every NFP and CPI release date in the window. Result: NFP 122 dates, CPI 126 dates, FOMC 81 dates.*

### Step 2: Check, clean and merge (`python/02_check_and_merge.py`)
![alt text](https://github.com/JaysonJob/Forex-master/blob/e1be2df696dc07fdfd6c506b162545131a34b942/screenshots/getting%20data%20in%20python.png)
The raw files stay untouched. The second script checks them, fixes what it finds, and merges them into **one table** with a single `event_name` column.

![Data quality checks in Python](images/python_data_checks.png)
*Goal: look for missing values, duplicates, impossible candles and missing days before fixing anything.*

| Check | Finding | Action |
|---|---|---|
| Missing values, duplicates | 0 | None needed |
| Impossible candles | 177 forex candles (AUDCAD 85, EURAUD 92) closed slightly outside the day's high-low range, by at most 0.1% | Widened `high` and `low` to contain the open and close, instead of deleting the days |
| Missing days | XAUUSD starts one day late and misses about 95 weekdays (US holidays) | Left as is |
| Volume | Reported as 0 for forex pairs | Column dropped |
| FOMC dates | FRED's FOMC release returned 3,169 dates | Replaced with the 81 real meeting dates |

Each day is labelled `NFP`, `CPI`, `FOMC`, `CPI, FOMC` (both on one day) or `None`. The final file is `data/forex_master.csv`.

### Step 3: SQL in PostgreSQL (`sql/`)

#### 3a. Is the data complete and clean? (`01_load_and_check.sql`)

![SQL data checks](images/sql_data_checks.png)
*Example query: row count, nulls, duplicates and impossible candles per asset.*
**The question:** before analysing anything, the team wants to know whether the load is complete and clean.
**The query** counts rows per asset, counts empty cells, looks for duplicate days and for candles where the high is below the low.
**The answer:** 11,375 rows (AUDCAD 2,605, BTCUSD 3,653, EURAUD 2,603, XAUUSD 2,514), 0 nulls, 0 duplicates, 0 impossible candles. The data is safe to analyse.

#### 3b. Four views that feed Power BI (`02_views.sql`)
![alt text](https://github.com/JaysonJob/Forex-master/blob/4f09ab80f47ba3f09e54d79ca05ce5a213e7c9d2/screenshots/loading%20the%20table.png)
| View | Content |
|---|---|
| `vw_daily_metrics` | One row per asset per day, with `range_pct` (high-to-low range as % of the open) and `ret_pct` (close vs previous close) |
| `vw_event_impact` | Per asset and event: days, average move, average return, win rate |
| `vw_monthly_performance` | Per asset and month, for seasonality |
| `vw_risk_metrics` | Per asset and day: 30-day volatility and drawdown from the all-time peak |

#### 3c. Example queries: question, method and answer (`03_analysis.sql`)

**Q1. Event days vs normal days: are news days more volatile? (H1)**

![Event-day vs normal-day range](images/sql_q1_event_vs_normal_range.png)
*Example query: average daily range on event days vs normal days, by asset.*

- **The question:** a trading desk wants to know if it should widen its risk limits on NFP, CPI and FOMC days.
- **The query** tags each day as `event` or `no_event`, then compares the average high-to-low range.
- **The answer:** partly true. Event-day ranges are wider for gold (1.52% vs 1.32%), Bitcoin (4.93% vs 4.34%) and AUDCAD (0.69% vs 0.62%). EURAUD shows none (0.68% vs 0.68%).
- **The action:** allow wider stops and smaller positions on news days for gold, Bitcoin and AUDCAD. EURAUD needs no change.

**Q2. Which release matters most for each asset? (H2)**

![Range multiple by event](images/sql_q2_range_by_event.png)
*Example query: how many times wider the range is on each event than on a normal day.*

- **The question:** which release should a gold trader respect most?
- **The query** splits "CPI, FOMC" days into two rows and divides each event's average range by the normal-day average.
- **The answer:** gold reacts most to the Fed: 1.21x on FOMC days, 1.18x on NFP and 1.09x on CPI. Bitcoin reacts most to CPI (1.21x), AUDCAD to NFP (1.17x). EURAUD barely reacts (0.92x to 1.03x).
- **The action:** a gold trader should be most careful around FOMC and NFP.

**Q3. Do wider ranges turn into bigger moves by the close? (H3)**

![Close-to-close move by event](images/sql_q3_close_move_by_event.png)
*Example query: the average close-to-close move on each event, compared with a normal day.*

- **The question:** if the range is wider, is the final move bigger too?
- **The query** compares the average close-to-close move on each event with a normal day.
- **The answer:** mostly no. Gold moves 0.56% on FOMC days against 0.74% normally (0.76x), and every AUDCAD event is below normal (0.85x to 0.93x). Only Bitcoin on CPI (1.34x) and FOMC days (1.12x) and gold on NFP (1.14x) are above normal.
- **The action:** news makes the day noisier, not necessarily more decisive. Don't assume a bigger closing move.

**Q4. Do prices go up or down on news days? (H4)**

![Direction and win rate on event days](images/sql_q4_direction_win_rate.png)
*Example query: average return and share of up days for each asset and event.*

- **The question:** "Gold usually sells off on FOMC days." Is there a direction worth trading?
- **The query** shows the average return and the win rate (share of days that closed higher) for each asset and event.
- **The answer:** false for gold, which averages **+0.17%** on FOMC days and closes higher 58.8% of the time. The best win rates are Bitcoin on FOMC days (59.3%, 81 days), gold on CPI days (58.9%, 124 days) and gold on FOMC days (58.8%, 80 days). The weakest is AUDCAD on NFP days (40.2%, 122 days). With 80 to 126 days behind each figure, gaps this small are not reliable.
- **The action:** use the news calendar to manage risk, not to decide whether to buy or sell.

**Q5. Do the four assets move together? (H5)**

![Correlation of daily returns](images/sql_q5_correlation.png)
*Example query: correlation of daily returns between every pair of assets.*

- **The question:** "Gold and Bitcoin are both alternative assets, so they must move together."
- **The query** pivots weekday returns into one column per asset and calculates the correlation of each pair.
- **The answer:** false. Gold and Bitcoin: **0.11**. Gold and AUDCAD: 0.06. Bitcoin and EURAUD: 0.06. All other pairs are within ±0.03, except **AUDCAD and EURAUD at -0.58**, because both contain the Australian dollar on opposite sides.
- **The action:** gold and Bitcoin spread risk. Holding both Australian dollar pairs mostly cancels itself out.

**Q6. Are there seasonal patterns? (H7)**

![Average return by calendar month](images/sql_q6_seasonality.png)
*Example query: average return and share of up years for each calendar month.*

- **The question:** "Bitcoin is strongest in October." Is that true in the data?
- **The query** averages each asset's monthly return by calendar month and counts how often that month was positive.
- **The answer:** true in this sample. Bitcoin averaged **+16.1%** in October and was up in 8 of 11 years. Gold's best month is January (+2.9%, up in 7 of 10 years). June is weak for both: Bitcoin -4.0% (up in 4 of 10) and gold -1.9% (up in only 2 of 10).
- **The action:** a watch list, not a rule. With about 10 observations per month, luck is a real possibility.

**Q7. Does the event calendar look right? (data validation)**

![Event days per year](images/sql_q7_events_per_year.png)
*Example query: number of NFP, CPI and FOMC days per year.*

- **The question:** "FOMC meets 8 times a year, and NFP and CPI 12 times." Does the data agree?
- **The query** counts distinct event days per year.
- **The answer:** true for FOMC and NFP (8 and 12 a year, with 9 FOMC days in 2020 because of two emergency meetings). CPI shows 13 dates in several years (for example 2017, 2019 and 2020), which points to an extra February date.
- **The action:** about 10 of the 329 flagged dates (seven February CPI dates and three NFP revision dates) are probably not real release days. They are only about 3% of event days, but they are listed under limitations.

**Q8. Which asset gave the best return for the risk taken? (H6)**

![Return and risk summary](images/sql_q8_return_and_risk.png)
*Example query: total return, yearly growth, volatility and Sharpe ratio per asset.*

- **The question:** a client can hold only one of the four. Which pays best for the risk?
- **The query** calculates total return, compounded yearly growth (CAGR), annualised volatility and the Sharpe ratio (return per unit of risk). Bitcoin is annualised over 365 days, the others over about 252.
- **The answer:** Bitcoin has the best Sharpe ratio, but with extreme risk.

| Asset | Total return | Yearly growth | Yearly volatility | Sharpe |
|---|---|---|---|---|
| Bitcoin | +12,833% | 62.6% | 66.9% | 1.07 |
| Gold | +237% | 12.9% | 17.0% | 0.80 |
| EURAUD | +9.9% | 1.0% | 7.9% | 0.15 |
| AUDCAD | -1.1% | -0.1% | 7.1% | 0.01 |

- **The action:** gold is the steadier choice, with about a quarter of Bitcoin's volatility. The two currency pairs went nowhere over the decade.

**Q9. What is the worst fall an investor would have sat through?**

![Maximum drawdown](images/sql_q9_max_drawdown.png)
*Example query: the biggest fall from a previous peak for each asset, and the date it happened.*

- **The question:** how much could an investor have lost at the worst moment?
- **The query** compares each day's close with the highest close so far and keeps the lowest point.
- **The answer:** Bitcoin **-83.4%** (15 Dec 2018), gold **-24.9%** (16 Jul 2026), EURAUD -24.1% (26 Aug 2022), AUDCAD -19.6% (23 Mar 2020).
- **The action:** size Bitcoin for a repeat of an 83% fall. Gold's July 2026 fall is its largest of the decade.

### Step 4: Power BI report (`powerbi/power_bi.pbix`)

**Connection and model.** Power BI connects to PostgreSQL (*Get data > PostgreSQL database*, server `localhost:5432`, schema `forex_cascade`, **Import** mode) and loads the four views as separate tables (the `vw_daily_metrics` query is named `fact table`). Two lookup tables link them: `dim_symbol` (one row per asset) and `dim_date` (one row per day).

```dax
dim_symbol = DISTINCT('fact table'[symbol])
dim_date   = CALENDAR(DATE(2016,10,10), DATE(2026,10,10))
Avg Range Event Days  = CALCULATE(AVERAGE('fact table'[range_pct]), 'fact table'[event_name] <> "None")
Avg Range Normal Days = CALCULATE(AVERAGE('fact table'[range_pct]), 'fact table'[event_name] = "None")
Range x vs Normal     = DIVIDE([Avg Range Event Days], [Avg Range Normal Days])
```

#### Page 1: Executive Report

![Executive report page](images/dashboard_1_executive_report.png)
*Goal: a one-page summary for a reader who has two minutes.*

**What it shows:** the report looks at ten years of gold, Bitcoin, AUDCAD and EURAUD and asks whether big US news days make them move more. Bitcoin returned +12,833% but fell 83% at its worst, while gold returned +237% with a worst fall of 25%. News days have 12% to 15% wider daily ranges for gold, Bitcoin and AUDCAD, but there is no reliable direction to trade on and the closing move is not reliably larger.

#### Page 2: Analysis dashboard

![Analysis dashboard](images/dashboard_2_analysis.png)
*Goal: an overview of the dataset, with event-day counts, volatility over time and drawdowns.*

**What it shows:** the cards confirm 11,375 trading days and the event days: **126 CPI, 122 NFP and 81 FOMC** (six days carry both CPI and FOMC). The volatility lines show Bitcoin's 30-day volatility averaging about 3.2% a day, gold's about 1.0% and the currency pairs' below 0.5%. The drawdown lines show that Bitcoin's falls are far deeper than the others (-83% at its low in December 2018, against -25% for gold, -24% for EURAUD and -20% for AUDCAD).

#### Page 3: Risk and Events dashboard

![Risk and events dashboard](images/dashboard_3_risk_and_events.png)
*Goal: show how each asset reacts to each type of news.*

**What it shows:** the event charts compare the daily range on event days with normal days. Gold (1.52% vs 1.32%), Bitcoin (4.93% vs 4.34%) and AUDCAD (0.69% vs 0.62%) are wider on event days, while EURAUD is unchanged. Gold's biggest reaction is to FOMC (1.21x) and NFP (1.18x). The win-rate view shows most results between 49% and 59%, with the extremes (59% for Bitcoin on FOMC days, 40% for AUDCAD on NFP days) resting on 80 to 126 days, so there is no dependable direction.

#### Page 4: Insights and Recommendations

![Insights and recommendations page](images/dashboard_4_insights_recommendations.png)
*Goal: turn the results into five insights and five actions.*

**What it shows:** the main insights are that Bitcoin pays most and hurts most, gold is the steadier performer, news days are wider but not wilder by the close, there is no reliable direction on news days, and the assets rarely move together. The recommendations are to allow more room on news days, not to trade a direction from the news alone, to size Bitcoin for its worst case, to use gold as the steady core, and to test hourly data and forecast surprises next.

---

## Key findings

- **Return and risk differ enormously.** Bitcoin: +12,833%, worst fall -83%. Gold: +237%, worst fall -25%.
- **News days are wider, not wilder by the close.** Ranges are 12% to 15% wider for gold, Bitcoin and AUDCAD, but the closing move is not reliably larger.
- **No reliable direction on news days.** Win rates top out near 59% on 80 to 126 days.
- **Good diversification.** Gold and Bitcoin correlate at 0.11. AUDCAD and EURAUD at -0.58 (the shared Australian dollar).
- **Where things stand (10 Oct 2026).** Bitcoin is about 34% below its October 2025 peak, and gold about 21% below its January 2026 peak.

---

## Repository structure

```
├── README.md
├── requirements.txt
├── .gitignore
├── python/
│   ├── 01_pull_data.py               # pull prices (yfinance) and event dates (FRED API)
│   └── 02_check_and_merge.py         # check, clean, merge, save forex_master.csv
├── data/
│   ├── prices_raw.csv                # prices as downloaded
│   ├── event_dates_raw.csv           # NFP, CPI (FRED API) and FOMC dates
│   └── forex_master.csv              # final merged dataset (11,375 rows)
├── sql/
│   ├── 00_one_step_setup.sql         # schema, table and all data in one file
│   ├── 01_load_and_check.sql         # alternative: manual CSV import and data checks
│   ├── 02_views.sql                  # the 4 views used by Power BI
│   └── 03_analysis.sql               # example queries answering the business questions
├── powerbi/
│   └── power_bi.pbix                 # the 4-page report
└── images/                           # screenshots used in this README
```

---

## Data dictionary

`data/forex_master.csv` (and the table `forex_master`)

| Column | Meaning |
|---|---|
| `symbol` | XAUUSD, BTCUSD, AUDCAD or EURAUD |
| `day` | Trading date |
| `open`, `high`, `low`, `close` | Daily prices (XAUUSD: USD per troy ounce, gold futures `GC=F`; BTCUSD: USD per Bitcoin, AUDCAD: CAD per AUD, EURAUD: AUD per EUR) |
| `event_name` | `None`, `NFP`, `CPI`, `FOMC` or `CPI, FOMC` |

Prices are in different currencies, so the analysis compares **returns**, never raw prices.

**Two lessons learned while building this:**
- **Use `numeric`, not `int`, for prices.** An `int` column rounded AUDCAD's 0.99 to 1 and turned every percentage into 0.
- **Use close-to-close returns for forex.** Yahoo's forex candles have `open = close` on about 36% of days, which made open-to-close volatility roughly 16 times too small.

---

## Limitations and next steps

**Limitations**
- **Daily data only.** A daily candle blends the few minutes of news reaction with the rest of the day, which dilutes the effect.
- **No forecast data.** The analysis shows that news happened, not whether it beat or missed expectations.
- **Event dates.** About 10 of the 329 flagged dates may not be true release days. These include seven February CPI dates, and they affect Bitcoin's CPI figures most. The two emergency FOMC meetings of March 2020 are included.
- **Yahoo Finance** is free but not an official price feed. Forex candles often show `open = close`.
- **Gold is a futures series (`GC=F`), not the spot price.** It tracks spot gold closely, but it follows the front-month contract, so contract roll-overs can cause small price jumps, and it misses about 95 weekdays (futures-market holidays).
- **Small samples.** Each event has only 80 to 126 days, and each calendar month about 10 observations.
- Bitcoin trades every day and the other assets only on weekdays, so correlations use weekday returns only.

**Next steps**
- Repeat the study with hourly data around release times (Dukascopy or HistData).
- Add consensus-versus-actual figures to test whether the surprise matters more than the release.
- Add more assets (silver, oil, EURUSD) and a simple backtest.

## Author

*Jayson Kibet* · [https://www.linkedin.com/in/jayson-kibet-/](#) 

*Data sources: Federal Reserve Bank of St. Louis, FRED® API (NFP and CPI release dates); Yahoo Finance (prices); Federal Reserve Board (FOMC meeting calendar).*
