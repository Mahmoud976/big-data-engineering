# 🌐 Enterprise Smart Supply Chain & Logistics Management System

<div align="center">
  <img src="https://shields.io" alt="SQL Server" />
  <img src="https://shields.io" alt="Architecture" />
  <img src="https://shields.io" alt="Isolation" />
  <img src="https://shields.io" alt="License" />
</div>

---

## 🤵 Lead Database Engineer
**Eng. Mahmoud Mohammed Saleh**  
*Big Data Engineer Trainee at National Telecommunication Institute (NTI)*

---

## 📖 Project Overview
This project represents a full-scale, **Production-Oriented multi-company ERP database cluster** engineered to manage end-to-end supply chain operations, automated procurement, inventory synchronization across shared warehouses, secure multi-tenant isolation, and resilient reverse logistics loops.

The engine doesn't just store data; it strictly enforces operational business boundaries via specialized database triggers, isolating computational data layers into **11 domain-specific schemas**.

---

## 🗺️ System Blueprint & Data Flow
Here is how the system handles the unified transit from production ordering down to customer reverse logistics:

```text
  [ SUPPLIER ] <───────────── (Associative Contract Mapping) ─────────────> [ COMPANY ]
       │                                                                       │
       ▼                                                                       ▼
  PURCHASE ORDER ───► GOODS RECEIPT ───► [ INVENTORY ] ◄─── RESERVATION ◄─── SALES ORDER
                                              │                                │
                                              ▼                                ▼
                                       WAREHOUSE ZONE ──► FULFILLMENT ──► PAYMENTS (CARD/CASH)
                                              │                                │
                                              ▼                                ▼
                                         STORAGE BIN ───► CARRIER SHIPMENT ──► DELIVERY
                                                                               │
   ┌───────────────────────────────────────────────────────────────────────────┘
   ▼
CUSTOMER RETURN REQUEST ──► PHYSICAL INSPECTION ──► DISPOSITION ──► INVENTORY RESTOCK / SCRAP
   │
   └──────────────────────────────────────────────────────────────► FINANCIAL REFUND BALANCE
```

---

## 🏗️ Database Schema & Table Hierarchy (The 11 Pillars)
The relational engine partitions the enterprise boundary into **11 logical sub-domains/schemas**, mappings objects and multi-to-multi associative states precisely:

```text
dbo
│
├── Currency
├── TaxRate
└── Address

organization
│
├── Enterprise
├── Company
├── Branch
├── Department
├── Employee
├── Role
├── EmployeeDepartment
└── EmployeeRole

catalog
│
├── Brand
├── Product
├── ProductVariant
├── Category
├── ProductCategory
└── CompanyProduct

warehouse
│
├── Warehouse
├── CompanyWarehouse
├── WarehouseZone
└── StorageBin

procurement
│
├── Supplier
├── CompanySupplier
├── SupplierProduct
├── PurchaseOrder
├── PurchaseOrderItem
├── PurchaseOrderStatusHistory
├── GoodsReceipt
└── GoodsReceiptItem

inventory
│
├── Inventory
├── InventoryTransaction
├── InventoryReservation
├── InventoryTransfer
└── InventoryTransferItem

sales
│
├── Customer
├── CompanyCustomer
├── CustomerAddress
├── OrderAddress
├── SalesOrder
├── SalesOrderItem
├── OrderStatusHistory
└── Payment

logistics
│
├── Carrier
├── Fulfillment
├── FulfillmentItem
├── Shipment
├── ShipmentItem
└── ShipmentTrackingEvent

returns
│
├── ReturnRequest
├── ReturnRequestItem
├── ReturnStatusHistory
├── ReturnReceipt
├── ReturnInspection
├── ReturnInspectionItem
├── ReturnDisposition
└── Refund

notifications
│
├── NotificationType
├── Notification
├── NotificationRecipient
├── AlertRule
└── AlertInstance

audit
│
├── DataChangeLog (Semi-structured analytical payload stored in JSON)
├── SecurityEventLog
└── ErrorLog
```

---

## 🛠️ The Defensive Engineering Layer (Triggers Enforced)
To ensure the application tier cannot violate transactional data sanity, the schema locks business constraints at the database compiler level:

