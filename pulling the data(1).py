#!/usr/bin/env python
# coding: utf-8

# In[17]:


# Import the libraries, set the date range (10 years up to 10 Oct 2026),
# and create the data folder if it doesn't exist yet.
# Install once if needed: pip install yfinance requests pandas
import yfinance as yf
import pandas as pd
import requests
import os
FRED_KEY = "beb0dba3638af432b1a6eee59d23c78f"


# In[18]:


#set the date range (10 years up to 10 Oct 2026),
# and create the data folder if it doesn't exist yet.
START = "2016-10-10"
END = "2026-10-10"
FRED_KEY = "beb0dba3638af432b1a6eee59d23c78f"   # free key from fred.stlouisfed.org

os.makedirs("data", exist_ok=True)


# In[5]:


# Download daily prices for the four pairs from Yahoo Finance,stack them into one table and save the raw result.Yahoo treats the end date as exclusive,
# so we add one day to include 10 Oct.
tickers = {"XAUUSD": "GC=F", "BTCUSD": "BTC-USD",
           "AUDCAD": "AUDCAD=X", "EURAUD": "EURAUD=X"}

frames = []
for name, tk in tickers.items():
    d = yf.download(tk, start=START, end="2026-10-11", interval="1d",
                    auto_adjust=False, progress=False)
    d.columns = [c[0] if isinstance(c, tuple) else c for c in d.columns]
    d = d.reset_index()
    d["symbol"] = name
    print(name, d.shape, d["Date"].min().date(), "to", d["Date"].max().date())
    frames.append(d)

prices = pd.concat(frames, ignore_index=True)
prices.to_csv("data/prices_raw.csv", index=False)


# In[19]:


# Same check as before, but it now prints what FRED actually replied,so we can
# see exactly what is wrong (bad key, wrong ID, or a connection problem).
release_ids = {"NFP": 50, "CPI": 10, "FOMC": 101}

for event, rid in release_ids.items():
    r = requests.get("https://api.stlouisfed.org/fred/release",
                     params={"release_id": rid, "api_key": FRED_KEY, "file_type": "json"},
                     timeout=30)
    print(event, "| status:", r.status_code)
    if r.status_code == 200:
        print("   ->", r.json()["releases"][0]["name"])
    else:
        print("   ->", r.text[:300])


# In[20]:


# Show exactly what Python holds in FRED_KEY: its length and its raw form,
# so any hidden space,quote mark or backtick becomes visible.
print(len(FRED_KEY))
print(repr(FRED_KEY))


# In[24]:


# Download NFP and CPI release dates from FRED, add the FOMC meeting dates
# (typed in by year as month-day), and save everything in ONE file.
rows = []
for name, rid in {"NFP": 50, "CPI": 10}.items():
    r = requests.get("https://api.stlouisfed.org/fred/release/dates", params={
        "release_id": rid, "api_key": FRED_KEY, "file_type": "json",
        "realtime_start": START, "realtime_end": END,
        "include_release_dates_with_no_data": "true", "limit": 10000})
    r.raise_for_status()
    rows += [{"event": name, "date": x["date"]} for x in r.json()["release_dates"]
             if START <= x["date"] <= END]

fomc = {
    2016: "11-02 12-14",
    2017: "02-01 03-15 05-03 06-14 07-26 09-20 11-01 12-13",
    2018: "01-31 03-21 05-02 06-13 08-01 09-26 11-08 12-19",
    2019: "01-30 03-20 05-01 06-19 07-31 09-18 10-30 12-11",
    2020: "01-29 03-03 03-15 04-29 06-10 07-29 09-16 11-05 12-16",
    2021: "01-27 03-17 04-28 06-16 07-28 09-22 11-03 12-15",
    2022: "01-26 03-16 05-04 06-15 07-27 09-21 11-02 12-14",
    2023: "02-01 03-22 05-03 06-14 07-26 09-20 11-01 12-13",
    2024: "01-31 03-20 05-01 06-12 07-31 09-18 11-07 12-18",
    2025: "01-29 03-19 05-07 06-18 07-30 09-17 10-29 12-10",
    2026: "01-28 03-18 04-29 06-17 07-29 09-16",
}
rows += [{"event": "FOMC", "date": f"{y}-{md}"} for y, s in fomc.items() for md in s.split()]

events = pd.DataFrame(rows)
events.to_csv("data/event_dates_raw.csv", index=False)
print(events.groupby("event").size())


# In[ ]:





# In[ ]:





# In[ ]:




