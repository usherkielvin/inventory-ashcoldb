-- Ashcol Inventory & Sales — create database (SQL Server)
-- Run as login with CREATE DATABASE permission.
-- To recreate from scratch: manually DROP DATABASE AshcolInventory; then run this script.

USE master;
GO

IF DB_ID(N'AshcolInventory') IS NULL
BEGIN
    CREATE DATABASE AshcolInventory
        COLLATE SQL_Latin1_General_CP1_CI_AS;
END;
GO

USE AshcolInventory;
GO
