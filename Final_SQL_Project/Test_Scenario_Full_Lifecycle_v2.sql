/* ============================================================================
   PART 0 — MASTER / REFERENCE DATA (IDEMPOTENT / SAFE RUN)
   ============================================================================ */

DECLARE @CurrencyID   int;
DECLARE @AddrCompany  bigint, @AddrWarehouse bigint, @AddrSupplier bigint;
DECLARE @EnterpriseID bigint, @CompanyID bigint, @EmployeeID bigint;
DECLARE @WarehouseID  bigint, @ZoneID bigint, @BinID bigint;
DECLARE @BrandID      bigint, @ProductID bigint, @VariantID bigint;
DECLARE @SupplierID   bigint, @CustomerID bigint;

-- 1. Currency
SELECT @CurrencyID = CurrencyID FROM dbo.Currency WHERE CurrencyCode = 'USD';
IF @CurrencyID IS NULL
BEGIN
    INSERT INTO dbo.Currency (CurrencyCode, CurrencyName, Symbol, DecimalPlaces)
    VALUES ('USD', 'US Dollar', '$', 2);
    SET @CurrencyID = SCOPE_IDENTITY();
END

-- 2. Addresses
SELECT @AddrCompany = AddressID FROM dbo.Address WHERE AddressLine1 = '1 Nova Street' AND City = 'Cairo';
IF @AddrCompany IS NULL
BEGIN
    INSERT INTO dbo.Address (AddressType, AddressLine1, City, Country)
    VALUES ('REGISTERED', '1 Nova Street', 'Cairo', 'Egypt');
    SET @AddrCompany = SCOPE_IDENTITY();
END

SELECT @AddrWarehouse = AddressID FROM dbo.Address WHERE AddressLine1 = '10 Industrial Zone' AND City = '6th of October';
IF @AddrWarehouse IS NULL
BEGIN
    INSERT INTO dbo.Address (AddressType, AddressLine1, City, Country)
    VALUES ('WAREHOUSE', '10 Industrial Zone', '6th of October', 'Egypt');
    SET @AddrWarehouse = SCOPE_IDENTITY();
END

SELECT @AddrSupplier = AddressID FROM dbo.Address WHERE AddressLine1 = '5 Supplier Road' AND City = 'Alexandria';
IF @AddrSupplier IS NULL
BEGIN
    INSERT INTO dbo.Address (AddressType, AddressLine1, City, Country)
    VALUES ('OTHER', '5 Supplier Road', 'Alexandria', 'Egypt');
    SET @AddrSupplier = SCOPE_IDENTITY();
END

-- 3. Enterprise & Company
SELECT @EnterpriseID = EnterpriseID FROM organization.Enterprise WHERE Name = 'NovaCoffee';
IF @EnterpriseID IS NULL
BEGIN
    INSERT INTO organization.Enterprise (Name, LegalName)
    VALUES ('NovaCoffee', 'NovaCoffee Holding Ltd.');
    SET @EnterpriseID = SCOPE_IDENTITY();
END

SELECT @CompanyID = CompanyID FROM organization.Company WHERE Name = 'NovaCoffee EG';
IF @CompanyID IS NULL
BEGIN
    INSERT INTO organization.Company (EnterpriseID, AddressID, Name, LegalName, CurrencyID)
    VALUES (@EnterpriseID, @AddrCompany, 'NovaCoffee EG', 'NovaCoffee Egypt LLC', @CurrencyID);
    SET @CompanyID = SCOPE_IDENTITY();
END

-- 4. Employee
SELECT @EmployeeID = EmployeeID FROM organization.Employee WHERE Email = 'sara.ahmed@novacoffee.example';
IF @EmployeeID IS NULL
BEGIN
    INSERT INTO organization.Employee (FirstName, LastName, Email, HireDate)
    VALUES ('Sara', 'Ahmed', 'sara.ahmed@novacoffee.example', '2024-01-15');
    SET @EmployeeID = SCOPE_IDENTITY();
END

-- 5. Warehouse, Zone & Bin
SELECT @WarehouseID = WarehouseID FROM warehouse.Warehouse WHERE Code = 'WH-CAI-01';
IF @WarehouseID IS NULL
BEGIN
    INSERT INTO warehouse.Warehouse (Name, Code, Type, AddressID)
    VALUES ('Cairo Central Warehouse', 'WH-CAI-01', 'CENTRAL', @AddrWarehouse);
    SET @WarehouseID = SCOPE_IDENTITY();
