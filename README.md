# 🍊 Swiggy Sales Analysis

> End-to-end data analysis project on 197,430 Swiggy orders across 28 Indian cities.  
> Built using Python (EDA complete) · SQL Server (in progress) · Power BI (in progress)

---

## 📌 Project Status

| Phase | Tool | Status |
|---|---|---|
| Data Cleaning & EDA | Python (pandas, seaborn) | ✅ Complete |
| Business Queries | SQL Server | 🔄 In Progress |
| Dashboard | Power BI | 🔄 In Progress |

---

## 📂 Dataset

**197,430 orders · Jan–Aug 2025 · 5-table star schema**

| Table | Rows | Description |
|---|---|---|
| `fact_orders` | 197,430 | Core order records — price, rating, rating_count, foreign keys |
| `dim_date` | 243 | Date dimension — year, month, day_of_week, is_weekend |
| `dim_restaurants` | 993 | Restaurant names |
| `dim_locations` | 995 | State, city, and locality across 28 Indian cities |
| `dim_dish` | 82,891 | Dish names and food categories |

>  Raw CSVs available in `/data/Raw/`.
>  Cleaned CSVs available in `/data/cleaned/`.

---

## 🛠️ Tools & Technologies used and will be used for further analysis -

![SQL](https://img.shields.io/badge/SQL-Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Excel](https://img.shields.io/badge/Excel-217346?style=for-the-badge&logo=microsoftexcel&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-150458?style=for-the-badge&logo=pandas&logoColor=white)

---

## 🔍 Key Findings (Python EDA)

### 💰 Order Value
- **Average order value: ₹268.51** · Median: ₹229 · Range: ₹0.95 – ₹8,000
- IQR outlier threshold at **₹614** — 9,876 orders (5%) flagged as high-value (bulk/corporate orders)
- Price–rating correlation is near zero (**r ≈ 0.03**) — customers don't equate higher price with higher quality

### 🏆 Restaurant Performance
- **KFC leads in revenue at ₹42.5L** (12,961 orders · AOV ₹328) despite McDonald's having more orders (13,530)
- **McDonald's AOV is ₹247 vs KFC's ₹328** — a ₹81/order gap explains the revenue difference entirely
- **Domino's Pizza has the highest AOV among QSR chains at ₹334** with 5,492 orders
- **Olio – The Wood Fired Pizzeria** tops all restaurants at ₹381 AOV on just 3,241 orders — classic premium segment

### 🍕 Category Analysis
- **`Recommended`** dominates all categories: ₹71.9L revenue across 24,100 orders — strongest signal of repeat customer loyalty
- **`Main Course`** (₹7.6L) and **`Burger Combos`** (₹5.1L) are volume-driver discovery categories
- **`Freshly Scooped Tubs`** has the highest AOV at ₹414 across 952 orders — high-margin, underleveraged upsell opportunity
- **`Korean Spicy Fest`** (₹343 AOV) and **`Burger Combos`** (₹381 AOV) confirm premium combos outperform standard items on spend
- **`Desserts`** has the lowest AOV at ₹141 despite 2,944 orders — best positioned as an add-on, not a standalone order driver

### 📅 Time Trends
- **W-shaped monthly pattern**: Jan peak (25K orders) → Feb dip → Mar–Apr recovery → May peak (26K) → Jun dip → Jul–Aug recovery
- **Weekdays drive 71% of orders** (140K vs 57K) and ₹3.76 Cr in revenue vs ₹1.54 Cr on weekends
- Despite the volume gap, **AOV is identical on weekdays and weekends (₹268)** — targeted weekend promotions on delivery fees (not discounts) could close the gap

### 🗺️ Geography
- **Bengaluru leads in order volume** (80 localities, ₹53L) — nearly 2x the next city (Lucknow at ₹30L)
- The remaining 9 cities are tightly clustered between ₹24L–₹30L — even penetration outside Bengaluru
- **Panaji leads in AOV at ~₹305**, suggesting a smaller but higher-spending customer base
- AOV is remarkably flat across all cities (~₹275–₹305) — no city shows extreme premium or budget behavior

---

## 📓 Notebook Walkthrough

**`notebooks/Swiggy_sales_analysis.ipynb`**

| Section | What's Covered |
|---|---|
| Data Loading | 5 CSVs loaded from star schema structure |
| Data Quality Checks | `.shape`, `.info()`, `.isnull()`, `.duplicated()`, `.describe()` on all 5 tables |
| Date Fix & Feature Engineering | `order_date` dtype fix · Added `year`, `month`, `month_name`, `day_of_week`, `is_weekend` |
| Outlier Detection | IQR method — upper fence ₹614, 5% flagged as high-value |
| Restaurant Analysis | Revenue, AOV, order count — top 10 ranked by total revenue |
| Dish Analysis | Top 10 dishes by revenue, premium pricing pattern |
| Category Analysis | Revenue, AOV, and order count across all food categories — top 10 ranked |
| Time Trends | Monthly order + revenue trend (Jan–Aug), W-shaped pattern identified |
| Weekend vs Weekday | Revenue, orders, and AOV split — 71% weekday dominance |
| City Analysis | Top 10 cities by revenue and by AOV — Bengaluru vs Panaji contrast |
| Price vs Rating | Boxplot + correlation (r ≈ 0.03) — no meaningful relationship |

---

## 🗂️ Repository Structure

```
swiggy-sales-analysis/
│
├── data/
│   └── cleaned/
│       ├── fact_orders.csv
│       ├── dim_date.csv
│       ├── dim_restaurants.csv
│       ├── dim_locations.csv
│       └── dim_dish.csv
│
├── notebooks/
│   └── Swiggy_sales_analysis.ipynb
│
├── sql/                          ← coming soon
│   ├── 01_create_tables.sql
│   ├── 02_basic_kpi_queries.sql
│   ├── 03_restaurant_analysis.sql
│   ├── 04_time_trends.sql
│   ├── 05_geography.sql
│   ├── 06_dish_category.sql
│   └── 07_advanced_window_functions.sql
│
├── powerbi/                      ← coming soon
│   └── Swiggy_Dashboard.pbix
│
├── screenshots/                  ← coming soon
│   └── dashboard_preview.png
│
└── README.md
```

---

## 🚀 How to Run the Notebook

```bash
# 1. Clone the repo
git clone https://github.com/sourabh0020/swiggy-sales-analysis-.git
cd swiggy-sales-analysis-

# 2. Install dependencies
pip install pandas numpy matplotlib seaborn jupyter

# 3. Launch the notebook
jupyter notebook notebooks/Swiggy_sales_analysis.ipynb
```

> Run `Kernel → Restart & Run All` to execute end-to-end cleanly.

---

## 🗺️ Roadmap

- [x] Data cleaning & EDA in Python
- [x] Category-wise revenue, AOV, and order analysis
- [ ] SQL Server DDL — create tables, load CSVs
- [ ] 20+ business SQL queries (KPIs, window functions, CTEs)
- [ ] Power BI star schema data model
- [ ] Power BI 4-page interactive dashboard
- [ ] Dashboard screenshot in README

---

## 🧠 Skills Demonstrated

`Exploratory Data Analysis` · `Star Schema / Data Modeling` · `Feature Engineering` · `Outlier Detection (IQR)` · `Category & Menu Analysis` · `pandas` · `seaborn` · `matplotlib` · `Business Insight Communication`

---

## 👤 Author

Sourabh Yadav  
Sourabhsubh20@gmail.com
[LinkedIn](https://www.linkedin.com/in/sourabhyadav96/) · [GitHub](https://github.com/sourabh0020)

---

*This project is part of my data analyst portfolio. Feedback welcome — open an issue or connect on LinkedIn.*