| Trigger Name | Bounded Context | Business Rule Enforced |
| :--- | :--- | :--- |
| `procurement.trg_GoodsReceiptItem_QtyCheck` | Procurement | Rejects transactions if received units exceed initial Purchase Orders. |
| `inventory.trg_InventoryReservation_Sync` | Inventory | Self-correcting stock commitment loop. Prevents concurrent overselling. |
| `logistics.trg_FulfillmentItem_QtyCheck` | Logistics | Hard block against executing fulfillment logs for missing or over-allocated entries. |
| `logistics.trg_ShipmentItem_QtyCheck` | Logistics | Enforces that shipped payload totals perfectly match verified packed lines. |
| `returns.trg_ReturnRequestItem_QtyCheck` | Returns | Standard validation preventing infinite fraud loops where customers return more than they paid for. |
| `returns.trg_Refund_AmountCheck` | Returns | Absolute rollback if a refund payload exceeds successful initial clearings. |

---

## 🚀 Installation & System Deployment

```bash
# Clone the repository
git clone https://github.com
cd Smart-Supply-Chain-System

# Run Schema compilation on your target database server engine
# Execute 01_Initial_Schema.sql
```

For a comprehensive analysis of the database testing architecture and stress test scripts, please check the dedicated [Testing Framework Guide](TESTING_GUIDE.md).

---
<div align="center">
  <p>Engineered with absolute atomic integrity by <b>Eng. Mahmoud Mohammed Saleh</b></p>
</div>
# 🧪 Complex Integration & Stress Testing Suite Guide

This testing engine (`02_Master_Data_and_Tests.sql`) is designed to validate the database kernel against real-world data telemetry. It isolates operational states in an active local reference memory context (`#Ids`), simulating live business logic and stress testing edge cases.

---

## 1️⃣ Phase 1: The Happy Path Lifecycle (E2E Integration)

This phase replicates a perfect, multi-tenant corporate operation across all 11 schemas, ensuring relational fields update atomically:

*   **Step 1: Multi-Tenant Authorization & Bounded Contracts**  
    The engine explicitly registers an Enterprise (`NovaCoffee`), establishes an isolated Egyptian subsidiary (`NovaCoffee EG`), and provisions a secure shared resource authorization linking `NovaCoffee EG` to `Cairo Central Warehouse`. Contracts are then bound to map vendor costs versus consumer pricing rules.
*   **Step 2: Atomicity in Procurement (`procurement` ──► `inventory`)**  
    The script generates a verified Purchase Order for **100 units** of a manual coffee grinder variant. Once flagged as `APPROVED`, a formal `GoodsReceipt` payload is processed. The database validates the input and automatically pushes the **100 units** straight into `inventory.Inventory` inside **Storage Bin A-01-01**, logging an immutable `RECEIPT` audit ledger event.
*   **Step 3: Concurrency Control via logical commitments (`sales` ──► `inventory`)**  
    Customer `Omar Khaled` triggers a checkout for **3 units**. Instantly, the database locks the targeted data row, shifts **3 units** from `OnHandQuantity` directly into `ReservedQuantity`, and provisions an active `InventoryReservation` key. This mechanism prevents race conditions, ensuring another customer cannot capture these same physical units mid-transit.
*   **Step 4: Fulfillment, Carrier Dispatches & Invoicing**  
    The engine converts the order state to `PAID`, dispatches a split-allocation token to logistics, flags the packed items for `Bosta Carrier`, registers standard tracking sequence milestones (`CREATED` ──► `IN_TRANSIT`), logs a successful payment ledger entry, and updates a polymorphic JSON change log.
*   **Step 5: Bounded Reverse Logistics Loop (`returns` ──► `refunds`)**  
    The customer returns **1 unit**. The system provisions a `ReturnRequest`, receives it at the authorized warehouse, runs an inspection grading outcome (`SCRAP`), updates inventory movement history, and triggers a financial balance refund of **\$45.00** mapped straight to the original payment key sequence.

---

## 2️⃣ Phase 2: Destructive Security & Logic Injections (Edge Cases)

This is the defensive engineering core where the database actively targets, catches, and kills fraudulent or malicious application data inputs using transactional rollbacks:

```text
       MALICIOUS APPLICATION INJECTION                    ROBUST DATABASE KERNEL
┌──────────────────────────────────────────┐       ┌──────────────────────────────────┐
│  [Test 2B] Over-Receive Payload (+20)   │ ─────► │ trg_GoodsReceiptItem_QtyCheck    │ ──► [ROLLBACK]
├──────────────────────────────────────────┤       ├──────────────────────────────────┤
│  [Test 3A] Over-Fulfill Allocation (+10) │ ─────► │ trg_FulfillmentItem_QtyCheck     │ ──► [ROLLBACK]
├──────────────────────────────────────────┤       ├──────────────────────────────────┤
│  [Test 3B] Over-Ship Payload (+5)        │ ─────► │ trg_ShipmentItem_QtyCheck        │ ──► [ROLLBACK]
├──────────────────────────────────────────┤       ├──────────────────────────────────┤
│  [Test 3C] Oversell Phantom Stock (+200) │ ─────► │ CK_Inventory_Reserved Check      │ ──► [ROLLBACK]
├──────────────────────────────────────────┤       ├──────────────────────────────────┤
│  [Test 4B] Cumulative Return Fraud (+3)  │ ─────► │ trg_ReturnRequestItem_QtyCheck   │ ──► [ROLLBACK]
├──────────────────────────────────────────┤       ├──────────────────────────────────┤
│  [Test 4C] Financial Over-Refund (+$500) │ ─────► │ trg_Refund_AmountCheck           │ ──► [ROLLBACK]
└──────────────────────────────────────────┘       └──────────────────────────────────┘
```

#### 🚫 Injection Scenario 2B: Supply Chain Over-Receiving Fraud
*   **The Attack:** A compromised vendor application attempts to register a secondary `GoodsReceiptItem` containing **20 extra units** on an already completed order line of 100 units.
*   **The Defense Layer:** `procurement.trg_GoodsReceiptItem_QtyCheck` evaluates the cumulative sum across all current transaction rows. Because 100 + 20 > 100, it intercepts the compilation, aborts execution via `RAISERROR`, and triggers a total batch `ROLLBACK`.

#### 🚫 Injection Scenario 3A & 3B: Warehouse Allocation Splitting Breaches
*   **The Attack:** A warehouse management system error tries to pack and fulfill **10 units** [2] or dispatch a tracking shipment of **5 units** [2] for an order line that only bought **3 items**.
*   **The Defense Layer:** `logistics.trg_FulfillmentItem_QtyCheck` and `logistics.trg_ShipmentItem_QtyCheck` calculate the original order parameters. They intercept the operation before state persistence can occur, safely guarding inventory counts from entering inaccurate negative figures.

#### 🚫 Injection Scenario 3C: High-Concurrency Race Conditions (Phantom Stock)
*   **The Attack:** An application attempts to reserve **200 units** from Storage Bin A-01-01 when the warehouse only holds a maximum balance of 100 units.
*   **The Defense Layer:** The database triggers a hardware column update syncing active keys. The check constraint `CK_Inventory_Reserved` evaluates the row state (200 > 100). The transactional engine blocks the statement instantly, safely managing concurrent transactions under strict data isolation.

#### 🚫 Injection Scenario 4B & 4C: Financial Refund & Reverse Logistics Exploits
*   **The Attack:** A malicious client attempts a cumulative return loop requesting to return **3 more items** after already returning 1, or processes an over-refund execution token of **\$500.00** against a micro-invoice that only paid **\$135.00**.
*   **The Defense Layer:** Financial logic evaluates the database history. `returns.trg_ReturnRequestItem_QtyCheck` verifies that cumulative returns cannot surpass the purchased count. Simultaneously, `returns.trg_Refund_AmountCheck` tracks historical successes, immediately aborting the transaction if the application tier attempts to refund more capital than the payment gateway originally captured.

---

## 🔬 Analyzing Test Engine Telemetry Output

After running `02_Master_Data_and_Tests.sql` in SQL Server Management Studio (SSMS), review the raw messages pane. You should strictly confirm the system intercepts:

```text
(12 row(s) affected) -> Temp reference memory mapping success.
(1 row(s) affected) -> Procurement automated receipt ingestion clear.

EXPECTED FAILURE (2B): Total received quantity exceeds ordered quantity for a Purchase Order Item.
EXPECTED FAILURE (3A): Total fulfilled quantity exceeds ordered quantity for a Sales Order Item.
EXPECTED FAILURE (3B): Total shipped quantity exceeds fulfilled quantity for a Fulfillment Item.
EXPECTED FAILURE (3C): The INSERT statement conflicted with the CHECK constraint "CK_Inventory_Reserved".
EXPECTED FAILURE (4B): Cumulative approved return quantity exceeds the purchased quantity for a Sales Order Item.
EXPECTED FAILURE (4C): Total successful refunds exceed the successfully paid amount for this Payment.

TEST SCENARIO COMPLETE SUCCESS.
```
