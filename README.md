# SQL Data Analytics Project

This project contains SQL scripts for analyzing sales, customers, and products using a data warehouse structure.

The main goal of this project is to create simple analytical reports that help understand customer behavior, product performance, sales trends, and business KPIs.

## Project Overview

This project uses SQL Server and a data warehouse database with tables from the `gold` layer.

Main tables used:

* `gold.fact_sales`
* `gold.dim_customers`
* `gold.dim_products`

## Reports Created

### 1. Customer Report

The customer report creates a view called:

```sql
gold.report_customers
```

This report summarizes customer-level metrics such as:

* Total orders
* Total sales
* Total quantity purchased
* Total products purchased
* Customer age
* Customer age group
* Last order date
* Customer lifespan
* Recency
* Average order value
* Average monthly spend

Customers are also segmented into:

* VIP
* Regular
* Newer

This helps identify valuable customers and understand customer purchasing behavior.

## 2. Product Report

The product report creates a view called:

```sql
gold.report_products
```

This report summarizes product-level metrics such as:

* Product name
* Category
* Subcategory
* Cost
* Total orders
* Total sales
* Total quantity sold
* Total customers
* Last sale date
* Product lifespan
* Average selling price
* Average order revenue
* Average monthly revenue

Products are segmented into:

* High-Performer
* Mid-Range
* Low-Performer

This helps identify best-selling products and products that need improvement.

## Key SQL Concepts Used

This project includes practical SQL concepts such as:

* Joins
* Common Table Expressions
* Aggregate functions
* Window functions
* Data segmentation
* Date calculations
* KPI calculations
* View creation

## Business Questions Answered

This project helps answer questions such as:

* Which products generate the most revenue?
* Which customers are the most valuable?
* How recently did customers place orders?
* What is the average order value?
* Which products are high-performing or low-performing?
* How much revenue does each product generate per month?

## Tools Used

* SQL Server
* SQL Server Management Studio
* Data Warehouse tables

## Purpose of the Project

This project was created to practice SQL data analytics using real business-style reporting logic. It shows how SQL can be used to transform raw sales data into useful business insights.

## Author

Created as part of my SQL Data Analytics learning project.
