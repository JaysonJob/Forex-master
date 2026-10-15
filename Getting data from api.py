#!/usr/bin/env python
# coding: utf-8

# In[1]:


#geting the relevant libraries
import requests


# In[2]:


import pandas as pd


# In[3]:


import time


# In[4]:


import os


# In[6]:


os.makedirs("data", exist_ok=True)


# In[7]:


# If api.binance.com is blocked for you (error 451/403), try the market-data mirror:
BASE_URL = "https://api.binance.com/api/v3/klines"


# In[9]:


# BASE_URL = "https://data-api.binance.vision/api/v3/klines"

COLS = ["open_time", "open", "high", "low", "close", "volume",
        "close_time", "quote_volume", "trades",
        "taker_buy_base", "taker_buy_quote", "ignore"]


# In[10]:


def fetch_klines(symbol, interval="1h", start="2024-01-01", end="2026-10-01"):
    start_ms = int(pd.Timestamp(start).timestamp() * 1000)
    end_ms = int(pd.Timestamp(end).timestamp() * 1000)
    rows = []

    while start_ms < end_ms:
        params = {"symbol": symbol, "interval": interval,
                  "startTime": start_ms, "endTime": end_ms, "limit": 1000}
        r = requests.get(BASE_URL, params=params, timeout=15)
        r.raise_for_status()
        data = r.json()
        if not data:
            break
        rows.extend(data)
        start_ms = data[-1][0] + 1
        time.sleep(0.2)

    df = pd.DataFrame(rows, columns=COLS)
    df["symbol"] = symbol
    return df


# In[11]:


symbols = ["BTCUSDT", "ETHUSDT", "SOLUSDT"]   # add or remove coins here

frames = []
for s in symbols:
    print(f"Fetching {s}...")
    frames.append(fetch_klines(s))

raw = pd.concat(frames, ignore_index=True)
print(raw.shape)
raw.head()


# In[13]:


# CSV (recommended for this size)
raw.to_csv("data/crypto_1h_raw.csv", index=False)


# In[ ]:




