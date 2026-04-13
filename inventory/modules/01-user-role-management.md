# Module 1 — User & role management (mandatory)

**Tables:** `dbo.Roles`, `dbo.Users`, `dbo.UserRoles`  
**Scripts:** [`../ddl/01_users_roles.sql`](../ddl/01_users_roles.sql)

Supports **Administrator**, **Staff**, and **Standard User** via `Roles.RoleName`. Application layer enforces privileges; the database stores assignments and unique emails. **Soft delete** on `Users` via `IsDeleted` / `DeletedAt`.
