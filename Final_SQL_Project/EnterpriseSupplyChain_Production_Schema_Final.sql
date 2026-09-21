
/*
================================================================================
Enterprise Smart Supply Chain & Logistics Management System
SQL Server - Production-Oriented Initial Schema
================================================================================
Rerunnable design:
- Existing DATABASE / SCHEMAS / TABLES / CONSTRAINTS / INDEXES are not recreated.
- This script is safe to execute repeatedly for objects created by this script.
- NOTE: IF NOT EXISTS does not alter an already-existing table definition.
  Schema changes belong in versioned migration scripts.
- No destructive DROP statements are used.
================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================================
   01. DATABASE
   ============================================================================ */
IF DB_ID(N'EnterpriseSupplyChain') IS NULL
BEGIN
    CREATE DATABASE [EnterpriseSupplyChain];
END
GO

USE [EnterpriseSupplyChain];
GO

/* ============================================================================
   02. SCHEMAS (11 schemas or domains)
   ============================================================================ */
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'organization')
    EXEC(N'CREATE SCHEMA [organization]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'warehouse')
    EXEC(N'CREATE SCHEMA [warehouse]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'catalog')
    EXEC(N'CREATE SCHEMA [catalog]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'procurement')
    EXEC(N'CREATE SCHEMA [procurement]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'inventory')
    EXEC(N'CREATE SCHEMA [inventory]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'sales')
    EXEC(N'CREATE SCHEMA [sales]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'logistics')
    EXEC(N'CREATE SCHEMA [logistics]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'returns')
    EXEC(N'CREATE SCHEMA [returns]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'notifications')
    EXEC(N'CREATE SCHEMA [notifications]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'security')
    EXEC(N'CREATE SCHEMA [security]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'audit')
    EXEC(N'CREATE SCHEMA [audit]');
GO

/* ============================================================================
   03. REFERENCE / MASTER DATA
   ============================================================================ */

IF OBJECT_ID(N'dbo.Currency', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Currency
    (
        CurrencyID      int IDENTITY(1,1) NOT NULL,
        CurrencyCode    char(3) NOT NULL,
        CurrencyName    nvarchar(100) NOT NULL,
        Symbol          nvarchar(10) NULL,
        DecimalPlaces   tinyint NOT NULL
            CONSTRAINT DF_Currency_DecimalPlaces DEFAULT (2),
        IsActive        bit NOT NULL
            CONSTRAINT DF_Currency_IsActive DEFAULT (1),

        CONSTRAINT PK_Currency PRIMARY KEY CLUSTERED (CurrencyID),
        CONSTRAINT UQ_Currency_CurrencyCode UNIQUE (CurrencyCode), 
        CONSTRAINT CK_Currency_Code CHECK (CurrencyCode NOT LIKE '%[^A-Z]%'), 
        CONSTRAINT CK_Currency_DecimalPlaces CHECK (DecimalPlaces BETWEEN 0 AND 2) /*to check that not bigist from 2 decimal value*/
    );
END
GO

IF OBJECT_ID(N'dbo.Address', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Address
    (
        AddressID       bigint IDENTITY(1,1) NOT NULL,
        AddressType     varchar(30) NOT NULL, /* should be one of ('REGISTERED','BILLING','SHIPPING','WAREHOUSE','BRANCH','OTHER')*/
        AddressLine1    nvarchar(250) NOT NULL,
        AddressLine2    nvarchar(250) NULL,
        City            nvarchar(100) NOT NULL,
        State           nvarchar(100) NULL,
        Country         nvarchar(100) NOT NULL,
        PostalCode      nvarchar(30) NULL,
        Latitude        decimal(9,6) NULL,
        Longitude       decimal(9,6) NULL,

        CONSTRAINT PK_Address PRIMARY KEY CLUSTERED (AddressID),
        CONSTRAINT CK_Address_Type CHECK (AddressType IN
            ('REGISTERED','BILLING','SHIPPING','WAREHOUSE','BRANCH','OTHER')),
        CONSTRAINT CK_Address_Latitude CHECK (Latitude IS NULL OR Latitude BETWEEN -90 AND 90),        /*خط العرض */
        CONSTRAINT CK_Address_Longitude CHECK (Longitude IS NULL OR Longitude BETWEEN -180 AND 180)    /*خط الطول */
    );
END
GO

IF OBJECT_ID(N'dbo.TaxRate', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TaxRate
    (
        TaxRateID       int IDENTITY(1,1) NOT NULL,
        EnterpriseID    bigint NOT NULL,
        Name            nvarchar(100) NOT NULL,
        Rate            decimal(9,4) NOT NULL,
        Country         nvarchar(100) NOT NULL,
        IsActive        bit NOT NULL
            CONSTRAINT DF_TaxRate_IsActive DEFAULT (1),
        EffectiveFrom   date NOT NULL,
        EffectiveTo     date NULL,

        CONSTRAINT PK_TaxRate PRIMARY KEY CLUSTERED (TaxRateID),
        CONSTRAINT CK_TaxRate_Rate CHECK (Rate >= 0 AND Rate <= 100),
        CONSTRAINT CK_TaxRate_Dates CHECK (EffectiveTo IS NULL OR EffectiveTo >= EffectiveFrom)
    );
END
GO

/* ============================================================================
   04. ORGANIZATION
   ============================================================================ */

IF OBJECT_ID(N'organization.Enterprise', N'U') IS NULL
BEGIN
    CREATE TABLE organization.Enterprise
    (
        EnterpriseID    bigint IDENTITY(1,1) NOT NULL,
        Name            nvarchar(200) NOT NULL,
        LegalName       nvarchar(250) NOT NULL,
        TaxNumber       nvarchar(100) NULL,
        Status          varchar(20) NOT NULL  /* One of ('ACTIVE','SUSPENDED','CLOSED') */
            CONSTRAINT DF_Enterprise_Status DEFAULT ('ACTIVE'),
        CreatedAt       datetime2(3) NOT NULL  
            CONSTRAINT DF_Enterprise_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_Enterprise PRIMARY KEY CLUSTERED (EnterpriseID),
        CONSTRAINT UQ_Enterprise_Name UNIQUE (Name),
        CONSTRAINT CK_Enterprise_Status CHECK (Status IN ('ACTIVE','SUSPENDED','CLOSED'))
    );
END
GO

IF OBJECT_ID(N'organization.Company', N'U') IS NULL
BEGIN
    CREATE TABLE organization.Company
    (
        CompanyID       bigint IDENTITY(1,1) NOT NULL,
        EnterpriseID    bigint NOT NULL,
        AddressID       bigint NULL,
        Name            nvarchar(200) NOT NULL,
        LegalName       nvarchar(250) NOT NULL,
        TaxNumber       nvarchar(100) NULL,
        CurrencyID      int NOT NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Company_Status DEFAULT ('ACTIVE'),
        CreatedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_Company_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_Company PRIMARY KEY CLUSTERED (CompanyID),
        CONSTRAINT UQ_Company_Name UNIQUE (EnterpriseID, Name),
        CONSTRAINT CK_Company_Status CHECK (Status IN ('ACTIVE','SUSPENDED','CLOSED'))
    );
END
GO

IF OBJECT_ID(N'organization.Branch', N'U') IS NULL
BEGIN
    CREATE TABLE organization.Branch
    (
        BranchID        bigint IDENTITY(1,1) NOT NULL,
        CompanyID       bigint NOT NULL,
        AddressID       bigint NOT NULL,
        Name            nvarchar(150) NOT NULL,
        Code            varchar(50) NOT NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Branch_Status DEFAULT ('ACTIVE'),
        CreatedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_Branch_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_Branch PRIMARY KEY CLUSTERED (BranchID),
        CONSTRAINT UQ_Branch_Code UNIQUE (CompanyID, Code),
        CONSTRAINT CK_Branch_Status CHECK (Status IN ('ACTIVE','INACTIVE','CLOSED'))
    );
END
GO

IF OBJECT_ID(N'organization.Department', N'U') IS NULL
BEGIN
    CREATE TABLE organization.Department
    (
        DepartmentID    bigint IDENTITY(1,1) NOT NULL,
        CompanyID       bigint NOT NULL,
        Name            nvarchar(150) NOT NULL,
        Code            varchar(50) NOT NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Department_Status DEFAULT ('ACTIVE'),

        CONSTRAINT PK_Department PRIMARY KEY CLUSTERED (DepartmentID),
        CONSTRAINT UQ_Department_Code UNIQUE (CompanyID, Code),
        CONSTRAINT CK_Department_Status CHECK (Status IN ('ACTIVE','INACTIVE'))
    );
END
GO

IF OBJECT_ID(N'organization.Employee', N'U') IS NULL
BEGIN
    CREATE TABLE organization.Employee
    (
        EmployeeID      bigint IDENTITY(1,1) NOT NULL,
        FirstName       nvarchar(100) NOT NULL,
        LastName        nvarchar(100) NOT NULL,
        Email           varchar(320) NOT NULL,
        Phone           varchar(30) NULL,
        HireDate        date NOT NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Employee_Status DEFAULT ('ACTIVE'),
        CreatedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_Employee_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_Employee PRIMARY KEY CLUSTERED (EmployeeID),
        CONSTRAINT UQ_Employee_Email UNIQUE (Email),
        CONSTRAINT CK_Employee_Status CHECK (Status IN ('ACTIVE','INACTIVE','TERMINATED','ON_LEAVE'))
    );
END
GO

IF OBJECT_ID(N'organization.Role', N'U') IS NULL
BEGIN
    CREATE TABLE organization.Role
    (
        RoleID          int IDENTITY(1,1) NOT NULL,
        Name            nvarchar(100) NOT NULL,
        Description     nvarchar(500) NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Role_Status DEFAULT ('ACTIVE'),

        CONSTRAINT PK_Role PRIMARY KEY CLUSTERED (RoleID),
        CONSTRAINT UQ_Role_Name UNIQUE (Name),
        CONSTRAINT CK_Role_Status CHECK (Status IN ('ACTIVE','INACTIVE'))
    );
END
GO

/* ============================================================================
   05. WAREHOUSE
   ============================================================================ */

IF OBJECT_ID(N'warehouse.Warehouse', N'U') IS NULL
BEGIN
    CREATE TABLE warehouse.Warehouse
    (
        WarehouseID     bigint IDENTITY(1,1) NOT NULL,
        Name            nvarchar(150) NOT NULL,
        Code            varchar(50) NOT NULL,
        Type            varchar(30) NOT NULL,
        Capacity        decimal(18,3) NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Warehouse_Status DEFAULT ('ACTIVE'),
        AddressID       bigint NOT NULL,
        CreatedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_Warehouse_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_Warehouse PRIMARY KEY CLUSTERED (WarehouseID),
        CONSTRAINT UQ_Warehouse_Code UNIQUE (Code),
        CONSTRAINT CK_Warehouse_Type CHECK (Type IN ('CENTRAL','REGIONAL','DISTRIBUTION','RETURNS','CROSS_DOCK','OTHER')),
        CONSTRAINT CK_Warehouse_Capacity CHECK (Capacity IS NULL OR Capacity >= 0),
        CONSTRAINT CK_Warehouse_Status CHECK (Status IN ('ACTIVE','INACTIVE','CLOSED'))
    );
END
GO

IF OBJECT_ID(N'warehouse.WarehouseZone', N'U') IS NULL
BEGIN
    CREATE TABLE warehouse.WarehouseZone
    (
        ZoneID          bigint IDENTITY(1,1) NOT NULL,
        WarehouseID     bigint NOT NULL,
        Name            nvarchar(100) NOT NULL,
        ZoneType        varchar(30) NOT NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_WarehouseZone_Status DEFAULT ('ACTIVE'),

        CONSTRAINT PK_WarehouseZone PRIMARY KEY CLUSTERED (ZoneID),
        CONSTRAINT UQ_WarehouseZone_Name UNIQUE (WarehouseID, Name),
        CONSTRAINT CK_WarehouseZone_Status CHECK (Status IN ('ACTIVE','INACTIVE'))
    );
END
GO

IF OBJECT_ID(N'warehouse.StorageBin', N'U') IS NULL
BEGIN
    CREATE TABLE warehouse.StorageBin
    (
        BinID           bigint IDENTITY(1,1) NOT NULL,
        ZoneID          bigint NOT NULL,
        WarehouseID     bigint NOT NULL,
        Code            varchar(80) NOT NULL,
        Capacity        decimal(18,3) NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_StorageBin_Status DEFAULT ('ACTIVE'),

        CONSTRAINT PK_StorageBin PRIMARY KEY CLUSTERED (BinID),
        CONSTRAINT UQ_StorageBin_Code UNIQUE (WarehouseID, Code),
        -- Denormalized 'WarehouseID' is kept here to speed up queries (performance) 
        -- and to ensure 'Code' remains unique across the entire warehouse, not just the zone.
        CONSTRAINT CK_StorageBin_Capacity CHECK (Capacity IS NULL OR Capacity >= 0),
        CONSTRAINT CK_StorageBin_Status CHECK (Status IN ('ACTIVE','INACTIVE'))
    );
END
GO

/* ============================================================================
   06. CATALOG
   ============================================================================ */

IF OBJECT_ID(N'catalog.Brand', N'U') IS NULL
BEGIN
    CREATE TABLE catalog.Brand
    (
        BrandID         bigint IDENTITY(1,1) NOT NULL,
        Name            nvarchar(150) NOT NULL,
        Description     nvarchar(1000) NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Brand_Status DEFAULT ('ACTIVE'),

        CONSTRAINT PK_Brand PRIMARY KEY CLUSTERED (BrandID),
        CONSTRAINT UQ_Brand_Name UNIQUE (Name),
        CONSTRAINT CK_Brand_Status CHECK (Status IN ('ACTIVE','INACTIVE'))
    );
END
GO

IF OBJECT_ID(N'catalog.Product', N'U') IS NULL
BEGIN
    CREATE TABLE catalog.Product
    (
        ProductID       bigint IDENTITY(1,1) NOT NULL,
        BrandID         bigint NULL,
        Name            nvarchar(200) NOT NULL,
        Description     nvarchar(max) NULL,
        ProductType     varchar(30) NOT NULL,
        Weight          decimal(18,3) NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Product_Status DEFAULT ('ACTIVE'),
        CreatedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_Product_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_Product PRIMARY KEY CLUSTERED (ProductID),
        CONSTRAINT CK_Product_Weight CHECK (Weight IS NULL OR Weight >= 0),
        CONSTRAINT CK_Product_Status CHECK (Status IN ('ACTIVE','INACTIVE','DISCONTINUED'))
    );
END
GO

IF OBJECT_ID(N'catalog.ProductVariant', N'U') IS NULL
BEGIN
    CREATE TABLE catalog.ProductVariant
    (
        VariantID       bigint IDENTITY(1,1) NOT NULL,
        ProductID       bigint NOT NULL,
        SKU             varchar(100) NOT NULL,
        Barcode         varchar(100) NULL,
        Color           nvarchar(80) NULL,
        Size            nvarchar(80) NULL,
        Weight          decimal(18,3) NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_ProductVariant_Status DEFAULT ('ACTIVE'),

        CONSTRAINT PK_ProductVariant PRIMARY KEY CLUSTERED (VariantID),
        CONSTRAINT UQ_ProductVariant_SKU UNIQUE (SKU),
        CONSTRAINT CK_ProductVariant_Weight CHECK (Weight IS NULL OR Weight >= 0),
        CONSTRAINT CK_ProductVariant_Status CHECK (Status IN ('ACTIVE','INACTIVE','DISCONTINUED'))
    );

    -- Ensures Barcode is unique across all products while allowing multiple NULL values
    CREATE UNIQUE NONCLUSTERED INDEX UX_ProductVariant_Barcode
    ON catalog.ProductVariant (Barcode)
    WHERE Barcode IS NOT NULL;
END
GO

IF OBJECT_ID(N'catalog.Category', N'U') IS NULL
BEGIN
    CREATE TABLE catalog.Category
    (
        CategoryID      bigint IDENTITY(1,1) NOT NULL,
        ParentCategoryID bigint NULL,
        Name            nvarchar(150) NOT NULL,
        Description     nvarchar(1000) NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Category_Status DEFAULT ('ACTIVE'),

        CONSTRAINT PK_Category PRIMARY KEY CLUSTERED (CategoryID),
        CONSTRAINT UQ_Category_Name UNIQUE (ParentCategoryID, Name),
        CONSTRAINT CK_Category_Status CHECK (Status IN ('ACTIVE','INACTIVE'))
    );
END
GO

/* ============================================================================
   07. PROCUREMENT
   ============================================================================ */

IF OBJECT_ID(N'procurement.Supplier', N'U') IS NULL
BEGIN
    CREATE TABLE procurement.Supplier
    (
        SupplierID      bigint IDENTITY(1,1) NOT NULL,
        Name            nvarchar(200) NOT NULL,
        LegalName       nvarchar(250) NOT NULL,
        TaxNumber       nvarchar(100) NULL,
        Email           varchar(320) NULL,
        Phone           varchar(30) NULL,
        AddressID       bigint NULL,
        Country         nvarchar(100) NOT NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Supplier_Status DEFAULT ('ACTIVE'),
        CreatedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_Supplier_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_Supplier PRIMARY KEY CLUSTERED (SupplierID),
        -- Ensures no two suppliers can have the exact same official registered legal name
        CONSTRAINT UQ_Supplier_LegalName UNIQUE (LegalName),
        CONSTRAINT CK_Supplier_Status CHECK (Status IN ('ACTIVE','INACTIVE','BLOCKED'))
    );

    -- Ensures TaxNumber is unique across suppliers while allowing multiple NULL values
    CREATE UNIQUE NONCLUSTERED INDEX UX_Supplier_TaxNumber
    ON procurement.Supplier (TaxNumber)
    WHERE TaxNumber IS NOT NULL;

    -- Ensures Email is unique across suppliers while allowing multiple NULL values
    CREATE UNIQUE NONCLUSTERED INDEX UX_Supplier_Email
    ON procurement.Supplier (Email)
    WHERE Email IS NOT NULL;
END
GO


IF OBJECT_ID(N'procurement.PurchaseOrder', N'U') IS NULL
BEGIN
    CREATE TABLE procurement.PurchaseOrder
    (
        PurchaseOrderID bigint IDENTITY(1,1) NOT NULL,
        CompanyID       bigint NOT NULL,
        SupplierID      bigint NOT NULL,
        WarehouseID     bigint NOT NULL,
        OrderDate       datetime2(3) NOT NULL
            CONSTRAINT DF_PurchaseOrder_OrderDate DEFAULT (SYSUTCDATETIME()),
        ExpectedDate    date NULL,
        Status          varchar(30) NOT NULL
            CONSTRAINT DF_PurchaseOrder_Status DEFAULT ('DRAFT'),
        TotalAmount     decimal(19,4) NOT NULL
            CONSTRAINT DF_PurchaseOrder_TotalAmount DEFAULT (0),
        CreatedBy       bigint NOT NULL,
        CreatedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_PurchaseOrder_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_PurchaseOrder PRIMARY KEY CLUSTERED (PurchaseOrderID),
        CONSTRAINT CK_PurchaseOrder_Total CHECK (TotalAmount >= 0),
        CONSTRAINT CK_PurchaseOrder_Dates CHECK (ExpectedDate IS NULL OR ExpectedDate >= CONVERT(date, OrderDate)),
        CONSTRAINT CK_PurchaseOrder_Status CHECK (Status IN
            ('DRAFT','SUBMITTED','APPROVED','PARTIALLY_RECEIVED','FULLY_RECEIVED','CANCELLED','REJECTED'))
    );
END
GO

IF OBJECT_ID(N'procurement.PurchaseOrderItem', N'U') IS NULL
BEGIN
    CREATE TABLE procurement.PurchaseOrderItem
    (
        PurchaseOrderItemID bigint IDENTITY(1,1) NOT NULL,
        PurchaseOrderID     bigint NOT NULL,
        VariantID           bigint NOT NULL,
        OrderedQuantity     decimal(18,3) NOT NULL,
        UnitCost            decimal(19,4) NOT NULL,

        CONSTRAINT PK_PurchaseOrderItem PRIMARY KEY CLUSTERED (PurchaseOrderItemID),
        CONSTRAINT UQ_PurchaseOrderItem_Order_Variant UNIQUE (PurchaseOrderID, VariantID),
        CONSTRAINT CK_PurchaseOrderItem_Qty CHECK (OrderedQuantity > 0),
        CONSTRAINT CK_PurchaseOrderItem_Cost CHECK (UnitCost >= 0)
    );
END
GO

IF OBJECT_ID(N'procurement.PurchaseOrderStatusHistory', N'U') IS NULL
BEGIN
    CREATE TABLE procurement.PurchaseOrderStatusHistory
    (
        HistoryID       bigint IDENTITY(1,1) NOT NULL,
        PurchaseOrderID bigint NOT NULL,
        OldStatus       varchar(30) NULL,
        NewStatus       varchar(30) NOT NULL,
        ChangedBy       bigint NOT NULL,
        ChangedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_POHistory_ChangedAt DEFAULT (SYSUTCDATETIME()),
        Reason          nvarchar(1000) NULL,

        CONSTRAINT PK_PurchaseOrderStatusHistory PRIMARY KEY CLUSTERED (HistoryID),
        CONSTRAINT CK_POHistory_Status CHECK
            (OldStatus IS NULL OR OldStatus IN ('DRAFT','SUBMITTED','APPROVED','PARTIALLY_RECEIVED','FULLY_RECEIVED','CANCELLED','REJECTED')),
        CONSTRAINT CK_POHistory_NewStatus CHECK
            (NewStatus IN ('DRAFT','SUBMITTED','APPROVED','PARTIALLY_RECEIVED','FULLY_RECEIVED','CANCELLED','REJECTED'))
    );
END
GO

IF OBJECT_ID(N'procurement.GoodsReceipt', N'U') IS NULL
BEGIN
    CREATE TABLE procurement.GoodsReceipt
    (
        GoodsReceiptID bigint IDENTITY(1,1) NOT NULL,
        PurchaseOrderID bigint NOT NULL,
        WarehouseID    bigint NOT NULL,
        ReceivedDate   datetime2(3) NOT NULL
            CONSTRAINT DF_GoodsReceipt_ReceivedDate DEFAULT (SYSUTCDATETIME()),
        ReceivedBy     bigint NOT NULL,
        Status         varchar(20) NOT NULL
            CONSTRAINT DF_GoodsReceipt_Status DEFAULT ('RECEIVED'),

        CONSTRAINT PK_GoodsReceipt PRIMARY KEY CLUSTERED (GoodsReceiptID),
        CONSTRAINT CK_GoodsReceipt_Status CHECK (Status IN ('RECEIVED','PARTIAL','CANCELLED'))
    );
END
GO

IF OBJECT_ID(N'procurement.GoodsReceiptItem', N'U') IS NULL
BEGIN
    CREATE TABLE procurement.GoodsReceiptItem
    (
        GoodsReceiptItemID bigint IDENTITY(1,1) NOT NULL,
        GoodsReceiptID     bigint NOT NULL,
        PurchaseOrderItemID bigint NOT NULL,
        ReceivedQuantity   decimal(18,3) NOT NULL,
        DamagedQuantity    decimal(18,3) NOT NULL
            CONSTRAINT DF_GoodsReceiptItem_Damaged DEFAULT (0),
        AcceptedQuantity   AS (ReceivedQuantity - DamagedQuantity) PERSISTED,

        CONSTRAINT PK_GoodsReceiptItem PRIMARY KEY CLUSTERED (GoodsReceiptItemID),
        CONSTRAINT UQ_GoodsReceiptItem_Receipt_POItem UNIQUE (GoodsReceiptID, PurchaseOrderItemID),
        CONSTRAINT CK_GoodsReceiptItem_Received CHECK (ReceivedQuantity > 0),
        CONSTRAINT CK_GoodsReceiptItem_Damaged CHECK (DamagedQuantity >= 0 AND DamagedQuantity <= ReceivedQuantity)
    );
END
GO

/* ============================================================================
   08. INVENTORY
   ============================================================================ */

IF OBJECT_ID(N'inventory.Inventory', N'U') IS NULL
BEGIN
    CREATE TABLE inventory.Inventory
    (
        InventoryID       bigint IDENTITY(1,1) NOT NULL,
        CompanyID         bigint NOT NULL,
        BinID             bigint NOT NULL,
        VariantID         bigint NOT NULL,
        OnHandQuantity    decimal(18,3) NOT NULL
            CONSTRAINT DF_Inventory_OnHand DEFAULT (0),
        ReservedQuantity  decimal(18,3) NOT NULL
            CONSTRAINT DF_Inventory_Reserved DEFAULT (0),
        DamagedQuantity   decimal(18,3) NOT NULL
            CONSTRAINT DF_Inventory_Damaged DEFAULT (0),
        CreatedAt         datetime2(3) NOT NULL
            CONSTRAINT DF_Inventory_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt         datetime2(3) NOT NULL
            CONSTRAINT DF_Inventory_UpdatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_Inventory PRIMARY KEY CLUSTERED (InventoryID),
        CONSTRAINT UQ_Inventory_Company_Bin_Variant UNIQUE
            (CompanyID, BinID, VariantID),
        CONSTRAINT CK_Inventory_OnHand CHECK (OnHandQuantity >= 0),
        CONSTRAINT CK_Inventory_Reserved CHECK (ReservedQuantity >= 0 AND ReservedQuantity <= OnHandQuantity),
        CONSTRAINT CK_Inventory_Damaged CHECK (DamagedQuantity >= 0 AND DamagedQuantity <= OnHandQuantity)
    );
END
GO

IF OBJECT_ID(N'inventory.InventoryTransaction', N'U') IS NULL
BEGIN
    CREATE TABLE inventory.InventoryTransaction
    (
        TransactionID    bigint IDENTITY(1,1) NOT NULL,
        InventoryID      bigint NOT NULL,
        TransactionType  varchar(30) NOT NULL,
        Quantity         decimal(18,3) NOT NULL,
        ReferenceType    varchar(50) NULL,
        ReferenceID      bigint NULL,
        PerformedBy      bigint NOT NULL,
        TransactionDate  datetime2(3) NOT NULL
            CONSTRAINT DF_InventoryTransaction_Date DEFAULT (SYSUTCDATETIME()),
        Reason           nvarchar(1000) NULL,

        CONSTRAINT PK_InventoryTransaction PRIMARY KEY CLUSTERED (TransactionID),
        CONSTRAINT CK_InventoryTransaction_Type CHECK (TransactionType IN
            ('RECEIPT','SALE','RESERVATION','RELEASE','TRANSFER_OUT','TRANSFER_IN','RETURN_RESTOCK','DAMAGE','SCRAP','ADJUSTMENT')),
        CONSTRAINT CK_InventoryTransaction_Qty CHECK (Quantity > 0)
    );
END
GO

IF OBJECT_ID(N'inventory.InventoryReservation', N'U') IS NULL
BEGIN
    CREATE TABLE inventory.InventoryReservation
    (
        ReservationID    bigint IDENTITY(1,1) NOT NULL,
        InventoryID      bigint NOT NULL,
        OrderItemID      bigint NOT NULL,
        Quantity         decimal(18,3) NOT NULL,
        Status            varchar(20) NOT NULL
            CONSTRAINT DF_InventoryReservation_Status DEFAULT ('ACTIVE'),
        CreatedAt        datetime2(3) NOT NULL
            CONSTRAINT DF_InventoryReservation_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ReleasedAt       datetime2(3) NULL,

        CONSTRAINT PK_InventoryReservation PRIMARY KEY CLUSTERED (ReservationID),
        CONSTRAINT CK_InventoryReservation_Qty CHECK (Quantity > 0),
        CONSTRAINT CK_InventoryReservation_Status CHECK (Status IN ('ACTIVE','RELEASED','CANCELLED')),
        CONSTRAINT CK_InventoryReservation_ReleasedAt CHECK
            ((Status = 'ACTIVE' AND ReleasedAt IS NULL) OR (Status <> 'ACTIVE'))
    );
END
GO

IF OBJECT_ID(N'inventory.InventoryTransfer', N'U') IS NULL
BEGIN
    CREATE TABLE inventory.InventoryTransfer
    (
        TransferID       bigint IDENTITY(1,1) NOT NULL,
        FromCompanyID    bigint NOT NULL,
        FromWarehouseID  bigint NOT NULL,
        ToCompanyID      bigint NOT NULL,
        ToWarehouseID    bigint NOT NULL,
        Status            varchar(20) NOT NULL
            CONSTRAINT DF_InventoryTransfer_Status DEFAULT ('REQUESTED'),
        RequestedBy       bigint NOT NULL,
        ApprovedBy        bigint NULL,
        CreatedAt         datetime2(3) NOT NULL
            CONSTRAINT DF_InventoryTransfer_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CompletedAt       datetime2(3) NULL,

        CONSTRAINT PK_InventoryTransfer PRIMARY KEY CLUSTERED (TransferID),
        CONSTRAINT CK_InventoryTransfer_Status CHECK (Status IN
            ('REQUESTED','APPROVED','RESERVED','SHIPPED','IN_TRANSIT','RECEIVED','COMPLETED','CANCELLED')),
        CONSTRAINT CK_InventoryTransfer_DifferentLocation CHECK
            (FromCompanyID <> ToCompanyID OR FromWarehouseID <> ToWarehouseID),
        CONSTRAINT CK_InventoryTransfer_CompletedAt CHECK
            (CompletedAt IS NULL OR Status = 'COMPLETED')
    );
END
GO

IF OBJECT_ID(N'inventory.InventoryTransferItem', N'U') IS NULL
BEGIN
    CREATE TABLE inventory.InventoryTransferItem
    (
        TransferItemID     bigint IDENTITY(1,1) NOT NULL,
        TransferID         bigint NOT NULL,
        FromInventoryID    bigint NOT NULL,
        ToInventoryID      bigint NOT NULL,
        RequestedQuantity  decimal(18,3) NOT NULL,
        ShippedQuantity    decimal(18,3) NOT NULL
            CONSTRAINT DF_TransferItem_Shipped DEFAULT (0),
        ReceivedQuantity   decimal(18,3) NOT NULL
            CONSTRAINT DF_TransferItem_Received DEFAULT (0),

        CONSTRAINT PK_InventoryTransferItem PRIMARY KEY CLUSTERED (TransferItemID),
        CONSTRAINT CK_TransferItem_Requested CHECK (RequestedQuantity > 0),
        CONSTRAINT CK_TransferItem_Shipped CHECK (ShippedQuantity >= 0 AND ShippedQuantity <= RequestedQuantity),
        CONSTRAINT CK_TransferItem_Received CHECK (ReceivedQuantity >= 0 AND ReceivedQuantity <= ShippedQuantity)
    );
END
GO

/* ============================================================================
   09. SALES
   ============================================================================ */

IF OBJECT_ID(N'sales.Customer', N'U') IS NULL
BEGIN
    CREATE TABLE sales.Customer
    (
        CustomerID      bigint IDENTITY(1,1) NOT NULL,
        EnterpriseID    bigint NOT NULL,
        CustomerType    varchar(20) NOT NULL,
        FirstName       nvarchar(100) NULL,
        LastName        nvarchar(100) NULL,
        Email           varchar(320) NULL,
        Phone           varchar(30) NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Customer_Status DEFAULT ('ACTIVE'),
        CreatedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_Customer_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_Customer PRIMARY KEY CLUSTERED (CustomerID),
        CONSTRAINT CK_Customer_Type CHECK (CustomerType IN ('INDIVIDUAL','BUSINESS')),
        CONSTRAINT CK_Customer_Status CHECK (Status IN ('ACTIVE','INACTIVE','BLOCKED'))
    );
END
GO

IF OBJECT_ID(N'sales.CustomerAddress', N'U') IS NULL
BEGIN
    CREATE TABLE sales.CustomerAddress
    (
        CustomerAddressID bigint IDENTITY(1,1) NOT NULL,
        CustomerID        bigint NOT NULL,
        AddressType       varchar(20) NOT NULL,
        AddressLine1      nvarchar(250) NOT NULL,
        AddressLine2      nvarchar(250) NULL,
        City              nvarchar(100) NOT NULL,
        State             nvarchar(100) NULL,
        Country           nvarchar(100) NOT NULL,
        PostalCode        nvarchar(30) NULL,
        IsDefault         bit NOT NULL
            CONSTRAINT DF_CustomerAddress_IsDefault DEFAULT (0),
        Status            varchar(20) NOT NULL
            CONSTRAINT DF_CustomerAddress_Status DEFAULT ('ACTIVE'),

        CONSTRAINT PK_CustomerAddress PRIMARY KEY CLUSTERED (CustomerAddressID),
        CONSTRAINT CK_CustomerAddress_Type CHECK (AddressType IN ('BILLING','SHIPPING','OTHER')),
        CONSTRAINT CK_CustomerAddress_Status CHECK (Status IN ('ACTIVE','INACTIVE'))
    );
END
GO

IF OBJECT_ID(N'sales.SalesOrder', N'U') IS NULL
BEGIN
    CREATE TABLE sales.SalesOrder
    (
        OrderID          bigint IDENTITY(1,1) NOT NULL,
        CompanyID        bigint NOT NULL,
        CustomerID       bigint NOT NULL,
        BranchID         bigint NULL,
        OrderDate        datetime2(3) NOT NULL
            CONSTRAINT DF_SalesOrder_OrderDate DEFAULT (SYSUTCDATETIME()),
        Status           varchar(30) NOT NULL
            CONSTRAINT DF_SalesOrder_Status DEFAULT ('DRAFT'),
        CurrencyID       int NOT NULL,
        Subtotal         decimal(19,4) NOT NULL
            CONSTRAINT DF_SalesOrder_Subtotal DEFAULT (0),
        DiscountAmount   decimal(19,4) NOT NULL
            CONSTRAINT DF_SalesOrder_Discount DEFAULT (0),
        TaxAmount        decimal(19,4) NOT NULL
            CONSTRAINT DF_SalesOrder_Tax DEFAULT (0),
        ShippingAmount   decimal(19,4) NOT NULL
            CONSTRAINT DF_SalesOrder_Shipping DEFAULT (0),
        TotalAmount      decimal(19,4) NOT NULL
            CONSTRAINT DF_SalesOrder_Total DEFAULT (0),
        CreatedBy        bigint NOT NULL,
        CreatedAt        datetime2(3) NOT NULL
            CONSTRAINT DF_SalesOrder_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_SalesOrder PRIMARY KEY CLUSTERED (OrderID),
        CONSTRAINT CK_SalesOrder_Status CHECK (Status IN
            ('DRAFT','PENDING_PAYMENT','PAID','ALLOCATED','PICKING','PACKED','SHIPPED','DELIVERED','CANCELLED')),
        CONSTRAINT CK_SalesOrder_Subtotal CHECK (Subtotal >= 0),
        CONSTRAINT CK_SalesOrder_Discount CHECK (DiscountAmount >= 0),
        CONSTRAINT CK_SalesOrder_Tax CHECK (TaxAmount >= 0),
        CONSTRAINT CK_SalesOrder_Shipping CHECK (ShippingAmount >= 0),
        CONSTRAINT CK_SalesOrder_Total CHECK (TotalAmount >= 0)
    );
END
GO

IF OBJECT_ID(N'sales.SalesOrderItem', N'U') IS NULL
BEGIN
    CREATE TABLE sales.SalesOrderItem
    (
        OrderItemID      bigint IDENTITY(1,1) NOT NULL,
        OrderID          bigint NOT NULL,
        VariantID        bigint NOT NULL,
        Quantity         decimal(18,3) NOT NULL,
        UnitPrice        decimal(19,4) NOT NULL,
        DiscountAmount   decimal(19,4) NOT NULL
            CONSTRAINT DF_SalesOrderItem_Discount DEFAULT (0),
        TaxAmount        decimal(19,4) NOT NULL
            CONSTRAINT DF_SalesOrderItem_Tax DEFAULT (0),
        LineTotal        decimal(19,4) NOT NULL,

        CONSTRAINT PK_SalesOrderItem PRIMARY KEY CLUSTERED (OrderItemID),
        CONSTRAINT UQ_SalesOrderItem_Order_Variant UNIQUE (OrderID, VariantID),
        CONSTRAINT CK_SalesOrderItem_Qty CHECK (Quantity > 0),
        CONSTRAINT CK_SalesOrderItem_Price CHECK (UnitPrice >= 0),
        CONSTRAINT CK_SalesOrderItem_Discount CHECK (DiscountAmount >= 0),
        CONSTRAINT CK_SalesOrderItem_Tax CHECK (TaxAmount >= 0),
        CONSTRAINT CK_SalesOrderItem_LineTotal CHECK (LineTotal >= 0)
    );
END
GO

IF OBJECT_ID(N'sales.OrderAddress', N'U') IS NULL
BEGIN
    CREATE TABLE sales.OrderAddress
    (
        OrderAddressID  bigint IDENTITY(1,1) NOT NULL,
        OrderID         bigint NOT NULL,
        AddressType     varchar(20) NOT NULL,
        AddressLine1    nvarchar(250) NOT NULL,
        AddressLine2    nvarchar(250) NULL,
        City            nvarchar(100) NOT NULL,
        State           nvarchar(100) NULL,
        Country         nvarchar(100) NOT NULL,
        PostalCode      nvarchar(30) NULL,

        CONSTRAINT PK_OrderAddress PRIMARY KEY CLUSTERED (OrderAddressID),
        CONSTRAINT UQ_OrderAddress_Order_Type UNIQUE (OrderID, AddressType),
        CONSTRAINT CK_OrderAddress_Type CHECK (AddressType IN ('BILLING','SHIPPING'))
    );
END
GO

IF OBJECT_ID(N'sales.OrderStatusHistory', N'U') IS NULL
BEGIN
    CREATE TABLE sales.OrderStatusHistory
    (
        HistoryID       bigint IDENTITY(1,1) NOT NULL,
        OrderID         bigint NOT NULL,
        OldStatus       varchar(30) NULL,
        NewStatus       varchar(30) NOT NULL,
        ChangedBy       bigint NOT NULL,
        ChangedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_OrderHistory_ChangedAt DEFAULT (SYSUTCDATETIME()),
        Reason          nvarchar(1000) NULL,

        CONSTRAINT PK_OrderStatusHistory PRIMARY KEY CLUSTERED (HistoryID),
        CONSTRAINT CK_OrderHistory_NewStatus CHECK (NewStatus IN
            ('DRAFT','PENDING_PAYMENT','PAID','ALLOCATED','PICKING','PACKED','SHIPPED','DELIVERED','CANCELLED'))
    );
END
GO

IF OBJECT_ID(N'sales.Payment', N'U') IS NULL
BEGIN
    CREATE TABLE sales.Payment
    (
        PaymentID            bigint IDENTITY(1,1) NOT NULL,
        OrderID              bigint NOT NULL,
        PaymentMethod        varchar(30) NOT NULL,
        Amount               decimal(19,4) NOT NULL,
        CurrencyID           int NOT NULL,
        Status               varchar(20) NOT NULL
            CONSTRAINT DF_Payment_Status DEFAULT ('PENDING'),
        TransactionReference varchar(150) NULL,
        AttemptNumber        int NOT NULL
            CONSTRAINT DF_Payment_Attempt DEFAULT (1),
        ProcessedAt          datetime2(3) NULL,

        CONSTRAINT PK_Payment PRIMARY KEY CLUSTERED (PaymentID),
        CONSTRAINT CK_Payment_Amount CHECK (Amount > 0),
        CONSTRAINT CK_Payment_Attempt CHECK (AttemptNumber > 0),
        CONSTRAINT CK_Payment_Status CHECK (Status IN ('PENDING','SUCCESS','FAILED','REFUNDED','CANCELLED'))
    );
END
GO

/* ============================================================================
   10. LOGISTICS
   ============================================================================ */

IF OBJECT_ID(N'logistics.Carrier', N'U') IS NULL
BEGIN
    CREATE TABLE logistics.Carrier
    (
        CarrierID       bigint IDENTITY(1,1) NOT NULL,
        Name            nvarchar(150) NOT NULL,
        Code            varchar(50) NOT NULL,
        Phone           varchar(30) NULL, -- No UNIQUE constraint here as multiple carrier branches/subsidiaries might share the same corporate phone number
        Email           varchar(320) NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Carrier_Status DEFAULT ('ACTIVE'),

        CONSTRAINT PK_Carrier PRIMARY KEY CLUSTERED (CarrierID),
        CONSTRAINT UQ_Carrier_Code UNIQUE (Code),
        CONSTRAINT CK_Carrier_Status CHECK (Status IN ('ACTIVE','INACTIVE'))
    );
    
    -- Ensures Email is unique across carriers while allowing multiple NULL values
    CREATE UNIQUE NONCLUSTERED INDEX UX_Carrier_Email
    ON logistics.Carrier (Email)
    WHERE Email IS NOT NULL;
END
GO


IF OBJECT_ID(N'logistics.Fulfillment', N'U') IS NULL
BEGIN
    CREATE TABLE logistics.Fulfillment
    (
        FulfillmentID   bigint IDENTITY(1,1) NOT NULL,
        OrderID         bigint NOT NULL,
        WarehouseID     bigint NOT NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_Fulfillment_Status DEFAULT ('PENDING'),
        CreatedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_Fulfillment_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_Fulfillment PRIMARY KEY CLUSTERED (FulfillmentID),
        CONSTRAINT CK_Fulfillment_Status CHECK (Status IN
            ('PENDING','ALLOCATED','PICKING','PACKED','READY_TO_SHIP','SHIPPED','COMPLETED','CANCELLED'))
    );
END
GO

IF OBJECT_ID(N'logistics.FulfillmentItem', N'U') IS NULL
BEGIN
    CREATE TABLE logistics.FulfillmentItem
    (
        FulfillmentItemID bigint IDENTITY(1,1) NOT NULL,
        FulfillmentID     bigint NOT NULL,
        OrderItemID       bigint NOT NULL,
        Quantity          decimal(18,3) NOT NULL,

        CONSTRAINT PK_FulfillmentItem PRIMARY KEY CLUSTERED (FulfillmentItemID),
        CONSTRAINT UQ_FulfillmentItem_Fulfillment_OrderItem UNIQUE (FulfillmentID, OrderItemID),
        CONSTRAINT CK_FulfillmentItem_Qty CHECK (Quantity > 0)
    );
END
GO

IF OBJECT_ID(N'logistics.Shipment', N'U') IS NULL
BEGIN
    CREATE TABLE logistics.Shipment
    (
        ShipmentID           bigint IDENTITY(1,1) NOT NULL,
        FulfillmentID        bigint NOT NULL,
        CarrierID            bigint NOT NULL,
        TrackingNumber       varchar(150) NOT NULL,
        ShippedAt            datetime2(3) NULL,
        ExpectedDeliveryDate date NULL,
        DeliveredAt          datetime2(3) NULL,
        Status               varchar(30) NOT NULL
            CONSTRAINT DF_Shipment_Status DEFAULT ('CREATED'),

        CONSTRAINT PK_Shipment PRIMARY KEY CLUSTERED (ShipmentID),
        CONSTRAINT UQ_Shipment_TrackingNumber UNIQUE (TrackingNumber),
        CONSTRAINT CK_Shipment_Status CHECK (Status IN
            ('CREATED','READY','PICKED_UP','IN_TRANSIT','ARRIVED','OUT_FOR_DELIVERY','DELIVERED','FAILED','RETURNED')),
        CONSTRAINT CK_Shipment_Dates CHECK (DeliveredAt IS NULL OR ShippedAt IS NOT NULL AND DeliveredAt >= ShippedAt)
    );
END
GO

IF OBJECT_ID(N'logistics.ShipmentItem', N'U') IS NULL
BEGIN
    CREATE TABLE logistics.ShipmentItem
    (
        ShipmentItemID   bigint IDENTITY(1,1) NOT NULL,
        ShipmentID       bigint NOT NULL,
        FulfillmentItemID bigint NOT NULL,
        Quantity         decimal(18,3) NOT NULL,

        CONSTRAINT PK_ShipmentItem PRIMARY KEY CLUSTERED (ShipmentItemID),
        CONSTRAINT UQ_ShipmentItem_Shipment_FulfillmentItem UNIQUE (ShipmentID, FulfillmentItemID),
        CONSTRAINT CK_ShipmentItem_Qty CHECK (Quantity > 0)
    );
END
GO

IF OBJECT_ID(N'logistics.ShipmentTrackingEvent', N'U') IS NULL
BEGIN
    CREATE TABLE logistics.ShipmentTrackingEvent
    (
        TrackingEventID bigint IDENTITY(1,1) NOT NULL,
        ShipmentID      bigint NOT NULL,
        Status          varchar(30) NOT NULL,
        Location        nvarchar(250) NULL,
        EventTime       datetime2(3) NOT NULL,
        Description     nvarchar(1000) NULL,

        CONSTRAINT PK_ShipmentTrackingEvent PRIMARY KEY CLUSTERED (TrackingEventID),
        CONSTRAINT CK_TrackingEvent_Status CHECK (Status IN
            ('CREATED','READY','PICKED_UP','IN_TRANSIT','ARRIVED','OUT_FOR_DELIVERY','DELIVERED','FAILED','RETURNED'))
    );
END
GO

/* ============================================================================
   11. RETURNS
   ============================================================================ */

IF OBJECT_ID(N'returns.ReturnRequest', N'U') IS NULL
BEGIN
    CREATE TABLE returns.ReturnRequest
    (
        ReturnRequestID bigint IDENTITY(1,1) NOT NULL,
        OrderID         bigint NOT NULL,
        RequestedAt     datetime2(3) NOT NULL
            CONSTRAINT DF_ReturnRequest_RequestedAt DEFAULT (SYSUTCDATETIME()),
        Reason          nvarchar(1000) NOT NULL,
        Status          varchar(30) NOT NULL
            CONSTRAINT DF_ReturnRequest_Status DEFAULT ('REQUESTED'),
        RequestedBy     bigint NOT NULL,
        ApprovedBy      bigint NULL,
        ApprovedAt      datetime2(3) NULL,
        Notes           nvarchar(2000) NULL,

        CONSTRAINT PK_ReturnRequest PRIMARY KEY CLUSTERED (ReturnRequestID),
        CONSTRAINT CK_ReturnRequest_Status CHECK (Status IN
            ('REQUESTED','APPROVED','IN_TRANSIT','RECEIVED','INSPECTING','DISPOSITIONED','REFUND_PENDING','REFUNDED','COMPLETED','REJECTED'))
    );
END
GO

IF OBJECT_ID(N'returns.ReturnRequestItem', N'U') IS NULL
BEGIN
    CREATE TABLE returns.ReturnRequestItem
    (
        ReturnItemID       bigint IDENTITY(1,1) NOT NULL,
        ReturnRequestID    bigint NOT NULL,
        OrderItemID        bigint NOT NULL,
        RequestedQuantity  decimal(18,3) NOT NULL,
        ApprovedQuantity   decimal(18,3) NOT NULL
            CONSTRAINT DF_ReturnItem_Approved DEFAULT (0),
        ReceivedQuantity   decimal(18,3) NOT NULL
            CONSTRAINT DF_ReturnItem_Received DEFAULT (0),
        Reason             nvarchar(1000) NULL,
        Condition          varchar(30) NULL,

        CONSTRAINT PK_ReturnRequestItem PRIMARY KEY CLUSTERED (ReturnItemID),
        CONSTRAINT UQ_ReturnRequestItem_Return_OrderItem UNIQUE (ReturnRequestID, OrderItemID),
        CONSTRAINT CK_ReturnItem_Requested CHECK (RequestedQuantity > 0),
        CONSTRAINT CK_ReturnItem_Approved CHECK (ApprovedQuantity >= 0 AND ApprovedQuantity <= RequestedQuantity),
        CONSTRAINT CK_ReturnItem_Received CHECK (ReceivedQuantity >= 0 AND ReceivedQuantity <= ApprovedQuantity),
        CONSTRAINT CK_ReturnItem_Condition CHECK (Condition IS NULL OR Condition IN ('NEW','OPEN_BOX','USED','DAMAGED','DEFECTIVE'))
    );
END
GO

IF OBJECT_ID(N'returns.ReturnStatusHistory', N'U') IS NULL
BEGIN
    CREATE TABLE returns.ReturnStatusHistory
    (
        HistoryID       bigint IDENTITY(1,1) NOT NULL,
        ReturnRequestID bigint NOT NULL,
        OldStatus       varchar(30) NULL,
        NewStatus       varchar(30) NOT NULL,
        ChangedBy       bigint NOT NULL,
        ChangedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_ReturnHistory_ChangedAt DEFAULT (SYSUTCDATETIME()),
        Reason          nvarchar(1000) NULL,

        CONSTRAINT PK_ReturnStatusHistory PRIMARY KEY CLUSTERED (HistoryID)
    );
END
GO

IF OBJECT_ID(N'returns.ReturnReceipt', N'U') IS NULL
BEGIN
    CREATE TABLE returns.ReturnReceipt
    (
        ReturnReceiptID bigint IDENTITY(1,1) NOT NULL,
        ReturnRequestID bigint NOT NULL,
        WarehouseID     bigint NOT NULL,
        ReceivedBy      bigint NOT NULL,
        ReceivedAt      datetime2(3) NOT NULL
            CONSTRAINT DF_ReturnReceipt_ReceivedAt DEFAULT (SYSUTCDATETIME()),
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_ReturnReceipt_Status DEFAULT ('RECEIVED'),

        CONSTRAINT PK_ReturnReceipt PRIMARY KEY CLUSTERED (ReturnReceiptID),
        CONSTRAINT CK_ReturnReceipt_Status CHECK (Status IN ('RECEIVED','INSPECTING','COMPLETED','CANCELLED'))
    );
END
GO

IF OBJECT_ID(N'returns.ReturnInspection', N'U') IS NULL
BEGIN
    CREATE TABLE returns.ReturnInspection
    (
        InspectionID    bigint IDENTITY(1,1) NOT NULL,
        ReturnReceiptID bigint NOT NULL,
        InspectedBy     bigint NOT NULL,
        InspectionDate  datetime2(3) NOT NULL
            CONSTRAINT DF_ReturnInspection_Date DEFAULT (SYSUTCDATETIME()),
        Result          varchar(30) NOT NULL,
        Notes           nvarchar(2000) NULL,

        CONSTRAINT PK_ReturnInspection PRIMARY KEY CLUSTERED (InspectionID),
        CONSTRAINT CK_ReturnInspection_Result CHECK (Result IN ('APPROVED','PARTIAL','REJECTED'))
    );
END
GO

IF OBJECT_ID(N'returns.ReturnInspectionItem', N'U') IS NULL
BEGIN
    CREATE TABLE returns.ReturnInspectionItem
    (
        InspectionItemID bigint IDENTITY(1,1) NOT NULL,
        InspectionID     bigint NOT NULL,
        ReturnItemID     bigint NOT NULL,
        Quantity         decimal(18,3) NOT NULL,
        Result           varchar(30) NOT NULL,
        Notes            nvarchar(1000) NULL,

        CONSTRAINT PK_ReturnInspectionItem PRIMARY KEY CLUSTERED (InspectionItemID),
        CONSTRAINT UQ_ReturnInspectionItem_Inspection_ReturnItem UNIQUE (InspectionID, ReturnItemID),
        CONSTRAINT CK_ReturnInspectionItem_Qty CHECK (Quantity > 0),
        CONSTRAINT CK_ReturnInspectionItem_Result CHECK (Result IN
            ('RESELLABLE','DAMAGED','DEFECTIVE','MISSING_PARTS','REPAIR_REQUIRED','SCRAP'))
    );
END
GO

IF OBJECT_ID(N'returns.ReturnDisposition', N'U') IS NULL
BEGIN
    CREATE TABLE returns.ReturnDisposition
    (
        DispositionID      bigint IDENTITY(1,1) NOT NULL,
        InspectionItemID   bigint NOT NULL,
        DispositionType    varchar(30) NOT NULL,
        Quantity           decimal(18,3) NOT NULL,
        WarehouseID        bigint NOT NULL,
        BinID              bigint NULL,
        CreatedAt          datetime2(3) NOT NULL
            CONSTRAINT DF_ReturnDisposition_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_ReturnDisposition PRIMARY KEY CLUSTERED (DispositionID),
        CONSTRAINT CK_ReturnDisposition_Type CHECK (DispositionType IN
            ('RESTOCK','REPAIR','SCRAP','DAMAGED','RETURN_TO_SUPPLIER')),
        CONSTRAINT CK_ReturnDisposition_Qty CHECK (Quantity > 0),
        CONSTRAINT CK_ReturnDisposition_Bin CHECK
            ((DispositionType = 'RESTOCK' AND BinID IS NOT NULL) OR
             (DispositionType <> 'RESTOCK'))
    );
END
GO

IF OBJECT_ID(N'returns.Refund', N'U') IS NULL
BEGIN
    CREATE TABLE returns.Refund
    (
        RefundID            bigint IDENTITY(1,1) NOT NULL,
        ReturnRequestID     bigint NOT NULL,
        PaymentID           bigint NOT NULL,
        Amount              decimal(19,4) NOT NULL,
        CurrencyID          int NOT NULL,
        RefundMethod        varchar(30) NOT NULL,
        Status               varchar(20) NOT NULL
            CONSTRAINT DF_Refund_Status DEFAULT ('PENDING'),
        TransactionReference varchar(150) NULL,
        ProcessedAt         datetime2(3) NULL,

        CONSTRAINT PK_Refund PRIMARY KEY CLUSTERED (RefundID),
        CONSTRAINT CK_Refund_Amount CHECK (Amount > 0),
        CONSTRAINT CK_Refund_Status CHECK (Status IN ('PENDING','SUCCESS','FAILED','CANCELLED'))
    );
END
GO

/* ============================================================================
   12. NOTIFICATIONS
   ============================================================================ */

IF OBJECT_ID(N'notifications.NotificationType', N'U') IS NULL
BEGIN
    CREATE TABLE notifications.NotificationType
    (
        NotificationTypeID int IDENTITY(1,1) NOT NULL,
        Code               varchar(50) NOT NULL,
        Name               nvarchar(100) NOT NULL,
        Description        nvarchar(500) NULL,
        DefaultPriority    tinyint NOT NULL
            CONSTRAINT DF_NotificationType_Priority DEFAULT (3),
        IsActive            bit NOT NULL
            CONSTRAINT DF_NotificationType_IsActive DEFAULT (1),

        CONSTRAINT PK_NotificationType PRIMARY KEY CLUSTERED (NotificationTypeID),
        CONSTRAINT UQ_NotificationType_Code UNIQUE (Code),
        CONSTRAINT CK_NotificationType_Priority CHECK (DefaultPriority BETWEEN 1 AND 5)
    );
END
GO

IF OBJECT_ID(N'notifications.Notification', N'U') IS NULL
BEGIN
    CREATE TABLE notifications.Notification
    (
        NotificationID     bigint IDENTITY(1,1) NOT NULL,
        NotificationTypeID int NOT NULL,
        Title              nvarchar(200) NOT NULL,
        Message            nvarchar(2000) NOT NULL,
        Priority           tinyint NOT NULL,
        CreatedAt          datetime2(3) NOT NULL
            CONSTRAINT DF_Notification_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ExpiresAt          datetime2(3) NULL,
        Status             varchar(20) NOT NULL
            CONSTRAINT DF_Notification_Status DEFAULT ('PENDING'),

        CONSTRAINT PK_Notification PRIMARY KEY CLUSTERED (NotificationID),
        CONSTRAINT CK_Notification_Priority CHECK (Priority BETWEEN 1 AND 5),
        CONSTRAINT CK_Notification_Status CHECK (Status IN ('PENDING','SENT','READ','EXPIRED','CANCELLED')),
        CONSTRAINT CK_Notification_Expiry CHECK (ExpiresAt IS NULL OR ExpiresAt >= CreatedAt)
    );
END
GO

IF OBJECT_ID(N'notifications.AlertRule', N'U') IS NULL
BEGIN
    CREATE TABLE notifications.AlertRule
    (
        AlertRuleID        bigint IDENTITY(1,1) NOT NULL,
        CompanyID          bigint NULL,
        NotificationTypeID int NOT NULL,
        RuleName           nvarchar(150) NOT NULL,
        ThresholdValue     decimal(19,4) NOT NULL,
        ThresholdUnit      varchar(30) NOT NULL,
        IsActive            bit NOT NULL
            CONSTRAINT DF_AlertRule_IsActive DEFAULT (1),
        CreatedAt          datetime2(3) NOT NULL
            CONSTRAINT DF_AlertRule_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_AlertRule PRIMARY KEY CLUSTERED (AlertRuleID),
        CONSTRAINT CK_AlertRule_Threshold CHECK (ThresholdValue >= 0)
    );
END
GO

IF OBJECT_ID(N'notifications.AlertInstance', N'U') IS NULL
BEGIN
    CREATE TABLE notifications.AlertInstance
    (
        AlertInstanceID bigint IDENTITY(1,1) NOT NULL,
        AlertRuleID     bigint NOT NULL,
        ReferenceType   varchar(50) NOT NULL,
        ReferenceID     bigint NOT NULL,
        FirstDetectedAt datetime2(3) NOT NULL
            CONSTRAINT DF_AlertInstance_FirstDetected DEFAULT (SYSUTCDATETIME()),
        LastDetectedAt  datetime2(3) NOT NULL
            CONSTRAINT DF_AlertInstance_LastDetected DEFAULT (SYSUTCDATETIME()),
        ResolvedAt      datetime2(3) NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_AlertInstance_Status DEFAULT ('OPEN'),

        CONSTRAINT PK_AlertInstance PRIMARY KEY CLUSTERED (AlertInstanceID),
        CONSTRAINT CK_AlertInstance_Status CHECK (Status IN ('OPEN','ACKNOWLEDGED','RESOLVED','CANCELLED')),
        CONSTRAINT CK_AlertInstance_Dates CHECK (LastDetectedAt >= FirstDetectedAt AND (ResolvedAt IS NULL OR ResolvedAt >= FirstDetectedAt))
    );
END
GO

/* ============================================================================
   13. SECURITY
   ============================================================================ */

IF OBJECT_ID(N'security.AppUser', N'U') IS NULL
BEGIN
    CREATE TABLE security.AppUser
    (
        UserID          bigint IDENTITY(1,1) NOT NULL,
        EmployeeID      bigint NOT NULL,
        LoginName       varchar(150) NOT NULL,
        Status          varchar(20) NOT NULL
            CONSTRAINT DF_AppUser_Status DEFAULT ('ACTIVE'),

        CONSTRAINT PK_AppUser PRIMARY KEY CLUSTERED (UserID),
        CONSTRAINT UQ_AppUser_Employee UNIQUE (EmployeeID),
        CONSTRAINT UQ_AppUser_LoginName UNIQUE (LoginName),
        CONSTRAINT CK_AppUser_Status CHECK (Status IN ('ACTIVE','LOCKED','DISABLED'))
    );
END
GO

/* ============================================================================
   14. AUDIT / TECHNICAL
   ============================================================================ */

IF OBJECT_ID(N'audit.DataChangeLog', N'U') IS NULL
BEGIN
    CREATE TABLE audit.DataChangeLog
    (
        AuditID         bigint IDENTITY(1,1) NOT NULL,
        TableName       sysname NOT NULL,
        RecordID        nvarchar(200) NOT NULL,
        Operation       varchar(10) NOT NULL,
        OldValue        nvarchar(max) NULL,
        NewValue        nvarchar(max) NULL,
        ChangedBy       bigint NULL,
        ChangedAt       datetime2(3) NOT NULL
            CONSTRAINT DF_DataChangeLog_ChangedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_DataChangeLog PRIMARY KEY CLUSTERED (AuditID),
        CONSTRAINT CK_DataChangeLog_Operation CHECK (Operation IN ('INSERT','UPDATE','DELETE'))
    );
END
GO

IF OBJECT_ID(N'audit.SecurityEventLog', N'U') IS NULL
BEGIN
    CREATE TABLE audit.SecurityEventLog
    (
        AuditID         bigint IDENTITY(1,1) NOT NULL,
        UserID          bigint NULL,
        EventType       varchar(50) NOT NULL,
        IPAddress       varchar(45) NULL,
        EventTime       datetime2(3) NOT NULL
            CONSTRAINT DF_SecurityEventLog_EventTime DEFAULT (SYSUTCDATETIME()),
        Success         bit NOT NULL,
        Details         nvarchar(2000) NULL,

        CONSTRAINT PK_SecurityEventLog PRIMARY KEY CLUSTERED (AuditID)
    );
END
GO

IF OBJECT_ID(N'audit.ErrorLog', N'U') IS NULL
BEGIN
    CREATE TABLE audit.ErrorLog
    (
        ErrorLogID      bigint IDENTITY(1,1) NOT NULL,
        ErrorNumber     int NULL,
        ErrorSeverity   int NULL,
        ErrorState      int NULL,
        ProcedureName   sysname NULL,
        LineNumber      int NULL,
        ErrorMessage    nvarchar(4000) NOT NULL,
        UserName        sysname NULL,
        OccurredAt      datetime2(3) NOT NULL
            CONSTRAINT DF_ErrorLog_OccurredAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_ErrorLog PRIMARY KEY CLUSTERED (ErrorLogID),
        CONSTRAINT CK_ErrorLog_Severity CHECK (ErrorSeverity IS NULL OR ErrorSeverity BETWEEN 0 AND 25),
        CONSTRAINT CK_ErrorLog_State CHECK (ErrorState IS NULL OR ErrorState BETWEEN 0 AND 255),
        CONSTRAINT CK_ErrorLog_Line CHECK (LineNumber IS NULL OR LineNumber > 0)
    );
END
GO

/* ============================================================================
   15. M:N ASSOCIATIVE TABLES
   These are the relational mapping of EERD M:N relationships.
   ============================================================================ */

IF OBJECT_ID(N'organization.EmployeeDepartment', N'U') IS NULL
BEGIN
    CREATE TABLE organization.EmployeeDepartment
    (
        EmployeeID   bigint NOT NULL,
        DepartmentID bigint NOT NULL,
        StartDate    date NOT NULL,
        EndDate      date NULL,
        IsPrimary    bit NOT NULL
            CONSTRAINT DF_EmployeeDepartment_IsPrimary DEFAULT (0),

        CONSTRAINT PK_EmployeeDepartment PRIMARY KEY CLUSTERED (EmployeeID, DepartmentID),
        CONSTRAINT CK_EmployeeDepartment_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate)
    );
END
GO

IF OBJECT_ID(N'organization.EmployeeRole', N'U') IS NULL
BEGIN
    CREATE TABLE organization.EmployeeRole
    (
        EmployeeID bigint NOT NULL,
        RoleID     int NOT NULL,

        CONSTRAINT PK_EmployeeRole PRIMARY KEY CLUSTERED (EmployeeID, RoleID)
    );
END
GO

IF OBJECT_ID(N'organization.CompanyWarehouse', N'U') IS NULL
BEGIN
    CREATE TABLE organization.CompanyWarehouse
    (
        CompanyID   bigint NOT NULL,
        WarehouseID bigint NOT NULL,
        AccessType  varchar(20) NOT NULL,
        StartDate   date NOT NULL,
        EndDate     date NULL,
        Status      varchar(20) NOT NULL
            CONSTRAINT DF_CompanyWarehouse_Status DEFAULT ('ACTIVE'),

        CONSTRAINT PK_CompanyWarehouse PRIMARY KEY CLUSTERED (CompanyID, WarehouseID),
        CONSTRAINT CK_CompanyWarehouse_AccessType CHECK (AccessType IN ('PRIMARY','SECONDARY','SHARED','TEMPORARY')),
        CONSTRAINT CK_CompanyWarehouse_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate),
        CONSTRAINT CK_CompanyWarehouse_Status CHECK (Status IN ('ACTIVE','INACTIVE','EXPIRED'))
    );
END
GO

IF OBJECT_ID(N'catalog.CompanyProduct', N'U') IS NULL
BEGIN
    CREATE TABLE catalog.CompanyProduct
    (
        CompanyID       bigint NOT NULL,
        VariantID       bigint NOT NULL,
        SellingPrice    decimal(19,4) NOT NULL,
        CostPrice       decimal(19,4) NULL,
        ReorderLevel    decimal(18,3) NOT NULL
            CONSTRAINT DF_CompanyProduct_Reorder DEFAULT (0),
        ReorderQuantity decimal(18,3) NOT NULL
            CONSTRAINT DF_CompanyProduct_ReorderQty DEFAULT (0),
        MinimumStock    decimal(18,3) NOT NULL
            CONSTRAINT DF_CompanyProduct_MinStock DEFAULT (0),
        MaximumStock    decimal(18,3) NULL,
        IsActive        bit NOT NULL
            CONSTRAINT DF_CompanyProduct_IsActive DEFAULT (1),

        CONSTRAINT PK_CompanyProduct PRIMARY KEY CLUSTERED (CompanyID, VariantID),
        CONSTRAINT CK_CompanyProduct_SellingPrice CHECK (SellingPrice >= 0),
        CONSTRAINT CK_CompanyProduct_CostPrice CHECK (CostPrice IS NULL OR CostPrice >= 0),
        CONSTRAINT CK_CompanyProduct_ReorderLevel CHECK (ReorderLevel >= 0),
        CONSTRAINT CK_CompanyProduct_ReorderQty CHECK (ReorderQuantity >= 0),
        CONSTRAINT CK_CompanyProduct_MinStock CHECK (MinimumStock >= 0),
        CONSTRAINT CK_CompanyProduct_MaxStock CHECK (MaximumStock IS NULL OR MaximumStock >= MinimumStock)
    );
END
GO

IF OBJECT_ID(N'catalog.ProductCategory', N'U') IS NULL
BEGIN
    CREATE TABLE catalog.ProductCategory
    (
        ProductID  bigint NOT NULL,
        CategoryID bigint NOT NULL,
        IsPrimary  bit NOT NULL
            CONSTRAINT DF_ProductCategory_IsPrimary DEFAULT (0),

        CONSTRAINT PK_ProductCategory PRIMARY KEY CLUSTERED (ProductID, CategoryID)
    );
END
GO

IF OBJECT_ID(N'procurement.CompanySupplier', N'U') IS NULL
BEGIN
    CREATE TABLE procurement.CompanySupplier
    (
        CompanyID          bigint NOT NULL,
        SupplierID         bigint NOT NULL,
        SupplierCode       varchar(50) NULL,
        PaymentTerms       varchar(100) NULL,
        CreditLimit        decimal(19,4) NULL,
        RelationshipStatus varchar(20) NOT NULL
            CONSTRAINT DF_CompanySupplier_Status DEFAULT ('ACTIVE'),
        StartDate          date NOT NULL
            CONSTRAINT DF_CompanySupplier_StartDate DEFAULT (CONVERT(date, SYSUTCDATETIME())),
        EndDate            date NULL,

        CONSTRAINT PK_CompanySupplier PRIMARY KEY CLUSTERED (CompanyID, SupplierID),
        CONSTRAINT UQ_CompanySupplier_Code UNIQUE (CompanyID, SupplierCode),
        CONSTRAINT CK_CompanySupplier_CreditLimit CHECK (CreditLimit IS NULL OR CreditLimit >= 0),
        CONSTRAINT CK_CompanySupplier_Status CHECK (RelationshipStatus IN ('ACTIVE','INACTIVE','SUSPENDED')),
        CONSTRAINT CK_CompanySupplier_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate)
    );
END
GO

IF OBJECT_ID(N'procurement.SupplierProduct', N'U') IS NULL
BEGIN
    CREATE TABLE procurement.SupplierProduct
    (
        SupplierID     bigint NOT NULL,
        VariantID      bigint NOT NULL,
        SupplierSKU         varchar(100) NULL,
        LastUnitCost        decimal(19,4) NULL,
        MinimumOrderQuantity decimal(18,3) NOT NULL
            CONSTRAINT DF_SupplierProduct_MOQ DEFAULT (1),
        LeadTimeDays        int NULL,
        IsPreferred         bit NOT NULL
            CONSTRAINT DF_SupplierProduct_IsPreferred DEFAULT (0),

        CONSTRAINT PK_SupplierProduct PRIMARY KEY CLUSTERED (SupplierID, VariantID),
        CONSTRAINT CK_SupplierProduct_Cost CHECK (LastUnitCost IS NULL OR LastUnitCost >= 0),
        CONSTRAINT CK_SupplierProduct_MOQ CHECK (MinimumOrderQuantity > 0),
        CONSTRAINT CK_SupplierProduct_LeadTime CHECK (LeadTimeDays IS NULL OR LeadTimeDays >= 0)
    );
END
GO

IF OBJECT_ID(N'sales.CompanyCustomer', N'U') IS NULL
BEGIN
    CREATE TABLE sales.CompanyCustomer
    (
        CompanyID      bigint NOT NULL,
        CustomerID     bigint NOT NULL,
        CustomerCode   varchar(50) NULL,
        Status         varchar(20) NOT NULL
            CONSTRAINT DF_CompanyCustomer_Status DEFAULT ('ACTIVE'),
        FirstOrderDate date NULL,
        LastOrderDate  date NULL,

        CONSTRAINT PK_CompanyCustomer PRIMARY KEY CLUSTERED (CompanyID, CustomerID),
        CONSTRAINT UQ_CompanyCustomer_Code UNIQUE (CompanyID, CustomerCode),
        CONSTRAINT CK_CompanyCustomer_Status CHECK (Status IN ('ACTIVE','INACTIVE','BLOCKED')),
        CONSTRAINT CK_CompanyCustomer_OrderDates CHECK
            (FirstOrderDate IS NULL OR LastOrderDate IS NULL OR LastOrderDate >= FirstOrderDate)
    );
END
GO

IF OBJECT_ID(N'notifications.NotificationRecipient', N'U') IS NULL
BEGIN
    CREATE TABLE notifications.NotificationRecipient
    (
        NotificationID bigint NOT NULL,
        EmployeeID     bigint NOT NULL,
        ReadAt         datetime2(3) NULL,

        CONSTRAINT PK_NotificationRecipient PRIMARY KEY CLUSTERED (NotificationID, EmployeeID)
    );
END
GO

/* ============================================================================
   16. FOREIGN KEYS
   Rerunnable: each FK is added only when it does not already exist by name.
   ============================================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_TaxRate_Enterprise')
ALTER TABLE dbo.TaxRate ADD CONSTRAINT FK_TaxRate_Enterprise
    FOREIGN KEY (EnterpriseID) REFERENCES organization.Enterprise(EnterpriseID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Company_Enterprise')
ALTER TABLE organization.Company ADD CONSTRAINT FK_Company_Enterprise
    FOREIGN KEY (EnterpriseID) REFERENCES organization.Enterprise(EnterpriseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Company_Address')
ALTER TABLE organization.Company ADD CONSTRAINT FK_Company_Address
    FOREIGN KEY (AddressID) REFERENCES dbo.Address(AddressID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Company_Currency')
ALTER TABLE organization.Company ADD CONSTRAINT FK_Company_Currency
    FOREIGN KEY (CurrencyID) REFERENCES dbo.Currency(CurrencyID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Branch_Company')
ALTER TABLE organization.Branch ADD CONSTRAINT FK_Branch_Company
    FOREIGN KEY (CompanyID) REFERENCES organization.Company(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Branch_Address')
ALTER TABLE organization.Branch ADD CONSTRAINT FK_Branch_Address
    FOREIGN KEY (AddressID) REFERENCES dbo.Address(AddressID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Department_Company')
ALTER TABLE organization.Department ADD CONSTRAINT FK_Department_Company
    FOREIGN KEY (CompanyID) REFERENCES organization.Company(CompanyID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Warehouse_Address')
ALTER TABLE warehouse.Warehouse ADD CONSTRAINT FK_Warehouse_Address
    FOREIGN KEY (AddressID) REFERENCES dbo.Address(AddressID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_WarehouseZone_Warehouse')
ALTER TABLE warehouse.WarehouseZone ADD CONSTRAINT FK_WarehouseZone_Warehouse
    FOREIGN KEY (WarehouseID) REFERENCES warehouse.Warehouse(WarehouseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StorageBin_Zone')
ALTER TABLE warehouse.StorageBin ADD CONSTRAINT FK_StorageBin_Zone
    FOREIGN KEY (ZoneID) REFERENCES warehouse.WarehouseZone(ZoneID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StorageBin_Warehouse')
ALTER TABLE warehouse.StorageBin ADD CONSTRAINT FK_StorageBin_Warehouse
    FOREIGN KEY (WarehouseID) REFERENCES warehouse.Warehouse(WarehouseID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Product_Brand')
ALTER TABLE catalog.Product ADD CONSTRAINT FK_Product_Brand
    FOREIGN KEY (BrandID) REFERENCES catalog.Brand(BrandID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ProductVariant_Product')
ALTER TABLE catalog.ProductVariant ADD CONSTRAINT FK_ProductVariant_Product
    FOREIGN KEY (ProductID) REFERENCES catalog.Product(ProductID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Category_Parent')
ALTER TABLE catalog.Category ADD CONSTRAINT FK_Category_Parent
    FOREIGN KEY (ParentCategoryID) REFERENCES catalog.Category(CategoryID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Supplier_Address')
ALTER TABLE procurement.Supplier ADD CONSTRAINT FK_Supplier_Address
    FOREIGN KEY (AddressID) REFERENCES dbo.Address(AddressID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PurchaseOrder_Company')
ALTER TABLE procurement.PurchaseOrder ADD CONSTRAINT FK_PurchaseOrder_Company
    FOREIGN KEY (CompanyID) REFERENCES organization.Company(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PurchaseOrder_Supplier')
ALTER TABLE procurement.PurchaseOrder ADD CONSTRAINT FK_PurchaseOrder_Supplier
    FOREIGN KEY (SupplierID) REFERENCES procurement.Supplier(SupplierID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PurchaseOrder_Warehouse')
ALTER TABLE procurement.PurchaseOrder ADD CONSTRAINT FK_PurchaseOrder_Warehouse
    FOREIGN KEY (WarehouseID) REFERENCES warehouse.Warehouse(WarehouseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PurchaseOrder_CreatedBy')
ALTER TABLE procurement.PurchaseOrder ADD CONSTRAINT FK_PurchaseOrder_CreatedBy
    FOREIGN KEY (CreatedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_POItem_PO')
ALTER TABLE procurement.PurchaseOrderItem ADD CONSTRAINT FK_POItem_PO
    FOREIGN KEY (PurchaseOrderID) REFERENCES procurement.PurchaseOrder(PurchaseOrderID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_POItem_Variant')
ALTER TABLE procurement.PurchaseOrderItem ADD CONSTRAINT FK_POItem_Variant
    FOREIGN KEY (VariantID) REFERENCES catalog.ProductVariant(VariantID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_POHistory_PO')
ALTER TABLE procurement.PurchaseOrderStatusHistory ADD CONSTRAINT FK_POHistory_PO
    FOREIGN KEY (PurchaseOrderID) REFERENCES procurement.PurchaseOrder(PurchaseOrderID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_POHistory_Employee')
ALTER TABLE procurement.PurchaseOrderStatusHistory ADD CONSTRAINT FK_POHistory_Employee
    FOREIGN KEY (ChangedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_GoodsReceipt_PO')
ALTER TABLE procurement.GoodsReceipt ADD CONSTRAINT FK_GoodsReceipt_PO
    FOREIGN KEY (PurchaseOrderID) REFERENCES procurement.PurchaseOrder(PurchaseOrderID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_GoodsReceipt_Warehouse')
ALTER TABLE procurement.GoodsReceipt ADD CONSTRAINT FK_GoodsReceipt_Warehouse
    FOREIGN KEY (WarehouseID) REFERENCES warehouse.Warehouse(WarehouseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_GoodsReceipt_Employee')
ALTER TABLE procurement.GoodsReceipt ADD CONSTRAINT FK_GoodsReceipt_Employee
    FOREIGN KEY (ReceivedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_GRItem_GR')
ALTER TABLE procurement.GoodsReceiptItem ADD CONSTRAINT FK_GRItem_GR
    FOREIGN KEY (GoodsReceiptID) REFERENCES procurement.GoodsReceipt(GoodsReceiptID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_GRItem_POItem')
ALTER TABLE procurement.GoodsReceiptItem ADD CONSTRAINT FK_GRItem_POItem
    FOREIGN KEY (PurchaseOrderItemID) REFERENCES procurement.PurchaseOrderItem(PurchaseOrderItemID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Inventory_Company')
ALTER TABLE inventory.Inventory ADD CONSTRAINT FK_Inventory_Company
    FOREIGN KEY (CompanyID) REFERENCES organization.Company(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Inventory_Bin')
ALTER TABLE inventory.Inventory ADD CONSTRAINT FK_Inventory_Bin
    FOREIGN KEY (BinID) REFERENCES warehouse.StorageBin(BinID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Inventory_Variant')
ALTER TABLE inventory.Inventory ADD CONSTRAINT FK_Inventory_Variant
    FOREIGN KEY (VariantID) REFERENCES catalog.ProductVariant(VariantID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_InventoryTransaction_Inventory')
ALTER TABLE inventory.InventoryTransaction ADD CONSTRAINT FK_InventoryTransaction_Inventory
    FOREIGN KEY (InventoryID) REFERENCES inventory.Inventory(InventoryID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_InventoryTransaction_Employee')
ALTER TABLE inventory.InventoryTransaction ADD CONSTRAINT FK_InventoryTransaction_Employee
    FOREIGN KEY (PerformedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Reservation_Inventory')
ALTER TABLE inventory.InventoryReservation ADD CONSTRAINT FK_Reservation_Inventory
    FOREIGN KEY (InventoryID) REFERENCES inventory.Inventory(InventoryID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Reservation_OrderItem')
ALTER TABLE inventory.InventoryReservation ADD CONSTRAINT FK_Reservation_OrderItem
    FOREIGN KEY (OrderItemID) REFERENCES sales.SalesOrderItem(OrderItemID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Transfer_FromCompany')
ALTER TABLE inventory.InventoryTransfer ADD CONSTRAINT FK_Transfer_FromCompany
    FOREIGN KEY (FromCompanyID) REFERENCES organization.Company(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Transfer_ToCompany')
ALTER TABLE inventory.InventoryTransfer ADD CONSTRAINT FK_Transfer_ToCompany
    FOREIGN KEY (ToCompanyID) REFERENCES organization.Company(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Transfer_FromWarehouse')
ALTER TABLE inventory.InventoryTransfer ADD CONSTRAINT FK_Transfer_FromWarehouse
    FOREIGN KEY (FromWarehouseID) REFERENCES warehouse.Warehouse(WarehouseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Transfer_ToWarehouse')
ALTER TABLE inventory.InventoryTransfer ADD CONSTRAINT FK_Transfer_ToWarehouse
    FOREIGN KEY (ToWarehouseID) REFERENCES warehouse.Warehouse(WarehouseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Transfer_RequestedBy')
ALTER TABLE inventory.InventoryTransfer ADD CONSTRAINT FK_Transfer_RequestedBy
    FOREIGN KEY (RequestedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Transfer_ApprovedBy')
ALTER TABLE inventory.InventoryTransfer ADD CONSTRAINT FK_Transfer_ApprovedBy
    FOREIGN KEY (ApprovedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_TransferItem_Transfer')
ALTER TABLE inventory.InventoryTransferItem ADD CONSTRAINT FK_TransferItem_Transfer
    FOREIGN KEY (TransferID) REFERENCES inventory.InventoryTransfer(TransferID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_TransferItem_FromInventory')
ALTER TABLE inventory.InventoryTransferItem ADD CONSTRAINT FK_TransferItem_FromInventory
    FOREIGN KEY (FromInventoryID) REFERENCES inventory.Inventory(InventoryID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_TransferItem_ToInventory')
ALTER TABLE inventory.InventoryTransferItem ADD CONSTRAINT FK_TransferItem_ToInventory
    FOREIGN KEY (ToInventoryID) REFERENCES inventory.Inventory(InventoryID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Customer_Enterprise')
ALTER TABLE sales.Customer ADD CONSTRAINT FK_Customer_Enterprise
    FOREIGN KEY (EnterpriseID) REFERENCES organization.Enterprise(EnterpriseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CustomerAddress_Customer')
ALTER TABLE sales.CustomerAddress ADD CONSTRAINT FK_CustomerAddress_Customer
    FOREIGN KEY (CustomerID) REFERENCES sales.Customer(CustomerID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SalesOrder_Company')
ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_Company
    FOREIGN KEY (CompanyID) REFERENCES organization.Company(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SalesOrder_Customer')
ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_Customer
    FOREIGN KEY (CustomerID) REFERENCES sales.Customer(CustomerID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SalesOrder_Branch')
ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_Branch
    FOREIGN KEY (BranchID) REFERENCES organization.Branch(BranchID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SalesOrder_Currency')
ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_Currency
    FOREIGN KEY (CurrencyID) REFERENCES dbo.Currency(CurrencyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SalesOrder_CreatedBy')
ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_CreatedBy
    FOREIGN KEY (CreatedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SalesOrderItem_Order')
ALTER TABLE sales.SalesOrderItem ADD CONSTRAINT FK_SalesOrderItem_Order
    FOREIGN KEY (OrderID) REFERENCES sales.SalesOrder(OrderID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SalesOrderItem_Variant')
ALTER TABLE sales.SalesOrderItem ADD CONSTRAINT FK_SalesOrderItem_Variant
    FOREIGN KEY (VariantID) REFERENCES catalog.ProductVariant(VariantID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_OrderAddress_Order')
ALTER TABLE sales.OrderAddress ADD CONSTRAINT FK_OrderAddress_Order
    FOREIGN KEY (OrderID) REFERENCES sales.SalesOrder(OrderID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_OrderHistory_Order')
ALTER TABLE sales.OrderStatusHistory ADD CONSTRAINT FK_OrderHistory_Order
    FOREIGN KEY (OrderID) REFERENCES sales.SalesOrder(OrderID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_OrderHistory_Employee')
ALTER TABLE sales.OrderStatusHistory ADD CONSTRAINT FK_OrderHistory_Employee
    FOREIGN KEY (ChangedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Payment_Order')
ALTER TABLE sales.Payment ADD CONSTRAINT FK_Payment_Order
    FOREIGN KEY (OrderID) REFERENCES sales.SalesOrder(OrderID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Payment_Currency')
ALTER TABLE sales.Payment ADD CONSTRAINT FK_Payment_Currency
    FOREIGN KEY (CurrencyID) REFERENCES dbo.Currency(CurrencyID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Fulfillment_Order')
ALTER TABLE logistics.Fulfillment ADD CONSTRAINT FK_Fulfillment_Order
    FOREIGN KEY (OrderID) REFERENCES sales.SalesOrder(OrderID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Fulfillment_Warehouse')
ALTER TABLE logistics.Fulfillment ADD CONSTRAINT FK_Fulfillment_Warehouse
    FOREIGN KEY (WarehouseID) REFERENCES warehouse.Warehouse(WarehouseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_FulfillmentItem_Fulfillment')
ALTER TABLE logistics.FulfillmentItem ADD CONSTRAINT FK_FulfillmentItem_Fulfillment
    FOREIGN KEY (FulfillmentID) REFERENCES logistics.Fulfillment(FulfillmentID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_FulfillmentItem_OrderItem')
ALTER TABLE logistics.FulfillmentItem ADD CONSTRAINT FK_FulfillmentItem_OrderItem
    FOREIGN KEY (OrderItemID) REFERENCES sales.SalesOrderItem(OrderItemID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Shipment_Fulfillment')
ALTER TABLE logistics.Shipment ADD CONSTRAINT FK_Shipment_Fulfillment
    FOREIGN KEY (FulfillmentID) REFERENCES logistics.Fulfillment(FulfillmentID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Shipment_Carrier')
ALTER TABLE logistics.Shipment ADD CONSTRAINT FK_Shipment_Carrier
    FOREIGN KEY (CarrierID) REFERENCES logistics.Carrier(CarrierID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ShipmentItem_Shipment')
ALTER TABLE logistics.ShipmentItem ADD CONSTRAINT FK_ShipmentItem_Shipment
    FOREIGN KEY (ShipmentID) REFERENCES logistics.Shipment(ShipmentID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ShipmentItem_FulfillmentItem')
ALTER TABLE logistics.ShipmentItem ADD CONSTRAINT FK_ShipmentItem_FulfillmentItem
    FOREIGN KEY (FulfillmentItemID) REFERENCES logistics.FulfillmentItem(FulfillmentItemID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_TrackingEvent_Shipment')
ALTER TABLE logistics.ShipmentTrackingEvent ADD CONSTRAINT FK_TrackingEvent_Shipment
    FOREIGN KEY (ShipmentID) REFERENCES logistics.Shipment(ShipmentID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnRequest_Order')
ALTER TABLE returns.ReturnRequest ADD CONSTRAINT FK_ReturnRequest_Order
    FOREIGN KEY (OrderID) REFERENCES sales.SalesOrder(OrderID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnRequest_RequestedBy')
ALTER TABLE returns.ReturnRequest ADD CONSTRAINT FK_ReturnRequest_RequestedBy
    FOREIGN KEY (RequestedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnRequest_ApprovedBy')
ALTER TABLE returns.ReturnRequest ADD CONSTRAINT FK_ReturnRequest_ApprovedBy
    FOREIGN KEY (ApprovedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnItem_Return')
ALTER TABLE returns.ReturnRequestItem ADD CONSTRAINT FK_ReturnItem_Return
    FOREIGN KEY (ReturnRequestID) REFERENCES returns.ReturnRequest(ReturnRequestID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnItem_OrderItem')
ALTER TABLE returns.ReturnRequestItem ADD CONSTRAINT FK_ReturnItem_OrderItem
    FOREIGN KEY (OrderItemID) REFERENCES sales.SalesOrderItem(OrderItemID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnHistory_Return')
ALTER TABLE returns.ReturnStatusHistory ADD CONSTRAINT FK_ReturnHistory_Return
    FOREIGN KEY (ReturnRequestID) REFERENCES returns.ReturnRequest(ReturnRequestID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnHistory_Employee')
ALTER TABLE returns.ReturnStatusHistory ADD CONSTRAINT FK_ReturnHistory_Employee
    FOREIGN KEY (ChangedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnReceipt_Return')
ALTER TABLE returns.ReturnReceipt ADD CONSTRAINT FK_ReturnReceipt_Return
    FOREIGN KEY (ReturnRequestID) REFERENCES returns.ReturnRequest(ReturnRequestID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnReceipt_Warehouse')
ALTER TABLE returns.ReturnReceipt ADD CONSTRAINT FK_ReturnReceipt_Warehouse
    FOREIGN KEY (WarehouseID) REFERENCES warehouse.Warehouse(WarehouseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnReceipt_Employee')
ALTER TABLE returns.ReturnReceipt ADD CONSTRAINT FK_ReturnReceipt_Employee
    FOREIGN KEY (ReceivedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnInspection_Receipt')
ALTER TABLE returns.ReturnInspection ADD CONSTRAINT FK_ReturnInspection_Receipt
    FOREIGN KEY (ReturnReceiptID) REFERENCES returns.ReturnReceipt(ReturnReceiptID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnInspection_Employee')
ALTER TABLE returns.ReturnInspection ADD CONSTRAINT FK_ReturnInspection_Employee
    FOREIGN KEY (InspectedBy) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnInspectionItem_Inspection')
ALTER TABLE returns.ReturnInspectionItem ADD CONSTRAINT FK_ReturnInspectionItem_Inspection
    FOREIGN KEY (InspectionID) REFERENCES returns.ReturnInspection(InspectionID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnInspectionItem_ReturnItem')
ALTER TABLE returns.ReturnInspectionItem ADD CONSTRAINT FK_ReturnInspectionItem_ReturnItem
    FOREIGN KEY (ReturnItemID) REFERENCES returns.ReturnRequestItem(ReturnItemID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnDisposition_InspectionItem')
ALTER TABLE returns.ReturnDisposition ADD CONSTRAINT FK_ReturnDisposition_InspectionItem
    FOREIGN KEY (InspectionItemID) REFERENCES returns.ReturnInspectionItem(InspectionItemID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnDisposition_Warehouse')
ALTER TABLE returns.ReturnDisposition ADD CONSTRAINT FK_ReturnDisposition_Warehouse
    FOREIGN KEY (WarehouseID) REFERENCES warehouse.Warehouse(WarehouseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReturnDisposition_Bin')
ALTER TABLE returns.ReturnDisposition ADD CONSTRAINT FK_ReturnDisposition_Bin
    FOREIGN KEY (BinID) REFERENCES warehouse.StorageBin(BinID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Refund_ReturnRequest')
ALTER TABLE returns.Refund ADD CONSTRAINT FK_Refund_ReturnRequest
    FOREIGN KEY (ReturnRequestID) REFERENCES returns.ReturnRequest(ReturnRequestID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Refund_Payment')
ALTER TABLE returns.Refund ADD CONSTRAINT FK_Refund_Payment
    FOREIGN KEY (PaymentID) REFERENCES sales.Payment(PaymentID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Refund_Currency')
ALTER TABLE returns.Refund ADD CONSTRAINT FK_Refund_Currency
    FOREIGN KEY (CurrencyID) REFERENCES dbo.Currency(CurrencyID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationType_Notification')
ALTER TABLE notifications.Notification ADD CONSTRAINT FK_NotificationType_Notification
    FOREIGN KEY (NotificationTypeID) REFERENCES notifications.NotificationType(NotificationTypeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AlertRule_Company')
ALTER TABLE notifications.AlertRule ADD CONSTRAINT FK_AlertRule_Company
    FOREIGN KEY (CompanyID) REFERENCES organization.Company(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AlertRule_NotificationType')
ALTER TABLE notifications.AlertRule ADD CONSTRAINT FK_AlertRule_NotificationType
    FOREIGN KEY (NotificationTypeID) REFERENCES notifications.NotificationType(NotificationTypeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AlertInstance_Rule')
ALTER TABLE notifications.AlertInstance ADD CONSTRAINT FK_AlertInstance_Rule
    FOREIGN KEY (AlertRuleID) REFERENCES notifications.AlertRule(AlertRuleID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AppUser_Employee')
ALTER TABLE security.AppUser ADD CONSTRAINT FK_AppUser_Employee
    FOREIGN KEY (EmployeeID) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SecurityEventLog_User')
ALTER TABLE audit.SecurityEventLog ADD CONSTRAINT FK_SecurityEventLog_User
    FOREIGN KEY (UserID) REFERENCES security.AppUser(UserID);
GO

/* ============================================================================
   17. M:N FOREIGN KEYS
   ============================================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_EmployeeDepartment_Employee')
ALTER TABLE organization.EmployeeDepartment ADD CONSTRAINT FK_EmployeeDepartment_Employee
    FOREIGN KEY (EmployeeID) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_EmployeeDepartment_Department')
ALTER TABLE organization.EmployeeDepartment ADD CONSTRAINT FK_EmployeeDepartment_Department
    FOREIGN KEY (DepartmentID) REFERENCES organization.Department(DepartmentID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_EmployeeRole_Employee')
ALTER TABLE organization.EmployeeRole ADD CONSTRAINT FK_EmployeeRole_Employee
    FOREIGN KEY (EmployeeID) REFERENCES organization.Employee(EmployeeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_EmployeeRole_Role')
ALTER TABLE organization.EmployeeRole ADD CONSTRAINT FK_EmployeeRole_Role
    FOREIGN KEY (RoleID) REFERENCES organization.Role(RoleID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanyWarehouse_Company')
ALTER TABLE organization.CompanyWarehouse ADD CONSTRAINT FK_CompanyWarehouse_Company
    FOREIGN KEY (CompanyID) REFERENCES organization.Company(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanyWarehouse_Warehouse')
ALTER TABLE organization.CompanyWarehouse ADD CONSTRAINT FK_CompanyWarehouse_Warehouse
    FOREIGN KEY (WarehouseID) REFERENCES warehouse.Warehouse(WarehouseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanyProduct_Company')
ALTER TABLE catalog.CompanyProduct ADD CONSTRAINT FK_CompanyProduct_Company
    FOREIGN KEY (CompanyID) REFERENCES organization.Company(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanyProduct_Variant')
ALTER TABLE catalog.CompanyProduct ADD CONSTRAINT FK_CompanyProduct_Variant
    FOREIGN KEY (VariantID) REFERENCES catalog.ProductVariant(VariantID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ProductCategory_Product')
ALTER TABLE catalog.ProductCategory ADD CONSTRAINT FK_ProductCategory_Product
    FOREIGN KEY (ProductID) REFERENCES catalog.Product(ProductID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ProductCategory_Category')
ALTER TABLE catalog.ProductCategory ADD CONSTRAINT FK_ProductCategory_Category
    FOREIGN KEY (CategoryID) REFERENCES catalog.Category(CategoryID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySupplier_Company')
ALTER TABLE procurement.CompanySupplier ADD CONSTRAINT FK_CompanySupplier_Company
    FOREIGN KEY (CompanyID) REFERENCES organization.Company(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySupplier_Supplier')
ALTER TABLE procurement.CompanySupplier ADD CONSTRAINT FK_CompanySupplier_Supplier
    FOREIGN KEY (SupplierID) REFERENCES procurement.Supplier(SupplierID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SupplierProduct_Supplier')
ALTER TABLE procurement.SupplierProduct ADD CONSTRAINT FK_SupplierProduct_Supplier
    FOREIGN KEY (SupplierID) REFERENCES procurement.Supplier(SupplierID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SupplierProduct_Variant')
ALTER TABLE procurement.SupplierProduct ADD CONSTRAINT FK_SupplierProduct_Variant
    FOREIGN KEY (VariantID) REFERENCES catalog.ProductVariant(VariantID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanyCustomer_Company')
ALTER TABLE sales.CompanyCustomer ADD CONSTRAINT FK_CompanyCustomer_Company
    FOREIGN KEY (CompanyID) REFERENCES organization.Company(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanyCustomer_Customer')
ALTER TABLE sales.CompanyCustomer ADD CONSTRAINT FK_CompanyCustomer_Customer
    FOREIGN KEY (CustomerID) REFERENCES sales.Customer(CustomerID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationRecipient_Notification')
ALTER TABLE notifications.NotificationRecipient ADD CONSTRAINT FK_NotificationRecipient_Notification
    FOREIGN KEY (NotificationID) REFERENCES notifications.Notification(NotificationID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationRecipient_Employee')
ALTER TABLE notifications.NotificationRecipient ADD CONSTRAINT FK_NotificationRecipient_Employee
    FOREIGN KEY (EmployeeID) REFERENCES organization.Employee(EmployeeID);
GO

/* ============================================================================
   18. INDEXES
   ============================================================================ */

-- Barcode must be unique only when present: a filtered unique index (unlike a
-- table-level UNIQUE constraint) allows any number of NULLs, so multiple
-- variants can exist without a barcode yet assigned.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_ProductVariant_Barcode' AND object_id = OBJECT_ID(N'catalog.ProductVariant'))
    CREATE UNIQUE INDEX UQ_ProductVariant_Barcode ON catalog.ProductVariant(Barcode) WHERE Barcode IS NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Company_EnterpriseID' AND object_id = OBJECT_ID(N'organization.Company'))
    CREATE INDEX IX_Company_EnterpriseID ON organization.Company(EnterpriseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Branch_CompanyID' AND object_id = OBJECT_ID(N'organization.Branch'))
    CREATE INDEX IX_Branch_CompanyID ON organization.Branch(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Department_CompanyID' AND object_id = OBJECT_ID(N'organization.Department'))
    CREATE INDEX IX_Department_CompanyID ON organization.Department(CompanyID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_TaxRate_Enterprise_Effective' AND object_id = OBJECT_ID(N'dbo.TaxRate'))
    CREATE INDEX IX_TaxRate_Enterprise_Effective ON dbo.TaxRate(EnterpriseID, EffectiveFrom, EffectiveTo);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_WarehouseZone_WarehouseID' AND object_id = OBJECT_ID(N'warehouse.WarehouseZone'))
    CREATE INDEX IX_WarehouseZone_WarehouseID ON warehouse.WarehouseZone(WarehouseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_StorageBin_ZoneID' AND object_id = OBJECT_ID(N'warehouse.StorageBin'))
    CREATE INDEX IX_StorageBin_ZoneID ON warehouse.StorageBin(ZoneID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ProductVariant_ProductID' AND object_id = OBJECT_ID(N'catalog.ProductVariant'))
    CREATE INDEX IX_ProductVariant_ProductID ON catalog.ProductVariant(ProductID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Category_ParentCategoryID' AND object_id = OBJECT_ID(N'catalog.Category'))
    CREATE INDEX IX_Category_ParentCategoryID ON catalog.Category(ParentCategoryID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PO_Company_Status_Date' AND object_id = OBJECT_ID(N'procurement.PurchaseOrder'))
    CREATE INDEX IX_PO_Company_Status_Date ON procurement.PurchaseOrder(CompanyID, Status, OrderDate DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PO_SupplierID' AND object_id = OBJECT_ID(N'procurement.PurchaseOrder'))
    CREATE INDEX IX_PO_SupplierID ON procurement.PurchaseOrder(SupplierID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_POItem_VariantID' AND object_id = OBJECT_ID(N'procurement.PurchaseOrderItem'))
    CREATE INDEX IX_POItem_VariantID ON procurement.PurchaseOrderItem(VariantID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_GoodsReceipt_PO_Date' AND object_id = OBJECT_ID(N'procurement.GoodsReceipt'))
    CREATE INDEX IX_GoodsReceipt_PO_Date ON procurement.GoodsReceipt(PurchaseOrderID, ReceivedDate DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Inventory_Company_Variant' AND object_id = OBJECT_ID(N'inventory.Inventory'))
    CREATE INDEX IX_Inventory_Company_Variant ON inventory.Inventory(CompanyID, VariantID) INCLUDE (BinID, OnHandQuantity, ReservedQuantity, DamagedQuantity);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Inventory_Bin_Variant' AND object_id = OBJECT_ID(N'inventory.Inventory'))
    CREATE INDEX IX_Inventory_Bin_Variant ON inventory.Inventory(BinID, VariantID) INCLUDE (CompanyID, OnHandQuantity, ReservedQuantity, DamagedQuantity);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_InventoryTransaction_Inventory_Date' AND object_id = OBJECT_ID(N'inventory.InventoryTransaction'))
    CREATE INDEX IX_InventoryTransaction_Inventory_Date ON inventory.InventoryTransaction(InventoryID, TransactionDate DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_InventoryReservation_OrderItem_Status' AND object_id = OBJECT_ID(N'inventory.InventoryReservation'))
    CREATE INDEX IX_InventoryReservation_OrderItem_Status ON inventory.InventoryReservation(OrderItemID, Status);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Transfer_Status_Date' AND object_id = OBJECT_ID(N'inventory.InventoryTransfer'))
    CREATE INDEX IX_Transfer_Status_Date ON inventory.InventoryTransfer(Status, CreatedAt DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Customer_EnterpriseID' AND object_id = OBJECT_ID(N'sales.Customer'))
    CREATE INDEX IX_Customer_EnterpriseID ON sales.Customer(EnterpriseID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrder_Company_Status_Date' AND object_id = OBJECT_ID(N'sales.SalesOrder'))
    CREATE INDEX IX_SalesOrder_Company_Status_Date ON sales.SalesOrder(CompanyID, Status, OrderDate DESC) INCLUDE (CustomerID, TotalAmount);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrder_Customer_Date' AND object_id = OBJECT_ID(N'sales.SalesOrder'))
    CREATE INDEX IX_SalesOrder_Customer_Date ON sales.SalesOrder(CustomerID, OrderDate DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrderItem_VariantID' AND object_id = OBJECT_ID(N'sales.SalesOrderItem'))
    CREATE INDEX IX_SalesOrderItem_VariantID ON sales.SalesOrderItem(VariantID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Payment_Order_Status' AND object_id = OBJECT_ID(N'sales.Payment'))
    CREATE INDEX IX_Payment_Order_Status ON sales.Payment(OrderID, Status);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Fulfillment_Order_Status' AND object_id = OBJECT_ID(N'logistics.Fulfillment'))
    CREATE INDEX IX_Fulfillment_Order_Status ON logistics.Fulfillment(OrderID, Status);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Fulfillment_Warehouse_Status' AND object_id = OBJECT_ID(N'logistics.Fulfillment'))
    CREATE INDEX IX_Fulfillment_Warehouse_Status ON logistics.Fulfillment(WarehouseID, Status);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Shipment_FulfillmentID' AND object_id = OBJECT_ID(N'logistics.Shipment'))
    CREATE INDEX IX_Shipment_FulfillmentID ON logistics.Shipment(FulfillmentID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Shipment_Status' AND object_id = OBJECT_ID(N'logistics.Shipment'))
    CREATE INDEX IX_Shipment_Status ON logistics.Shipment(Status, ShippedAt);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_TrackingEvent_Shipment_Time' AND object_id = OBJECT_ID(N'logistics.ShipmentTrackingEvent'))
    CREATE INDEX IX_TrackingEvent_Shipment_Time ON logistics.ShipmentTrackingEvent(ShipmentID, EventTime DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ReturnRequest_Order_Status' AND object_id = OBJECT_ID(N'returns.ReturnRequest'))
    CREATE INDEX IX_ReturnRequest_Order_Status ON returns.ReturnRequest(OrderID, Status, RequestedAt DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ReturnReceipt_Warehouse_Date' AND object_id = OBJECT_ID(N'returns.ReturnReceipt'))
    CREATE INDEX IX_ReturnReceipt_Warehouse_Date ON returns.ReturnReceipt(WarehouseID, ReceivedAt DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Refund_ReturnRequest_Status' AND object_id = OBJECT_ID(N'returns.Refund'))
    CREATE INDEX IX_Refund_ReturnRequest_Status ON returns.Refund(ReturnRequestID, Status);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Notification_Status_Created' AND object_id = OBJECT_ID(N'notifications.Notification'))
    CREATE INDEX IX_Notification_Status_Created ON notifications.Notification(Status, CreatedAt DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AlertInstance_Rule_Status' AND object_id = OBJECT_ID(N'notifications.AlertInstance'))
    CREATE INDEX IX_AlertInstance_Rule_Status ON notifications.AlertInstance(AlertRuleID, Status, LastDetectedAt DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DataChangeLog_Table_Record_Date' AND object_id = OBJECT_ID(N'audit.DataChangeLog'))
    CREATE INDEX IX_DataChangeLog_Table_Record_Date ON audit.DataChangeLog(TableName, RecordID, ChangedAt DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SecurityEventLog_User_Time' AND object_id = OBJECT_ID(N'audit.SecurityEventLog'))
    CREATE INDEX IX_SecurityEventLog_User_Time ON audit.SecurityEventLog(UserID, EventTime DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ErrorLog_OccurredAt' AND object_id = OBJECT_ID(N'audit.ErrorLog'))
    CREATE INDEX IX_ErrorLog_OccurredAt ON audit.ErrorLog(OccurredAt DESC);
GO

/* ============================================================================
   19. AUDIT COLUMNS (UpdatedAt)
   Added via ALTER so the CREATE TABLE blocks above stay untouched/rerunnable.
   UpdatedAt is set at INSERT time by the DEFAULT and kept current afterwards
   by the triggers in section 20.1.
   ============================================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'organization.Company') AND name = 'UpdatedAt')
ALTER TABLE organization.Company ADD UpdatedAt datetime2(3) NOT NULL CONSTRAINT DF_Company_UpdatedAt DEFAULT (SYSUTCDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'procurement.Supplier') AND name = 'UpdatedAt')
ALTER TABLE procurement.Supplier ADD UpdatedAt datetime2(3) NOT NULL CONSTRAINT DF_Supplier_UpdatedAt DEFAULT (SYSUTCDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'sales.Customer') AND name = 'UpdatedAt')
ALTER TABLE sales.Customer ADD UpdatedAt datetime2(3) NOT NULL CONSTRAINT DF_Customer_UpdatedAt DEFAULT (SYSUTCDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'warehouse.Warehouse') AND name = 'UpdatedAt')
ALTER TABLE warehouse.Warehouse ADD UpdatedAt datetime2(3) NOT NULL CONSTRAINT DF_Warehouse_UpdatedAt DEFAULT (SYSUTCDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'catalog.Product') AND name = 'UpdatedAt')
ALTER TABLE catalog.Product ADD UpdatedAt datetime2(3) NOT NULL CONSTRAINT DF_Product_UpdatedAt DEFAULT (SYSUTCDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'catalog.ProductVariant') AND name = 'UpdatedAt')
ALTER TABLE catalog.ProductVariant ADD UpdatedAt datetime2(3) NOT NULL CONSTRAINT DF_ProductVariant_UpdatedAt DEFAULT (SYSUTCDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'procurement.PurchaseOrder') AND name = 'UpdatedAt')
ALTER TABLE procurement.PurchaseOrder ADD UpdatedAt datetime2(3) NOT NULL CONSTRAINT DF_PurchaseOrder_UpdatedAt DEFAULT (SYSUTCDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'sales.SalesOrder') AND name = 'UpdatedAt')
ALTER TABLE sales.SalesOrder ADD UpdatedAt datetime2(3) NOT NULL CONSTRAINT DF_SalesOrder_UpdatedAt DEFAULT (SYSUTCDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'logistics.Fulfillment') AND name = 'UpdatedAt')
ALTER TABLE logistics.Fulfillment ADD UpdatedAt datetime2(3) NOT NULL CONSTRAINT DF_Fulfillment_UpdatedAt DEFAULT (SYSUTCDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'logistics.Shipment') AND name = 'UpdatedAt')
ALTER TABLE logistics.Shipment ADD UpdatedAt datetime2(3) NOT NULL CONSTRAINT DF_Shipment_UpdatedAt DEFAULT (SYSUTCDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'returns.ReturnRequest') AND name = 'UpdatedAt')
ALTER TABLE returns.ReturnRequest ADD UpdatedAt datetime2(3) NOT NULL CONSTRAINT DF_ReturnRequest_UpdatedAt DEFAULT (SYSUTCDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'security.AppUser') AND name = 'UpdatedAt')
ALTER TABLE security.AppUser ADD UpdatedAt datetime2(3) NOT NULL CONSTRAINT DF_AppUser_UpdatedAt DEFAULT (SYSUTCDATETIME());
GO

/* ============================================================================
   20. TRIGGERS
   ============================================================================ */

/* ---------- 20.1 UpdatedAt auto-maintenance ----------
   IF UPDATE(UpdatedAt) short-circuits when the caller already set UpdatedAt
   explicitly, so the trigger does not fight an intentional value. */

IF OBJECT_ID(N'organization.trg_Company_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER organization.trg_Company_UpdatedAt ON organization.Company AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM organization.Company t INNER JOIN inserted i ON t.CompanyID = i.CompanyID;
END');
GO

IF OBJECT_ID(N'procurement.trg_Supplier_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER procurement.trg_Supplier_UpdatedAt ON procurement.Supplier AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM procurement.Supplier t INNER JOIN inserted i ON t.SupplierID = i.SupplierID;
END');
GO

IF OBJECT_ID(N'sales.trg_Customer_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER sales.trg_Customer_UpdatedAt ON sales.Customer AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM sales.Customer t INNER JOIN inserted i ON t.CustomerID = i.CustomerID;
END');
GO

IF OBJECT_ID(N'warehouse.trg_Warehouse_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER warehouse.trg_Warehouse_UpdatedAt ON warehouse.Warehouse AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM warehouse.Warehouse t INNER JOIN inserted i ON t.WarehouseID = i.WarehouseID;
END');
GO

IF OBJECT_ID(N'catalog.trg_Product_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER catalog.trg_Product_UpdatedAt ON catalog.Product AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM catalog.Product t INNER JOIN inserted i ON t.ProductID = i.ProductID;
END');
GO

IF OBJECT_ID(N'catalog.trg_ProductVariant_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER catalog.trg_ProductVariant_UpdatedAt ON catalog.ProductVariant AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM catalog.ProductVariant t INNER JOIN inserted i ON t.VariantID = i.VariantID;
END');
GO

IF OBJECT_ID(N'procurement.trg_PurchaseOrder_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER procurement.trg_PurchaseOrder_UpdatedAt ON procurement.PurchaseOrder AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM procurement.PurchaseOrder t INNER JOIN inserted i ON t.PurchaseOrderID = i.PurchaseOrderID;
END');
GO

IF OBJECT_ID(N'sales.trg_SalesOrder_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER sales.trg_SalesOrder_UpdatedAt ON sales.SalesOrder AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM sales.SalesOrder t INNER JOIN inserted i ON t.OrderID = i.OrderID;
END');
GO

IF OBJECT_ID(N'logistics.trg_Fulfillment_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER logistics.trg_Fulfillment_UpdatedAt ON logistics.Fulfillment AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM logistics.Fulfillment t INNER JOIN inserted i ON t.FulfillmentID = i.FulfillmentID;
END');
GO

IF OBJECT_ID(N'logistics.trg_Shipment_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER logistics.trg_Shipment_UpdatedAt ON logistics.Shipment AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM logistics.Shipment t INNER JOIN inserted i ON t.ShipmentID = i.ShipmentID;
END');
GO

IF OBJECT_ID(N'returns.trg_ReturnRequest_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER returns.trg_ReturnRequest_UpdatedAt ON returns.ReturnRequest AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM returns.ReturnRequest t INNER JOIN inserted i ON t.ReturnRequestID = i.ReturnRequestID;
END');
GO

IF OBJECT_ID(N'security.trg_AppUser_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER security.trg_AppUser_UpdatedAt ON security.AppUser AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM security.AppUser t INNER JOIN inserted i ON t.UserID = i.UserID;
END');
GO

IF OBJECT_ID(N'inventory.trg_Inventory_UpdatedAt', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER inventory.trg_Inventory_UpdatedAt ON inventory.Inventory AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN;
    UPDATE t SET UpdatedAt = SYSUTCDATETIME()
    FROM inventory.Inventory t INNER JOIN inserted i ON t.InventoryID = i.InventoryID;
END');
GO

/* ---------- 20.2 Cross-row business-rule enforcement ----------
   These implement the rules listed under section 19''s notes, which a
   single-row CHECK constraint cannot express. Each rolls back the batch
   with RAISERROR if the business rule is violated. */

-- BR-PO-006: total received per PO line must never exceed ordered quantity
IF OBJECT_ID(N'procurement.trg_GoodsReceiptItem_QtyCheck', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER procurement.trg_GoodsReceiptItem_QtyCheck ON procurement.GoodsReceiptItem AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT PurchaseOrderItemID FROM inserted) x
        INNER JOIN procurement.PurchaseOrderItem poi ON poi.PurchaseOrderItemID = x.PurchaseOrderItemID
        WHERE (SELECT ISNULL(SUM(g.ReceivedQuantity), 0)
               FROM procurement.GoodsReceiptItem g
               WHERE g.PurchaseOrderItemID = x.PurchaseOrderItemID) > poi.OrderedQuantity
    )
    BEGIN
        RAISERROR(N''Total received quantity exceeds ordered quantity for a Purchase Order Item.'', 16, 1);
        ROLLBACK TRANSACTION;
    END
END');
GO

-- BR-INV-005/006/BR-RES-003: keep Inventory.ReservedQuantity in sync with active
-- reservations; the existing CK_Inventory_Reserved (Reserved <= OnHand) then
-- blocks any oversell as part of this same UPDATE.
IF OBJECT_ID(N'inventory.trg_InventoryReservation_Sync', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER inventory.trg_InventoryReservation_Sync ON inventory.InventoryReservation AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE inv
    SET ReservedQuantity = ISNULL((
            SELECT SUM(r.Quantity) FROM inventory.InventoryReservation r
            WHERE r.InventoryID = inv.InventoryID AND r.Status = ''ACTIVE''
        ), 0)
    FROM inventory.Inventory inv
    WHERE inv.InventoryID IN (SELECT InventoryID FROM inserted UNION SELECT InventoryID FROM deleted);
END');
GO

-- BR-FUL-005: total fulfilled quantity per Order Item must never exceed ordered quantity
IF OBJECT_ID(N'logistics.trg_FulfillmentItem_QtyCheck', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER logistics.trg_FulfillmentItem_QtyCheck ON logistics.FulfillmentItem AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT OrderItemID FROM inserted) x
        INNER JOIN sales.SalesOrderItem soi ON soi.OrderItemID = x.OrderItemID
        WHERE (SELECT ISNULL(SUM(f.Quantity), 0)
               FROM logistics.FulfillmentItem f
               WHERE f.OrderItemID = x.OrderItemID) > soi.Quantity
    )
    BEGIN
        RAISERROR(N''Total fulfilled quantity exceeds ordered quantity for a Sales Order Item.'', 16, 1);
        ROLLBACK TRANSACTION;
    END
END');
GO

-- BR-SHIP-005: total shipped quantity per Fulfillment Item must never exceed its fulfilled quantity
IF OBJECT_ID(N'logistics.trg_ShipmentItem_QtyCheck', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER logistics.trg_ShipmentItem_QtyCheck ON logistics.ShipmentItem AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT FulfillmentItemID FROM inserted) x
        INNER JOIN logistics.FulfillmentItem fi ON fi.FulfillmentItemID = x.FulfillmentItemID
        WHERE (SELECT ISNULL(SUM(s.Quantity), 0)
               FROM logistics.ShipmentItem s
               WHERE s.FulfillmentItemID = x.FulfillmentItemID) > fi.Quantity
    )
    BEGIN
        RAISERROR(N''Total shipped quantity exceeds fulfilled quantity for a Fulfillment Item.'', 16, 1);
        ROLLBACK TRANSACTION;
    END
END');
GO

-- BR-RET-004: cumulative approved return quantity per Order Item must never exceed purchased quantity
IF OBJECT_ID(N'returns.trg_ReturnRequestItem_QtyCheck', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER returns.trg_ReturnRequestItem_QtyCheck ON returns.ReturnRequestItem AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT OrderItemID FROM inserted) x
        INNER JOIN sales.SalesOrderItem soi ON soi.OrderItemID = x.OrderItemID
        WHERE (SELECT ISNULL(SUM(ri.ApprovedQuantity), 0)
               FROM returns.ReturnRequestItem ri
               WHERE ri.OrderItemID = x.OrderItemID) > soi.Quantity
    )
    BEGIN
        RAISERROR(N''Cumulative approved return quantity exceeds the purchased quantity for a Sales Order Item.'', 16, 1);
        ROLLBACK TRANSACTION;
    END
END');
GO

-- BR-REF-003: total successful refunds per Payment must never exceed the successfully paid amount
IF OBJECT_ID(N'returns.trg_Refund_AmountCheck', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER returns.trg_Refund_AmountCheck ON returns.Refund AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT PaymentID FROM inserted) x
        INNER JOIN sales.Payment p ON p.PaymentID = x.PaymentID
        WHERE (SELECT ISNULL(SUM(r.Amount), 0)
               FROM returns.Refund r
               WHERE r.PaymentID = x.PaymentID AND r.Status = ''SUCCESS'') >
              (CASE WHEN p.Status = ''SUCCESS'' THEN p.Amount ELSE 0 END)
    )
    BEGIN
        RAISERROR(N''Total successful refunds exceed the successfully paid amount for this Payment.'', 16, 1);
        ROLLBACK TRANSACTION;
    END
END');
GO

/* ---------- 20.3 Change audit (BR-34) ----------
   Representative coverage on the financially/operationally sensitive header
   tables the BRD names explicitly (Purchase Order, Sales Order, Payment,
   Refund). Extend the same pattern to further tables if the assignment
   requires wider coverage.
   ChangedBy is read from SESSION_CONTEXT(''EmployeeID''); the application
   layer must call sp_set_session_context before its DML, e.g.:
       EXEC sp_set_session_context @key = N''EmployeeID'', @value = @EmployeeID; */

IF OBJECT_ID(N'sales.trg_SalesOrder_Audit', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER sales.trg_SalesOrder_Audit ON sales.SalesOrder AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO audit.DataChangeLog (TableName, RecordID, Operation, OldValue, NewValue, ChangedBy)
    SELECT ''sales.SalesOrder'', CAST(i.OrderID AS nvarchar(200)), ''UPDATE'',
           (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           TRY_CAST(SESSION_CONTEXT(N''EmployeeID'') AS bigint)
    FROM inserted i INNER JOIN deleted d ON i.OrderID = d.OrderID;
END');
GO

IF OBJECT_ID(N'procurement.trg_PurchaseOrder_Audit', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER procurement.trg_PurchaseOrder_Audit ON procurement.PurchaseOrder AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO audit.DataChangeLog (TableName, RecordID, Operation, OldValue, NewValue, ChangedBy)
    SELECT ''procurement.PurchaseOrder'', CAST(i.PurchaseOrderID AS nvarchar(200)), ''UPDATE'',
           (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           TRY_CAST(SESSION_CONTEXT(N''EmployeeID'') AS bigint)
    FROM inserted i INNER JOIN deleted d ON i.PurchaseOrderID = d.PurchaseOrderID;
END');
GO

IF OBJECT_ID(N'sales.trg_Payment_Audit', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER sales.trg_Payment_Audit ON sales.Payment AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO audit.DataChangeLog (TableName, RecordID, Operation, OldValue, NewValue, ChangedBy)
    SELECT ''sales.Payment'', CAST(i.PaymentID AS nvarchar(200)), ''UPDATE'',
           (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           TRY_CAST(SESSION_CONTEXT(N''EmployeeID'') AS bigint)
    FROM inserted i INNER JOIN deleted d ON i.PaymentID = d.PaymentID;
END');
GO

IF OBJECT_ID(N'returns.trg_Refund_Audit', N'TR') IS NULL
EXEC(N'
CREATE TRIGGER returns.trg_Refund_Audit ON returns.Refund AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO audit.DataChangeLog (TableName, RecordID, Operation, OldValue, NewValue, ChangedBy)
    SELECT ''returns.Refund'', CAST(i.RefundID AS nvarchar(200)), ''UPDATE'',
           (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           TRY_CAST(SESSION_CONTEXT(N''EmployeeID'') AS bigint)
    FROM inserted i INNER JOIN deleted d ON i.RefundID = d.RefundID;
END');
GO

/* ============================================================================
   21. REPORTING VIEWS  (BRD section 42)
   ============================================================================ */

-- Sales by Company / by Product / by Customer
IF OBJECT_ID(N'sales.vw_SalesByCompany', N'V') IS NOT NULL DROP VIEW sales.vw_SalesByCompany;
GO
CREATE VIEW sales.vw_SalesByCompany AS
SELECT so.CompanyID, c.Name AS CompanyName,
       COUNT(DISTINCT so.OrderID) AS OrderCount,
       SUM(so.TotalAmount) AS TotalSales,
       CAST(so.OrderDate AS date) AS OrderDate
FROM sales.SalesOrder so
INNER JOIN organization.Company c ON c.CompanyID = so.CompanyID
WHERE so.Status NOT IN ('DRAFT', 'CANCELLED')
GROUP BY so.CompanyID, c.Name, CAST(so.OrderDate AS date);
GO

IF OBJECT_ID(N'sales.vw_SalesByProduct', N'V') IS NOT NULL DROP VIEW sales.vw_SalesByProduct;
GO
CREATE VIEW sales.vw_SalesByProduct AS
SELECT so.CompanyID, p.ProductID, p.Name AS ProductName, pv.VariantID, pv.SKU,
       SUM(soi.Quantity) AS UnitsSold,
       SUM(soi.LineTotal) AS Revenue
FROM sales.SalesOrderItem soi
INNER JOIN sales.SalesOrder so ON so.OrderID = soi.OrderID
INNER JOIN catalog.ProductVariant pv ON pv.VariantID = soi.VariantID
INNER JOIN catalog.Product p ON p.ProductID = pv.ProductID
WHERE so.Status NOT IN ('DRAFT', 'CANCELLED')
GROUP BY so.CompanyID, p.ProductID, p.Name, pv.VariantID, pv.SKU;
GO

IF OBJECT_ID(N'sales.vw_SalesByCustomer', N'V') IS NOT NULL DROP VIEW sales.vw_SalesByCustomer;
GO
CREATE VIEW sales.vw_SalesByCustomer AS
SELECT so.CompanyID, so.CustomerID,
       cu.FirstName, cu.LastName,
       COUNT(DISTINCT so.OrderID) AS OrderCount,
       SUM(so.TotalAmount) AS TotalSpent,
       MAX(so.OrderDate) AS LastOrderDate
FROM sales.SalesOrder so
INNER JOIN sales.Customer cu ON cu.CustomerID = so.CustomerID
WHERE so.Status NOT IN ('DRAFT', 'CANCELLED')
GROUP BY so.CompanyID, so.CustomerID, cu.FirstName, cu.LastName;
GO

-- Inventory: current / available / low-stock
IF OBJECT_ID(N'inventory.vw_CurrentStock', N'V') IS NOT NULL DROP VIEW inventory.vw_CurrentStock;
GO
CREATE VIEW inventory.vw_CurrentStock AS
SELECT inv.InventoryID, inv.CompanyID, sb.ZoneID, wz.WarehouseID, inv.BinID, inv.VariantID,
       pv.SKU, inv.OnHandQuantity, inv.ReservedQuantity, inv.DamagedQuantity,
       (inv.OnHandQuantity - inv.ReservedQuantity - inv.DamagedQuantity) AS AvailableQuantity
FROM inventory.Inventory inv
INNER JOIN warehouse.StorageBin sb ON sb.BinID = inv.BinID
INNER JOIN warehouse.WarehouseZone wz ON wz.ZoneID = sb.ZoneID
INNER JOIN catalog.ProductVariant pv ON pv.VariantID = inv.VariantID;
GO

IF OBJECT_ID(N'inventory.vw_LowStock', N'V') IS NOT NULL DROP VIEW inventory.vw_LowStock;
GO
CREATE VIEW inventory.vw_LowStock AS
SELECT s.CompanyID, s.VariantID, s.SKU,
       SUM(s.AvailableQuantity) AS AvailableQuantity,
       cp.ReorderLevel, cp.ReorderQuantity
FROM inventory.vw_CurrentStock s
INNER JOIN catalog.CompanyProduct cp ON cp.CompanyID = s.CompanyID AND cp.VariantID = s.VariantID
GROUP BY s.CompanyID, s.VariantID, s.SKU, cp.ReorderLevel, cp.ReorderQuantity
HAVING SUM(s.AvailableQuantity) < cp.ReorderLevel;
GO

-- Procurement: outstanding / overdue Purchase Orders
IF OBJECT_ID(N'procurement.vw_OutstandingPurchaseOrders', N'V') IS NOT NULL DROP VIEW procurement.vw_OutstandingPurchaseOrders;
GO
CREATE VIEW procurement.vw_OutstandingPurchaseOrders AS
SELECT po.PurchaseOrderID, po.CompanyID, po.SupplierID, po.Status,
       po.OrderDate, po.ExpectedDate, po.TotalAmount,
       CASE WHEN po.ExpectedDate IS NOT NULL
                 AND po.ExpectedDate < CONVERT(date, SYSUTCDATETIME())
                 AND po.Status NOT IN ('FULLY_RECEIVED', 'CANCELLED', 'REJECTED')
            THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS IsOverdue
FROM procurement.PurchaseOrder po
WHERE po.Status NOT IN ('FULLY_RECEIVED', 'CANCELLED', 'REJECTED');
GO

-- Logistics: shipment performance by Carrier
IF OBJECT_ID(N'logistics.vw_ShipmentPerformance', N'V') IS NOT NULL DROP VIEW logistics.vw_ShipmentPerformance;
GO
CREATE VIEW logistics.vw_ShipmentPerformance AS
SELECT sh.CarrierID, c.Name AS CarrierName,
       COUNT(*) AS ShipmentCount,
       SUM(CASE WHEN sh.DeliveredAt IS NOT NULL
                     AND sh.ExpectedDeliveryDate IS NOT NULL
                     AND CONVERT(date, sh.DeliveredAt) <= sh.ExpectedDeliveryDate
                THEN 1 ELSE 0 END) AS OnTimeCount,
       SUM(CASE WHEN sh.DeliveredAt IS NOT NULL
                     AND sh.ExpectedDeliveryDate IS NOT NULL
                     AND CONVERT(date, sh.DeliveredAt) > sh.ExpectedDeliveryDate
                THEN 1 ELSE 0 END) AS DelayedCount,
       AVG(CASE WHEN sh.DeliveredAt IS NOT NULL AND sh.ShippedAt IS NOT NULL
                THEN DATEDIFF(HOUR, sh.ShippedAt, sh.DeliveredAt) END) AS AvgDeliveryHours
FROM logistics.Shipment sh
INNER JOIN logistics.Carrier c ON c.CarrierID = sh.CarrierID
GROUP BY sh.CarrierID, c.Name;
GO

-- Returns: rate, reasons, disposition outcomes
IF OBJECT_ID(N'returns.vw_ReturnsSummary', N'V') IS NOT NULL DROP VIEW returns.vw_ReturnsSummary;
GO
CREATE VIEW returns.vw_ReturnsSummary AS
SELECT so.CompanyID,
       COUNT(DISTINCT rr.ReturnRequestID) AS ReturnRequestCount,
       COUNT(DISTINCT so.OrderID) AS OrdersWithReturns,
       SUM(rri.ApprovedQuantity) AS TotalApprovedReturnQty
FROM returns.ReturnRequest rr
INNER JOIN returns.ReturnRequestItem rri ON rri.ReturnRequestID = rr.ReturnRequestID
INNER JOIN sales.SalesOrder so ON so.OrderID = rr.OrderID
GROUP BY so.CompanyID;
GO

IF OBJECT_ID(N'returns.vw_DispositionOutcomes', N'V') IS NOT NULL DROP VIEW returns.vw_DispositionOutcomes;
GO
CREATE VIEW returns.vw_DispositionOutcomes AS
SELECT so.CompanyID, rd.DispositionType, SUM(rd.Quantity) AS TotalQuantity
FROM returns.ReturnDisposition rd
INNER JOIN returns.ReturnInspectionItem rii ON rii.InspectionItemID = rd.InspectionItemID
INNER JOIN returns.ReturnInspection ri ON ri.InspectionID = rii.InspectionID
INNER JOIN returns.ReturnReceipt rrc ON rrc.ReturnReceiptID = ri.ReturnReceiptID
INNER JOIN returns.ReturnRequest rr ON rr.ReturnRequestID = rrc.ReturnRequestID
INNER JOIN sales.SalesOrder so ON so.OrderID = rr.OrderID
GROUP BY so.CompanyID, rd.DispositionType;
GO

-- Finance: payments and refunds
IF OBJECT_ID(N'sales.vw_FinanceSummary', N'V') IS NOT NULL DROP VIEW sales.vw_FinanceSummary;
GO
CREATE VIEW sales.vw_FinanceSummary AS
SELECT so.CompanyID,
       SUM(CASE WHEN p.Status = 'SUCCESS' THEN p.Amount ELSE 0 END) AS SuccessfulPayments,
       SUM(CASE WHEN p.Status = 'FAILED' THEN 1 ELSE 0 END) AS FailedPaymentAttempts,
       SUM(CASE WHEN rf.Status = 'SUCCESS' THEN rf.Amount ELSE 0 END) AS TotalRefunds
FROM sales.SalesOrder so
LEFT JOIN sales.Payment p ON p.OrderID = so.OrderID
LEFT JOIN returns.ReturnRequest rr ON rr.OrderID = so.OrderID
LEFT JOIN returns.Refund rf ON rf.ReturnRequestID = rr.ReturnRequestID
GROUP BY so.CompanyID;
GO

/* ============================================================================
   22. IMPORTANT PRODUCTION NOTES
   ============================================================================

   Section 20.2 triggers now enforce, at the database layer, the cross-row
   rules that CHECK constraints cannot express on their own:
   - Received quantity must not exceed ordered quantity across receipts.
   - Inventory reservation concurrency / overselling prevention.
   - Fulfillment and shipment quantities must not exceed order quantities.
   - Return quantities must not exceed purchased quantities.
   - Refunds must not exceed successful payment balance.
   Transfer quantities are still enforced by row-level CHECK constraints on
   InventoryTransferItem (Shipped <= Requested, Received <= Shipped).
   Company/Warehouse/Bin ownership consistency (BR-WH-005) is intentionally
   left to a stored procedure layer, since it requires validating against
   organization.CompanyWarehouse, which is outside a simple trigger''s scope.

   DataChangeLog is intentionally polymorphic:
       TableName + RecordID
   rather than an FK to every business table. Section 20.3 covers
   PurchaseOrder / SalesOrder / Payment / Refund as a representative
   implementation; extend the same trigger pattern to any further table the
   assignment requires auditing on.

   ErrorLog is a technical sink for TRY/CATCH and operational processes.

   TaxRate is scoped to Enterprise through EnterpriseID.
    
   CustomerAddress is included because Customer -> CustomerAddress is a real
   1:N business entity in the EERD, even though it was omitted from the earlier
   55-entity shorthand list.

   DO NOT add ON DELETE CASCADE globally. Deletion policy should be handled
   explicitly per business lifecycle to preserve audit/history.
============================================================================ */
PRINT N'EnterpriseSupplyChain schema deployment completed.';
GO
/*
select * from EnterpriseSupplyChain.warehouse.Warehouse;
select * from EnterpriseSupplyChain.warehouse.WarehouseZone;
select * from EnterpriseSupplyChain.warehouse.StorageBin;
*/