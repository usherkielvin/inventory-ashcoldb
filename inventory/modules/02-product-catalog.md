# Module 2 — Product catalog

**Tables:** `dbo.ProductCategories`, `dbo.Products`  
**Scripts:** [`../ddl/02_catalog_suppliers.sql`](../ddl/02_catalog_suppliers.sql), [`../triggers/trg_Products_SoftDeleteOnly.sql`](../triggers/trg_Products_SoftDeleteOnly.sql), [`../views/vw_ActiveProductCatalog.sql`](../views/vw_ActiveProductCatalog.sql)

Categories optional **self-parent** for hierarchy. Products carry **SKU**, pricing, **reorder level**, and optional default supplier. **INSTEAD OF DELETE** trigger enforces soft delete.