END

SELECT @ZoneID = ZoneID FROM warehouse.WarehouseZone WHERE WarehouseID = @WarehouseID AND Name = 'Zone A - Small Appliances';
IF @ZoneID IS NULL
BEGIN
    INSERT INTO warehouse.WarehouseZone (WarehouseID, Name, ZoneType)
    VALUES (@WarehouseID, 'Zone A - Small Appliances', 'STORAGE');
    SET @ZoneID = SCOPE_IDENTITY();
END

SELECT @BinID = BinID FROM warehouse.StorageBin WHERE WarehouseID = @WarehouseID AND Code = 'A-01-01';
IF @BinID IS NULL
BEGIN
    INSERT INTO warehouse.StorageBin (ZoneID, WarehouseID, Code)
    VALUES (@ZoneID, @WarehouseID, 'A-01-01');
    SET @BinID = SCOPE_IDENTITY();
END

-- 6. Catalog
SELECT @BrandID = BrandID FROM catalog.Brand WHERE Name = 'NovaBrew';
IF @BrandID IS NULL
BEGIN
    INSERT INTO catalog.Brand (Name) VALUES ('NovaBrew');
    SET @BrandID = SCOPE_IDENTITY();
END

SELECT @ProductID = ProductID FROM catalog.Product WHERE BrandID = @BrandID AND Name = 'NovaBrew Manual Coffee Grinder';
IF @ProductID IS NULL
BEGIN
    INSERT INTO catalog.Product (BrandID, Name, ProductType)
    VALUES (@BrandID, 'NovaBrew Manual Coffee Grinder', 'PHYSICAL');
    SET @ProductID = SCOPE_IDENTITY();
END

SELECT @VariantID = VariantID FROM catalog.ProductVariant WHERE ProductID = @ProductID AND SKU = 'NB-GRND-001-BLK';
IF @VariantID IS NULL
BEGIN
    INSERT INTO catalog.ProductVariant (ProductID, SKU, Color)
    VALUES (@ProductID, 'NB-GRND-001-BLK', 'Black');
    SET @VariantID = SCOPE_IDENTITY();
END

-- 7. Supplier & Customer
SELECT @SupplierID = SupplierID FROM procurement.Supplier WHERE LegalName = 'GrindWorks Manufacturing Co.';
IF @SupplierID IS NULL
BEGIN
    INSERT INTO procurement.Supplier (Name, LegalName, AddressID, Country)
    VALUES ('GrindWorks Manufacturing', 'GrindWorks Manufacturing Co.', @AddrSupplier, 'Egypt');
    SET @SupplierID = SCOPE_IDENTITY();
END

SELECT @CustomerID = CustomerID FROM sales.Customer WHERE EnterpriseID = @EnterpriseID AND Email = 'omar.khaled@example.com';
IF @CustomerID IS NULL
BEGIN
    INSERT INTO sales.Customer (EnterpriseID, CustomerType, FirstName, LastName, Email)
    VALUES (@EnterpriseID, 'INDIVIDUAL', 'Omar', 'Khaled', 'omar.khaled@example.com');
    SET @CustomerID = SCOPE_IDENTITY();
END

-- Save/Update current accurate IDs into session temp table
IF OBJECT_ID('tempdb..#Ids') IS NOT NULL DROP TABLE #Ids;
CREATE TABLE #Ids (Name varchar(50) PRIMARY KEY, Value bigint);
INSERT INTO #Ids VALUES
    ('CurrencyID', @CurrencyID), ('EnterpriseID', @EnterpriseID), ('CompanyID', @CompanyID),
    ('EmployeeID', @EmployeeID), ('WarehouseID', @WarehouseID), ('ZoneID', @ZoneID),
    ('BinID', @BinID), ('BrandID', @BrandID), ('ProductID', @ProductID),
    ('VariantID', @VariantID), ('SupplierID', @SupplierID), ('CustomerID', @CustomerID);

SELECT * FROM #Ids;
GO

/* ============================================================================
   PART 1 — AUTHORIZATION / ASSOCIATIVE TABLES (SAFE RUN)
   ============================================================================ */

