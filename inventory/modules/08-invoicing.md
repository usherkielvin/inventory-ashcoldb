# Module 8 — Invoicing

**Tables:** `dbo.Invoices`  
**Scripts:** [`../ddl/05_customers_sales.sql`](../ddl/05_customers_sales.sql)

Invoice header tied 1:1 (conceptually) to a **sales order**; tracks **payment status** and amounts. Extend with `Payments` table if the syllabus requires explicit payment rows.
