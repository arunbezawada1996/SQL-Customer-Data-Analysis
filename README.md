This project provides a comprehensive SQL-based reporting framework for analyzing **Sales, Customers, and Products** within a modern data warehouse environment. 

It utilizes a combination of fact and dimension tables (Kimball-style star schema) to deliver key business intelligence metrics such as:

- **Change-over-time sales trends** (daily, monthly, yearly)
- **Cumulative sales analysis**
- **Year-over-year product performance comparison**
- **Customer segmentation** (VIP, Regular, New)
- **Product segmentation** (High-Performer, Mid-Range, Low-Performer)
- **Part-to-whole category contribution**
- **Detailed customer and product reports with key KPIs**

The SQL scripts are modular, well-documented, and designed to support both **operational reporting** and **strategic decision-making**. They can easily be integrated into BI tools such as Power BI, Tableau, or Looker.

---

## 📂 Data Sources

| Table | Description |
|-------|-------------|
| `gold.fact_sales` | Sales transaction fact table |
| `gold.dim_customers` | Customer dimension table |
| `gold.dim_products` | Product dimension table |

---

## 🔥 SQL Modules & Analytics

### 1️⃣ Change Over Time Analysis

- Daily Sales Trend
- Monthly Sales Aggregation
- New Customers by Year

### 2️⃣ Cumulative Sales Analysis

- Running total sales over time

### 3️⃣ Year-Over-Year Product Performance

- Current sales vs historical average sales per product
- Year-over-year growth comparisons

### 4️⃣ Part-to-Whole Category Contribution

- Category-level contribution to total revenue

### 5️⃣ Data Segmentation

- Product Cost Segmentation
- Customer Spending Segmentation

### 6️⃣ Customer Report View

- Create view `gold.report_customers` for customer-level analytics and segmentation

### 7️⃣ Product Report View

- Create view `gold.report_products` for product-level analytics and segmentation

---

## 📊 Example Use Cases

- Executive dashboards for leadership teams
- Marketing campaign segmentation
- Product portfolio management
- Inventory optimization
- Customer lifetime value modeling (CLV)
- Yearly performance reports

---
