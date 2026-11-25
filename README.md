<div align="center">

# FinSight

### Turning financial data into actionable intelligence.

**A banking customer intelligence platform that transforms customer data into insights for smarter business decisions.**

<br>

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1?logo=postgresql&logoColor=white)
![Status](https://img.shields.io/badge/Status-Active%20Development-orange)

</div>

---

## Overview

Banks collect vast amounts of customer and transaction data every day. However, raw data alone does not tell decision-makers **where to focus, who to prioritize, or what action to take next.**

**FinSight** is a banking customer intelligence platform designed to bridge that gap.

It brings together customer analytics, churn intelligence, customer value analysis, and cross-sell opportunities into a single platform.

FinSight is built around three fundamental questions:

| Question | Intelligence |
|---|---|
| **Who is at risk?** | Identify customers who may be at risk of leaving. |
| **Who matters most?** | Identify high-value customer relationships. |
| **What should happen next?** | Identify potential cross-sell opportunities and recommended actions. |

---

## Core Features

### Churn Intelligence

FinSight analyzes customer activity and behavioral indicators to classify customers according to their potential churn risk.

**Risk levels:**

- 🟢 Low Risk
- 🟡 Medium Risk
- 🔴 High Risk

This allows banking teams to identify customers who may require retention attention before they become inactive or leave.

---

### Customer Value

The Customer Value module helps identify customers who represent stronger business value to the bank.

It considers factors such as:

- Average balance
- Monthly income
- Transaction activity
- Number of products
- Customer value score
- Account characteristics

Customers can then be grouped into value segments for easier analysis and prioritization.

---

### Cross-Sell Intelligence

FinSight identifies customers who may have opportunities for additional financial products.

Rather than treating every customer the same, the platform uses customer characteristics and behavioral indicators to identify potential opportunities and recommend relevant products and actions.

The goal is to help answer:

> **Which customer should we approach, with which product, and why?**

---

### Customer Intelligence

The Customers section provides a searchable view of individual customer records.

Analysts can move from:

**Bank-wide analytics → Customer segments → Individual customers**

This makes it possible to investigate the customer-level information behind the aggregate statistics.

---

### Analytics Dashboard

The main dashboard provides a high-level view of customer intelligence, including:

- Total customers
- High-risk customers
- High-value customers
- Cross-sell opportunities
- Churn risk distribution
- Priority actions

---

### CSV Export

Customer intelligence data can be exported to CSV for further analysis or use by other banking teams, including:

- Customer retention
- Sales
- Relationship management
- Business analytics

---

## How FinSight Works

```text
Customer & Transaction Data
            │
            ▼
     Supabase / PostgreSQL
            │
            ▼
      Analytics & Scoring
            │
            ▼
       FinSight Dashboard
            │
      ┌─────┼─────┐
      ▼     ▼     ▼
    Churn  Value  Cross-Sell
      │     │       │
      └─────┼───────┘
            ▼
      Business Actions
```

---

## Technology Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter / Dart |
| **Backend** | Supabase |
| **Database** | PostgreSQL |
| **Analytics** | Customer behavioral scoring |
| **Analytics** | Churn risk analysis |
| **Analytics** | Customer value scoring |
| **Analytics** | Cross-sell opportunity analysis |

---

## Architecture

```text
                    ┌─────────────────────┐
                    │   FinSight Client   │
                    │      Flutter        │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │      Supabase       │
                    │     Backend Layer   │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │     PostgreSQL      │
                    │      Database       │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Analytics & Scoring │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
         Churn Risk       Customer Value    Cross-Sell
              │                │                │
              └────────────────┼────────────────┘
                               ▼
                    ┌─────────────────────┐
                    │  Business Actions   │
                    └─────────────────────┘
```

---

## Screenshots

### Dashboard

<p align="center">
  <img src="screenshots/dashboard.png" width="850" alt="FinSight Dashboard">
</p>

### Customer Intelligence

<p align="center">
  <img src="screenshots/customers.png" width="850" alt="FinSight Customer Intelligence">
</p>

### Churn Intelligence

<p align="center">
  <img src="screenshots/churn.png" width="850" alt="FinSight Churn Intelligence">
</p>

---

## Why FinSight?

FinSight is built around a simple principle:

> **Data becomes valuable when it leads to a decision.**

Instead of presenting banking data as disconnected tables and statistics, FinSight organizes customer intelligence around practical business questions.

The platform helps banking teams move from:

**Data → Information → Intelligence → Action**

---

## Project Purpose

FinSight aims to help financial institutions:

- Identify customers at risk of leaving
- Prioritize high-value customer relationships
- Discover targeted cross-sell opportunities
- Improve customer retention strategies
- Support relationship managers with actionable intelligence
