# 📊 Data Catalog — Gold Layer

## Overview
The **Gold Layer** represents the business-oriented data model, designed to support reporting, dashboards, and analytical use cases.  
It is built from **dimension tables** (descriptive attributes) and **fact tables** (business metrics).

---

## 1. `gold.dim_customers`

**Purpose:**  
Holds enriched customer details, including demographic and geographic attributes, for analytics and reporting.

**Columns:**

| Column Name     | Data Type     | Description                                                                 |
|-----------------|---------------|-----------------------------------------------------------------------------|
| customer_key    | INT           | Surrogate key uniquely identifying each customer in the dimension table.    |
| customer_id     | INT           | Business identifier of the customer.                                        |
| customer_number | NVARCHAR(50)  | Alphanumeric customer code used for tracking and referencing.               |
| first_name      | NVARCHAR(50)  | Customer’s first name.                                                      |
| last_name       | NVARCHAR(50)  | Customer’s last (family) name.                                              |
| country         | NVARCHAR(50)  | Country of residence (e.g., *Australia*).                                   |
| marital_status  | NVARCHAR(50)  | Marital status (e.g., *Married*, *Single*).                                 |
| gender          | NVARCHAR(50)  | Gender (e.g., *Male*, *Female*, *n/a*).                                     |
| birthdate       | DATE          | Customer’s date of birth (YYYY-MM-DD).                                      |
| create_date     | DATE          | Record creation date in the source system.                                  |

---

## 2. `gold.dim_products`

**Purpose:**  
Provides product-related attributes used for categorization, pricing, and product line analysis.

**Columns:**

| Column Name         | Data Type     | Description                                                                 |
|---------------------|---------------|-----------------------------------------------------------------------------|
| product_key         | INT           | Surrogate key uniquely identifying each product record.                     |
| product_id          | INT           | Business identifier of the product.                                         |
| product_number      | NVARCHAR(50)  | Alphanumeric product code (commonly used for tracking/inventory).           |
| product_name        | NVARCHAR(50)  | Descriptive product name (e.g., type, color, size).                         |
| category_id         | NVARCHAR(50)  | Identifier for the product’s category.                                      |
| category            | NVARCHAR(50)  | High-level classification (e.g., *Bikes*, *Components*).                    |
| subcategory         | NVARCHAR(50)  | More detailed classification within the category.                           |
| maintenance_required| NVARCHAR(50)  | Indicates if maintenance is required (*Yes* / *No*).                         |
| cost                | INT           | Product cost (base price in monetary units).                                |
| product_line        | NVARCHAR(50)  | Product line or series (e.g., *Road*, *Mountain*).                          |
| start_date          | DATE          | Availability start date.                                                    |

---

## 3. `gold.fact_sales`

**Purpose:**  
Contains transactional sales data to enable financial and operational reporting.

**Columns:**

| Column Name   | Data Type     | Description                                                                 |
|---------------|---------------|-----------------------------------------------------------------------------|
| order_number  | NVARCHAR(50)  | Unique identifier of the sales order (e.g., *SO54496*).                      |
| product_key   | INT           | Foreign key referencing the product dimension.                              |
| customer_key  | INT           | Foreign key referencing the customer dimension.                             |
| order_date    | DATE          | Date the order was placed.                                                  |
| shipping_date | DATE          | Date the order was shipped.                                                 |
| due_date      | DATE          | Payment due date.                                                           |
| sales_amount  | INT           | Total sales amount (currency units).                                        |
| quantity      | INT           | Number of product units sold.                                               |
| price         | INT           | Price per unit (currency units).                                            |

---