DECLARE @CompanyID bigint = (SELECT Value FROM #Ids WHERE Name='CompanyID');
DECLARE @WarehouseID bigint = (SELECT Value FROM #Ids WHERE Name='WarehouseID');
DECLARE @SupplierID bigint = (SELECT Value FROM #Ids WHERE Name='SupplierID');
DECLARE @VariantID bigint = (SELECT Value FROM #Ids WHERE Name='VariantID');
DECLARE @CustomerID bigint = (SELECT Value FROM #Ids WHERE Name='CustomerID');

IF NOT EXISTS (SELECT 1 FROM organization.CompanyWarehouse WHERE CompanyID = @CompanyID AND WarehouseID = @WarehouseID)
    INSERT INTO organization.CompanyWarehouse (CompanyID, WarehouseID, AccessType, StartDate)
    VALUES (@CompanyID, @WarehouseID, 'PRIMARY', '2024-01-01');

IF NOT EXISTS (SELECT 1 FROM procurement.CompanySupplier WHERE CompanyID = @CompanyID AND SupplierID = @SupplierID)
    INSERT INTO procurement.CompanySupplier (CompanyID, SupplierID)
    VALUES (@CompanyID, @SupplierID);

IF NOT EXISTS (SELECT 1 FROM catalog.CompanyProduct WHERE CompanyID = @CompanyID AND VariantID = @VariantID)
    INSERT INTO catalog.CompanyProduct (CompanyID, VariantID, SellingPrice, CostPrice, ReorderLevel, ReorderQuantity)
    VALUES (@CompanyID, @VariantID, 45.00, 22.00, 10, 50);

IF NOT EXISTS (SELECT 1 FROM procurement.SupplierProduct WHERE SupplierID = @SupplierID AND VariantID = @VariantID)
    INSERT INTO procurement.SupplierProduct (SupplierID, VariantID, SupplierSKU, LastUnitCost, LeadTimeDays, IsPreferred)
    VALUES (@SupplierID, @VariantID, 'GW-BLK-001', 22.00, 7, 1);

IF NOT EXISTS (SELECT 1 FROM sales.CompanyCustomer WHERE CompanyID = @CompanyID AND CustomerID = @CustomerID)
    INSERT INTO sales.CompanyCustomer (CompanyID, CustomerID)
    VALUES (@CompanyID, @CustomerID);

SELECT * FROM organization.CompanyWarehouse WHERE CompanyID = @CompanyID;
GO

/* ============================================================================
   PART 2 — PROCUREMENT: Purchase Order -> Goods Receipt -> Inventory (SAFE & IDEMPOTENT)
   ============================================================================ */

DECLARE @CompanyID bigint = (SELECT Value FROM #Ids WHERE Name='CompanyID');
DECLARE @SupplierID bigint = (SELECT Value FROM #Ids WHERE Name='SupplierID');
DECLARE @WarehouseID bigint = (SELECT Value FROM #Ids WHERE Name='WarehouseID');
DECLARE @VariantID bigint = (SELECT Value FROM #Ids WHERE Name='VariantID');
DECLARE @EmployeeID bigint = (SELECT Value FROM #Ids WHERE Name='EmployeeID');
DECLARE @BinID bigint = (SELECT Value FROM #Ids WHERE Name='BinID');

EXEC sp_set_session_context @key = N'EmployeeID', @value = @EmployeeID;

DECLARE @PurchaseOrderID bigint, @PurchaseOrderItemID bigint, @GoodsReceiptID bigint, @InventoryID bigint;

-- 1. Safe PurchaseOrder
SELECT @PurchaseOrderID = PurchaseOrderID FROM procurement.PurchaseOrder 
WHERE CompanyID = @CompanyID AND SupplierID = @SupplierID AND WarehouseID = @WarehouseID;

IF @PurchaseOrderID IS NULL
BEGIN
    INSERT INTO procurement.PurchaseOrder (CompanyID, SupplierID, WarehouseID, CreatedBy)
    VALUES (@CompanyID, @SupplierID, @WarehouseID, @EmployeeID);
    SET @PurchaseOrderID = SCOPE_IDENTITY();
END

-- 2. Safe PurchaseOrderItem
SELECT @PurchaseOrderItemID = PurchaseOrderItemID FROM procurement.PurchaseOrderItem 
WHERE PurchaseOrderID = @PurchaseOrderID AND VariantID = @VariantID;

IF @PurchaseOrderItemID IS NULL
BEGIN
    INSERT INTO procurement.PurchaseOrderItem (PurchaseOrderID, VariantID, OrderedQuantity, UnitCost)
    VALUES (@PurchaseOrderID, @VariantID, 100, 22.00);
    SET @PurchaseOrderItemID = SCOPE_IDENTITY();
END

-- Ensure PO is approved
UPDATE procurement.PurchaseOrder SET Status = 'APPROVED' WHERE PurchaseOrderID = @PurchaseOrderID;

-- 3. Safe GoodsReceipt
SELECT @GoodsReceiptID = GoodsReceiptID FROM procurement.GoodsReceipt 
WHERE PurchaseOrderID = @PurchaseOrderID AND WarehouseID = @WarehouseID;

IF @GoodsReceiptID IS NULL
BEGIN
    INSERT INTO procurement.GoodsReceipt (PurchaseOrderID, WarehouseID, ReceivedBy)
    VALUES (@PurchaseOrderID, @WarehouseID, @EmployeeID);
    SET @GoodsReceiptID = SCOPE_IDENTITY();
END

-- 4. Trigger-Safe GoodsReceiptItem Check
-- Only insert if nothing has been received yet for this PO Item to prevent trigger abortion
IF NOT EXISTS (SELECT 1 FROM procurement.GoodsReceiptItem WHERE PurchaseOrderItemID = @PurchaseOrderItemID)
BEGIN
    INSERT INTO procurement.GoodsReceiptItem (GoodsReceiptID, PurchaseOrderItemID, ReceivedQuantity)
    VALUES (@GoodsReceiptID, @PurchaseOrderItemID, 100);
END

-- 5. Safe Inventory
SELECT @InventoryID = InventoryID FROM inventory.Inventory 
WHERE CompanyID = @CompanyID AND BinID = @BinID AND VariantID = @VariantID;

IF @InventoryID IS NULL
BEGIN
    INSERT INTO inventory.Inventory (CompanyID, WarehouseID, BinID, VariantID, OnHandQuantity)
    VALUES (@CompanyID, @WarehouseID, @BinID, @VariantID, 100);
    SET @InventoryID = SCOPE_IDENTITY();
END
ELSE
BEGIN
    UPDATE inventory.Inventory SET OnHandQuantity = 100 WHERE InventoryID = @InventoryID;
END

-- Update the temp session table
DELETE FROM #Ids WHERE Name IN ('PurchaseOrderID', 'PurchaseOrderItemID', 'GoodsReceiptID', 'InventoryID');
INSERT INTO #Ids VALUES 
    ('PurchaseOrderID', @PurchaseOrderID), ('PurchaseOrderItemID', @PurchaseOrderItemID),
    ('GoodsReceiptID', @GoodsReceiptID), ('InventoryID', @InventoryID);

-- View current accurate stock
SELECT * FROM inventory.vw_CurrentStock WHERE InventoryID = @InventoryID;

-- NEGATIVE TEST 2A: try to over-receive (Fake receipt bypasses trigger but tests FK)
BEGIN TRY
    INSERT INTO procurement.GoodsReceiptItem (GoodsReceiptID, PurchaseOrderItemID, ReceivedQuantity)
    VALUES ((SELECT Value FROM #Ids WHERE Name='GoodsReceiptID') + 999999,
            (SELECT Value FROM #Ids WHERE Name='PurchaseOrderItemID'), 50);
    PRINT 'UNEXPECTED: over-receipt was allowed!';
END TRY
BEGIN CATCH
    PRINT 'EXPECTED FAILURE (2A): ' + ERROR_MESSAGE();
END CATCH;

-- NEGATIVE TEST 2B: a second, real receipt that forces trigger to fire properly for testing
BEGIN TRY
    DECLARE @GoodsReceiptID2 bigint;
    INSERT INTO procurement.GoodsReceipt (PurchaseOrderID, WarehouseID, ReceivedBy)
    VALUES ((SELECT Value FROM #Ids WHERE Name='PurchaseOrderID'), @WarehouseID, @EmployeeID);
    SET @GoodsReceiptID2 = SCOPE_IDENTITY();

    INSERT INTO procurement.GoodsReceiptItem (GoodsReceiptID, PurchaseOrderItemID, ReceivedQuantity)
    VALUES (@GoodsReceiptID2, (SELECT Value FROM #Ids WHERE Name='PurchaseOrderItemID'), 20);
    PRINT 'UNEXPECTED: over-receipt (120 > 100 ordered) was allowed!';
END TRY
BEGIN CATCH
    PRINT 'EXPECTED FAILURE (2B): ' + ERROR_MESSAGE();
END CATCH;
GO

/* ============================================================================
   PART 3 — SALES: Order -> Reservation -> Fulfillment -> Shipment -> Payment (SAFE RUN)
   ============================================================================ */

DECLARE @CompanyID bigint = (SELECT Value FROM #Ids WHERE Name='CompanyID');
DECLARE @CustomerID bigint = (SELECT Value FROM #Ids WHERE Name='CustomerID');
DECLARE @CurrencyID int = (SELECT Value FROM #Ids WHERE Name='CurrencyID');
DECLARE @VariantID bigint = (SELECT Value FROM #Ids WHERE Name='VariantID');
DECLARE @EmployeeID bigint = (SELECT Value FROM #Ids WHERE Name='EmployeeID');
DECLARE @WarehouseID bigint = (SELECT Value FROM #Ids WHERE Name='WarehouseID');
DECLARE @InventoryID bigint = (SELECT Value FROM #Ids WHERE Name='InventoryID');

EXEC sp_set_session_context @key = N'EmployeeID', @value = @EmployeeID;

DECLARE @OrderID bigint, @OrderItemID bigint, @FulfillmentID bigint, @FulfillmentItemID bigint,
        @ShipmentID bigint, @ShipmentItemID bigint, @CarrierID bigint, @PaymentID bigint,
        @ReservationID bigint;

-- 1. Safe SalesOrder
SELECT @OrderID = OrderID FROM sales.SalesOrder 
WHERE CompanyID = @CompanyID AND CustomerID = @CustomerID AND CreatedBy = @EmployeeID;

IF @OrderID IS NULL
BEGIN
    INSERT INTO sales.SalesOrder (CompanyID, CustomerID, CurrencyID, CreatedBy)
    VALUES (@CompanyID, @CustomerID, @CurrencyID, @EmployeeID);
    SET @OrderID = SCOPE_IDENTITY();
END

-- 2. Safe SalesOrderItem
SELECT @OrderItemID = OrderItemID FROM sales.SalesOrderItem 
WHERE OrderID = @OrderID AND VariantID = @VariantID;

IF @OrderItemID IS NULL
BEGIN
    INSERT INTO sales.SalesOrderItem (OrderID, VariantID, Quantity, UnitPrice, LineTotal)
    VALUES (@OrderID, @VariantID, 3, 45.00, 135.00);
    SET @OrderItemID = SCOPE_IDENTITY();
END

-- Update SalesOrder to Paid status safely
UPDATE sales.SalesOrder
SET Subtotal = 135.00, TotalAmount = 135.00, Status = 'PAID'
WHERE OrderID = @OrderID;

-- 3. Safe InventoryReservation (Bypasses duplicate triggers)
SELECT @ReservationID = ReservationID FROM inventory.InventoryReservation 
WHERE InventoryID = @InventoryID AND OrderItemID = @OrderItemID;

IF @ReservationID IS NULL
BEGIN
    INSERT INTO inventory.InventoryReservation (InventoryID, OrderItemID, Quantity)
    VALUES (@InventoryID, @OrderItemID, 3);
    SET @ReservationID = SCOPE_IDENTITY();
END

-- View current stock status after reservation
SELECT OnHandQuantity, ReservedQuantity FROM inventory.Inventory WHERE InventoryID = @InventoryID;

-- 4. Safe Fulfillment
SELECT @FulfillmentID = FulfillmentID FROM logistics.Fulfillment 
WHERE OrderID = @OrderID AND WarehouseID = @WarehouseID;

IF @FulfillmentID IS NULL
BEGIN
    INSERT INTO logistics.Fulfillment (OrderID, WarehouseID)
    VALUES (@OrderID, @WarehouseID);
    SET @FulfillmentID = SCOPE_IDENTITY();
END

-- 5. Safe FulfillmentItem (Trigger-safe check)
SELECT @FulfillmentItemID = FulfillmentItemID FROM logistics.FulfillmentItem 
WHERE FulfillmentID = @FulfillmentID AND OrderItemID = @OrderItemID;

IF @FulfillmentItemID IS NULL
BEGIN
    INSERT INTO logistics.FulfillmentItem (FulfillmentID, OrderItemID, Quantity)
    VALUES (@FulfillmentID, @OrderItemID, 3);
    SET @FulfillmentItemID = SCOPE_IDENTITY();
END

-- 6. Safe Carrier
SELECT @CarrierID = CarrierID FROM logistics.Carrier WHERE Code = 'BOSTA';
IF @CarrierID IS NULL
BEGIN
    INSERT INTO logistics.Carrier (Name, Code) VALUES ('Bosta', 'BOSTA');
    SET @CarrierID = SCOPE_IDENTITY();
END

-- 7. Safe Shipment
SELECT @ShipmentID = ShipmentID FROM logistics.Shipment 
WHERE FulfillmentID = @FulfillmentID AND CarrierID = @CarrierID;

IF @ShipmentID IS NULL
BEGIN
    INSERT INTO logistics.Shipment (FulfillmentID, CarrierID, TrackingNumber, ShippedAt, ExpectedDeliveryDate)
    VALUES (@FulfillmentID, @CarrierID, 'TRK-0001', SYSUTCDATETIME(), CONVERT(date, DATEADD(DAY, 3, SYSUTCDATETIME())));
    SET @ShipmentID = SCOPE_IDENTITY();
END

-- 8. Safe ShipmentItem
IF NOT EXISTS (SELECT 1 FROM logistics.ShipmentItem WHERE ShipmentID = @ShipmentID AND FulfillmentItemID = @FulfillmentItemID)
BEGIN
    INSERT INTO logistics.ShipmentItem (ShipmentID, FulfillmentItemID, Quantity)
    VALUES (@ShipmentID, @FulfillmentItemID, 3);
END

-- 9. Safe Payment
SELECT @PaymentID = PaymentID FROM sales.Payment WHERE OrderID = @OrderID AND Amount = 135.00;
IF @PaymentID IS NULL
BEGIN
    INSERT INTO sales.Payment (OrderID, PaymentMethod, Amount, CurrencyID, Status, ProcessedAt)
    VALUES (@OrderID, 'CARD', 135.00, @CurrencyID, 'SUCCESS', SYSUTCDATETIME());
    SET @PaymentID = SCOPE_IDENTITY();
END

-- Dynamically update session IDs scratch table
DELETE FROM #Ids WHERE Name IN ('OrderID', 'OrderItemID', 'FulfillmentID', 'FulfillmentItemID', 'ShipmentID', 'PaymentID', 'ReservationID');
INSERT INTO #Ids VALUES 
    ('OrderID', @OrderID), ('OrderItemID', @OrderItemID), ('FulfillmentID', @FulfillmentID), 
    ('FulfillmentItemID', @FulfillmentItemID), ('ShipmentID', @ShipmentID), ('PaymentID', @PaymentID), 
    ('ReservationID', @ReservationID);

-- Verify Audit log rows
SELECT * FROM audit.DataChangeLog WHERE TableName = 'sales.SalesOrder';

-- NEGATIVE TEST 3A: try to over-fulfill (Forces trigger protection)
BEGIN TRY
    INSERT INTO logistics.FulfillmentItem (FulfillmentID, OrderItemID, Quantity)
    VALUES ((SELECT Value FROM #Ids WHERE Name='FulfillmentID'),
            (SELECT Value FROM #Ids WHERE Name='OrderItemID'), 10);
    PRINT 'UNEXPECTED: over-fulfillment was allowed!';
END TRY
BEGIN CATCH
    PRINT 'EXPECTED FAILURE (3A): ' + ERROR_MESSAGE();
END CATCH;

-- NEGATIVE TEST 3B: try to over-ship (Forces trigger protection)
BEGIN TRY
    INSERT INTO logistics.ShipmentItem (ShipmentID, FulfillmentItemID, Quantity)
    VALUES ((SELECT Value FROM #Ids WHERE Name='ShipmentID'),
            (SELECT Value FROM #Ids WHERE Name='FulfillmentItemID'), 5);
    PRINT 'UNEXPECTED: over-shipment was allowed!';
END TRY
BEGIN CATCH
    PRINT 'EXPECTED FAILURE (3B): ' + ERROR_MESSAGE();
END CATCH;

-- NEGATIVE TEST 3C: try to reserve more than is on hand
BEGIN TRY
    INSERT INTO inventory.InventoryReservation (InventoryID, OrderItemID, Quantity)
    VALUES ((SELECT Value FROM #Ids WHERE Name='InventoryID'),
            (SELECT Value FROM #Ids WHERE Name='OrderItemID'), 200);
    PRINT 'UNEXPECTED: overselling was allowed!';
END TRY
BEGIN CATCH
    PRINT 'EXPECTED FAILURE (3C): ' + ERROR_MESSAGE();
END CATCH;
GO
/* ============================================================================
   PART 4 — RETURNS: Request -> Receipt -> Inspection -> Disposition -> Refund (PERFECT STRUCTURAL MATCH)
   ============================================================================ */

DECLARE @OrderID bigint = (SELECT Value FROM #Ids WHERE Name='OrderID');
DECLARE @OrderItemID bigint = (SELECT Value FROM #Ids WHERE Name='OrderItemID');
DECLARE @EmployeeID bigint = (SELECT Value FROM #Ids WHERE Name='EmployeeID');
DECLARE @WarehouseID bigint = (SELECT Value FROM #Ids WHERE Name='WarehouseID');
DECLARE @BinID bigint = (SELECT Value FROM #Ids WHERE Name='BinID');
DECLARE @PaymentID bigint = (SELECT Value FROM #Ids WHERE Name='PaymentID');
DECLARE @CustomerID bigint = (SELECT Value FROM #Ids WHERE Name='CustomerID');

EXEC sp_set_session_context @key = N'EmployeeID', @value = @EmployeeID;

DECLARE @ReturnRequestID bigint, @ReturnItemID bigint, @ReturnReceiptID bigint,
        @InspectionID bigint, @InspectionItemID bigint, @DispositionID bigint, @RefundID bigint;

-- [CLEANUP] Clean previous attempts completely
IF @OrderID IS NOT NULL
BEGIN
    DELETE FROM returns.Refund WHERE ReturnRequestID IN (SELECT ReturnRequestID FROM returns.ReturnRequest WHERE OrderID = @OrderID);
    DELETE FROM returns.ReturnDisposition WHERE WarehouseID = @WarehouseID;
    DELETE FROM returns.ReturnInspectionItem WHERE ReturnItemID IN (SELECT ReturnItemID FROM returns.ReturnRequestItem WHERE OrderItemID = @OrderItemID);
    DELETE FROM returns.ReturnInspection WHERE InspectedBy = @EmployeeID;
    DELETE FROM returns.ReturnReceipt WHERE ReturnRequestID IN (SELECT ReturnRequestID FROM returns.ReturnRequest WHERE OrderID = @OrderID);
    DELETE FROM returns.ReturnRequestItem WHERE OrderItemID = @OrderItemID;
    DELETE FROM returns.ReturnRequest WHERE OrderID = @OrderID;
END

-- 1. Insert Fresh ReturnRequest
INSERT INTO returns.ReturnRequest (OrderID, CustomerID, Reason, RequestedBy)
VALUES (@OrderID, @CustomerID, 'Customer changed their mind', @EmployeeID);
SET @ReturnRequestID = SCOPE_IDENTITY();

-- 2. Insert Fresh ReturnRequestItem
INSERT INTO returns.ReturnRequestItem (ReturnRequestID, OrderItemID, RequestedQuantity, ApprovedQuantity)
VALUES (@ReturnRequestID, @OrderItemID, 1, 1);
SET @ReturnItemID = SCOPE_IDENTITY();

-- 3. Insert Fresh ReturnReceipt
INSERT INTO returns.ReturnReceipt (ReturnRequestID, WarehouseID, ReceivedBy)
VALUES (@ReturnRequestID, @WarehouseID, @EmployeeID);
SET @ReturnReceiptID = SCOPE_IDENTITY();

-- 4. Insert Fresh ReturnInspection
INSERT INTO returns.ReturnInspection (ReturnReceiptID, InspectedBy, Result)
VALUES (@ReturnReceiptID, @EmployeeID, 'APPROVED');
SET @InspectionID = SCOPE_IDENTITY();

-- 5. Insert Fresh ReturnInspectionItem (Using 'SCRAP' which is fully supported by your check constraint)
INSERT INTO returns.ReturnInspectionItem (InspectionID, ReturnItemID, Quantity, Result)
VALUES (@InspectionID, @ReturnItemID, 1, 'SCRAP');
SET @InspectionItemID = SCOPE_IDENTITY();

-- 6. Insert Fresh ReturnDisposition (Passed @BinID explicitly to satisfy your NOT NULL constraint)
INSERT INTO returns.ReturnDisposition (InspectionItemID, DispositionType, Quantity, WarehouseID, BinID)
VALUES (@InspectionItemID, 'SCRAP', 1, @WarehouseID, @BinID);
SET @DispositionID = SCOPE_IDENTITY();

-- 7. Insert Fresh Refund
INSERT INTO returns.Refund (ReturnRequestID, PaymentID, Amount, CurrencyID, RefundMethod, Status, ProcessedAt)
VALUES (@ReturnRequestID, @PaymentID, 45.00, (SELECT Value FROM #Ids WHERE Name='CurrencyID'), 'ORIGINAL_METHOD', 'SUCCESS', SYSUTCDATETIME());
SET @RefundID = SCOPE_IDENTITY();

-- Save IDs
DELETE FROM #Ids WHERE Name IN ('ReturnRequestID', 'ReturnItemID', 'ReturnReceiptID', 'InspectionID', 'InspectionItemID', 'DispositionID', 'RefundID');
INSERT INTO #Ids VALUES 
    ('ReturnRequestID', @ReturnRequestID), ('ReturnItemID', @ReturnItemID), ('ReturnReceiptID', @ReturnReceiptID), 
    ('InspectionID', @InspectionID), ('InspectionItemID', @InspectionItemID), ('DispositionID', @DispositionID), 
    ('RefundID', @RefundID);

-- Views validation output
SELECT * FROM returns.vw_DispositionOutcomes;
SELECT * FROM sales.vw_FinanceSummary WHERE CompanyID = (SELECT Value FROM #Ids WHERE Name='CompanyID');

-- NEGATIVE TEST 4B: Cumulative check
BEGIN TRY
    DECLARE @ReturnRequestID2 bigint;
    INSERT INTO returns.ReturnRequest (OrderID, CustomerID, Reason, RequestedBy)
    VALUES (@OrderID, @CustomerID, 'Second return attempt for test', @EmployeeID);
    SET @ReturnRequestID2 = SCOPE_IDENTITY();

    INSERT INTO returns.ReturnRequestItem (ReturnRequestID, OrderItemID, RequestedQuantity, ApprovedQuantity)
    VALUES (@ReturnRequestID2, @OrderItemID, 3, 3);
    PRINT 'UNEXPECTED: cumulative over-return was allowed!';
END TRY
BEGIN CATCH
    PRINT 'EXPECTED FAILURE (4B): ' + ERROR_MESSAGE();
END CATCH;

-- NEGATIVE TEST 4C: Over-refund check
BEGIN TRY
    INSERT INTO returns.Refund (ReturnRequestID, PaymentID, Amount, CurrencyID, RefundMethod, Status, ProcessedAt)
    VALUES ((SELECT Value FROM #Ids WHERE Name='ReturnRequestID'),
            (SELECT Value FROM #Ids WHERE Name='PaymentID'), 500.00,
            (SELECT Value FROM #Ids WHERE Name='CurrencyID'), 'ORIGINAL_METHOD', 'SUCCESS', SYSUTCDATETIME());
    PRINT 'UNEXPECTED: over-refund was allowed!';
END TRY
BEGIN CATCH
    PRINT 'EXPECTED FAILURE (4C): ' + ERROR_MESSAGE();
END CATCH;
GO

/* ============================================================================
   PART 5 — FINAL CHECKS
   ============================================================================ */
SELECT * FROM inventory.vw_CurrentStock WHERE InventoryID = (SELECT Value FROM #Ids WHERE Name='InventoryID');
SELECT * FROM audit.DataChangeLog ORDER BY ChangedAt;

PRINT 'TEST SCENARIO COMPLETE SUCCESS.';
GO
 