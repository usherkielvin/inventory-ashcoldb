-- Invoicing module
-- Billing document generated from a confirmed/completed SalesOrder.

## Tables

| Column | Type | Notes |
|--------|------|-------|
| `InvoiceId` | `BIGINT IDENTITY` | PK |
| `InvoiceNumber` | `NVARCHAR(32)` | Unique billing reference (e.g. `INV-2026-001`) |
| `SalesOrderId` | `BIGINT FK` | Parent sales order |
| `InvoiceDate` | `DATETIME2(0)` | Date issued |
| `SubTotal` | `DECIMAL(18,4)` | Sum of line totals (before tax) |
| `TaxAmount` | `DECIMAL(18,4)` | VAT / applicable tax |
| `TotalAmount` | `DECIMAL(18,4)` | SubTotal + TaxAmount |
| `PaymentStatus` | `NVARCHAR(32)` | `UNPAID` · `PARTIAL` · `PAID` |
| `IsDeleted` / `DeletedAt` | | Soft-delete pattern |

## Key business rules

- An invoice is always linked to exactly one `SalesOrder` (1:1 in practice; schema allows 1:N).
- `TotalAmount` must equal `SubTotal + TaxAmount` (validated at insert; no computed column to allow manual overrides).
- Only `CONFIRMED`, `SHIPPED`, or `COMPLETED` orders should be invoiced.
- Philippine VAT rate example: 12 % of `SubTotal`.

## Sample queries

```sql
-- List all unpaid invoices with customer and order details
SELECT * FROM dbo.vw_InvoiceSummary WHERE PaymentStatus = N'UNPAID';

-- Mark invoice as paid
UPDATE dbo.Invoices
SET PaymentStatus = N'PAID'
WHERE InvoiceNumber = N'INV-2026-003';

-- Revenue by month (use vw_InvoiceSummary)
SELECT
    FORMAT(InvoiceDate, 'yyyy-MM') AS Month,
    SUM(TotalAmount)               AS Revenue,
    COUNT(*)                       AS InvoiceCount
FROM dbo.vw_InvoiceSummary
WHERE PaymentStatus IN (N'PAID', N'PARTIAL')
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM')
ORDER BY Month;
```

## Related view

`dbo.vw_InvoiceSummary` — joins invoice with sales order, customer, location, and sales rep columns for reporting.
