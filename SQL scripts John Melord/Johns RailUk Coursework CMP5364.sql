-- TABLE
CREATE TABLE address (
  address_id       NUMBER        NOT NULL,
  line_1_address   VARCHAR2(120) NOT NULL,
  city             VARCHAR2(60)  NOT NULL,
  postcode         VARCHAR2(16)  NOT NULL,
  county           VARCHAR2(60), 
  country          VARCHAR2(60)  NOT NULL,
  CONSTRAINT pk_address PRIMARY KEY (address_id),
  CONSTRAINT uq_address_unique UNIQUE (line_1_address, city, postcode, country)
);

##
-- SEQUENCE (starts at 1)
CREATE SEQUENCE seq_address START WITH 1 INCREMENT BY 1;

-- TRIGGER to auto-fill PK from sequence (only if not provided)
CREATE OR REPLACE TRIGGER trg_address_bi
BEFORE INSERT ON address
FOR EACH ROW
WHEN (NEW.address_id IS NULL)
BEGIN
  :NEW.address_id := seq_address.NEXTVAL;
END;
/

-- Addresses

INSERT INTO address(address_id, line_1_address, city, postcode, county, country)
VALUES (seq_address.NEXTVAL, '5 Green Yard', 'Manchester', 'M4 2HB', 'Greater Manchester', 'UK');
INSERT INTO address(address_id, line_1_address, city, postcode, county, country)
VALUES (seq_address.NEXTVAL, '6th High Street', 'Preston', 'P3 2FB', 'Preston City', 'UK');



-- 1) Table
CREATE TABLE location (
  location_id NUMBER NOT NULL,
  name VARCHAR2(80)  NOT NULL,
  location_building_type VARCHAR2(40),
  address_id_fk NUMBER NOT NULL,
  CONSTRAINT pk_location PRIMARY KEY (location_id),
  CONSTRAINT fk_location_address
    FOREIGN KEY (address_id_fk) REFERENCES address(address_id)
);

-- 2) FK index
CREATE INDEX ix_location_address_fk ON location(address_id_fk);


-- 3) Sequence (starts at 1)
CREATE SEQUENCE seq_location START WITH 1 INCREMENT BY 1;

-- 4) Trigger to auto-populate PK from sequence when NULL
CREATE OR REPLACE TRIGGER trg_location_bi
BEFORE INSERT ON location
FOR EACH ROW
WHEN (NEW.location_id IS NULL)
BEGIN
  :NEW.location_id := seq_location.NEXTVAL;
END;
/


CREATE TABLE staffroles (
  role_id         NUMBER        NOT NULL,
  role_name       VARCHAR2(60)  NOT NULL,
  permission_level NUMBER(2)    NOT NULL,      -- e.g., 1..10
  CONSTRAINT pk_staffroles PRIMARY KEY (role_id),
  CONSTRAINT uq_staffroles_name UNIQUE (role_name),
  CONSTRAINT ck_staffroles_perm CHECK (permission_level BETWEEN 1 AND 99)
);

CREATE SEQUENCE seq_staffroles START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_staffroles_bi
BEFORE INSERT ON staffroles
FOR EACH ROW
WHEN (NEW.role_id IS NULL)
BEGIN
  :NEW.role_id := seq_staffroles.NEXTVAL;
END;
/

INSERT INTO staffroles(role_id, role_name, permission_level)
VALUES (seq_staffroles.NEXTVAL, 'Manager', 10);
INSERT INTO staffroles(role_id, role_name, permission_level)
VALUES (seq_staffroles.NEXTVAL, 'Driver', 3);


CREATE TABLE transportmode (
  mode_id     NUMBER        NOT NULL,
  code        VARCHAR2(20)  NOT NULL,   -- e.g., "ROAD", "RAIL", "SEA", "AIR"
  description VARCHAR2(120),
  CONSTRAINT pk_transportmode PRIMARY KEY (mode_id),
  CONSTRAINT uq_transportmode_code UNIQUE (code)
);

CREATE SEQUENCE seq_transportmode START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_transportmode_bi
BEFORE INSERT ON transportmode
FOR EACH ROW
WHEN (NEW.mode_id IS NULL)
BEGIN
  :NEW.mode_id := seq_transportmode.NEXTVAL;
END;
/

CREATE TABLE servicetype (
  service_type_id NUMBER        NOT NULL,
  name            VARCHAR2(80)  NOT NULL,  -- e.g., "Fuel", "Maintenance", "Repair"
  CONSTRAINT pk_servicetype PRIMARY KEY (service_type_id),
  CONSTRAINT uq_servicetype_name UNIQUE (name)
);

CREATE SEQUENCE seq_servicetype START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_servicetype_bi
BEFORE INSERT ON servicetype
FOR EACH ROW
WHEN (NEW.service_type_id IS NULL)
BEGIN
  :NEW.service_type_id := seq_servicetype.NEXTVAL;
END;
/

---------------------------------------------------------------------------------------------

-- TABLE
CREATE TABLE clients (
  client_id             NUMBER          NOT NULL,
  name                  VARCHAR2(120)   NOT NULL,
  client_type           VARCHAR2(40),              -- e.g., "Business", "Individual", "Gov"
  sector                VARCHAR2(60),              -- optional categorisation
  email                 VARCHAR2(120),
  billing_address_id_fk NUMBER,
  status                VARCHAR2(12)   DEFAULT 'ACTIVE' NOT NULL,  -- ACTIVE/INACTIVE
  CONSTRAINT pk_clients PRIMARY KEY (client_id),
  CONSTRAINT uq_clients_email UNIQUE (email),
  CONSTRAINT fk_clients_billing_address
    FOREIGN KEY (billing_address_id_fk) REFERENCES address(address_id),
  CONSTRAINT ck_clients_status
    CHECK (status IN ('ACTIVE','INACTIVE'))
);

-- Helpful index on FK
CREATE INDEX ix_clients_billing_addr_fk ON clients(billing_address_id_fk);


/*
(JOIN clients c ON c.billing_address_id_fk = a.address_id).
*/

-- Sequence and trigger
CREATE SEQUENCE seq_clients START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_clients_bi
BEFORE INSERT ON clients
FOR EACH ROW
WHEN (NEW.client_id IS NULL)
BEGIN
  :NEW.client_id := seq_clients.NEXTVAL;
END;
/


-- SUPPLIERS
CREATE TABLE suppliers (
  supplier_id    NUMBER         NOT NULL,
  name           VARCHAR2(120)  NOT NULL,
  phone          VARCHAR2(40),
  email          VARCHAR2(120),
  address_id_fk  NUMBER,
  notes          VARCHAR2(4000),
  CONSTRAINT pk_suppliers PRIMARY KEY (supplier_id),
  CONSTRAINT uq_suppliers_name UNIQUE (name),
  CONSTRAINT fk_suppliers_address
    FOREIGN KEY (address_id_fk) REFERENCES address(address_id)
);


CREATE INDEX ix_suppliers_address_fk ON suppliers(address_id_fk);

CREATE SEQUENCE seq_suppliers START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_suppliers_bi
BEFORE INSERT ON suppliers
FOR EACH ROW
WHEN (NEW.supplier_id IS NULL)
BEGIN
  :NEW.supplier_id := seq_suppliers.NEXTVAL;
END;
/

-- SUPPLIER_SERVICE (junction table)
CREATE TABLE supplier_service (
  supplier_id_fk    NUMBER NOT NULL,
  service_type_id_fk NUMBER NOT NULL,
  CONSTRAINT pk_supplier_service PRIMARY KEY (supplier_id_fk, service_type_id_fk),
  CONSTRAINT fk_suppliersvc_supplier
    FOREIGN KEY (supplier_id_fk) REFERENCES suppliers(supplier_id),
  CONSTRAINT fk_suppliersvc_servicetype
    FOREIGN KEY (service_type_id_fk) REFERENCES servicetype(service_type_id)
);

-- Indexes on the bridge FKs (PK already helps, but separate indexes can improve deletes)
CREATE INDEX ix_supsvc_supplier_fk ON supplier_service(supplier_id_fk);
CREATE INDEX ix_supsvc_servtype_fk ON supplier_service(service_type_id_fk);

----------------------------------------------------------------------------------------

CREATE TABLE staff (
  staff_id      NUMBER         NOT NULL,
  role_id_fk    NUMBER         NOT NULL,
  first_name    VARCHAR2(60)   NOT NULL,
  last_name     VARCHAR2(60)   NOT NULL,
  email         VARCHAR2(120),
  phone         VARCHAR2(40),
  hire_date     DATE,
  active_flag   CHAR(1) DEFAULT 'Y' NOT NULL,     -- 'Y' or 'N'
  CONSTRAINT pk_staff PRIMARY KEY (staff_id),
  CONSTRAINT uq_staff_email UNIQUE (email),
  CONSTRAINT fk_staff_role
    FOREIGN KEY (role_id_fk) REFERENCES staffroles(role_id),
  CONSTRAINT ck_staff_active_flag CHECK (active_flag IN ('Y','N'))
);

CREATE INDEX ix_staff_role_fk ON staff(role_id_fk);

CREATE SEQUENCE seq_staff START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_staff_bi
BEFORE INSERT ON staff
FOR EACH ROW
WHEN (NEW.staff_id IS NULL)
BEGIN
  :NEW.staff_id := seq_staff.NEXTVAL;
END;
/


---------------------------------------------------


CREATE TABLE warehouse (
  location_id_fk          NUMBER        NOT NULL,
  name                    VARCHAR2(120) NOT NULL,
  storage_capacity_tonnes NUMBER(12,2),
  manager_staff_id_fk     NUMBER,
  no_of_employees         NUMBER,
  no_of_vehicles          NUMBER,
  CONSTRAINT pk_warehouse PRIMARY KEY (location_id_fk),
  CONSTRAINT fk_wh_location
    FOREIGN KEY (location_id_fk) REFERENCES location(location_id),
  CONSTRAINT fk_wh_manager
    FOREIGN KEY (manager_staff_id_fk) REFERENCES staff(staff_id),
  CONSTRAINT ck_wh_counts
    CHECK ( (no_of_employees IS NULL OR no_of_employees >= 0)
        AND (no_of_vehicles  IS NULL OR no_of_vehicles  >= 0) ),
  CONSTRAINT ck_wh_storage
    CHECK (storage_capacity_tonnes IS NULL OR storage_capacity_tonnes >= 0)
);

-- Helpful FK indexes
CREATE INDEX ix_wh_manager_fk  ON warehouse(manager_staff_id_fk);

CREATE TABLE hub (
  location_id_fk          NUMBER        NOT NULL,
  opening_hours           VARCHAR2(120),
  manager_staff_id_fk     NUMBER,
  no_of_employees         NUMBER,
  no_of_vehicles          NUMBER,
  storage_capacity_tonnes NUMBER(12,2),
  CONSTRAINT pk_hub PRIMARY KEY (location_id_fk),
  CONSTRAINT fk_hub_location
    FOREIGN KEY (location_id_fk) REFERENCES location(location_id),
  CONSTRAINT fk_hub_manager
    FOREIGN KEY (manager_staff_id_fk) REFERENCES staff(staff_id),
  CONSTRAINT ck_hub_counts
    CHECK ( (no_of_employees IS NULL OR no_of_employees >= 0)
        AND (no_of_vehicles  IS NULL OR no_of_vehicles  >= 0) ),
  CONSTRAINT ck_hub_storage
    CHECK (storage_capacity_tonnes IS NULL OR storage_capacity_tonnes >= 0)
);

CREATE INDEX ix_hub_manager_fk ON hub(manager_staff_id_fk);

CREATE TABLE companyvehicles (
  vehicle_id      NUMBER        NOT NULL,
  mode_id_fk      NUMBER        NOT NULL,         -- ROAD/RAIL/AIR/SEA etc.
  vehicle_reg_no  VARCHAR2(32)  NOT NULL,         -- unique per vehicle
  capacity_kg     NUMBER(12,2),
  volume_m3       NUMBER(12,3),
  CONSTRAINT pk_companyvehicles PRIMARY KEY (vehicle_id),
  CONSTRAINT uq_companyvehicles_reg UNIQUE (vehicle_reg_no),
  CONSTRAINT fk_vehicle_mode
    FOREIGN KEY (mode_id_fk) REFERENCES transportmode(mode_id),
  CONSTRAINT ck_vehicle_nonneg
    CHECK ( (capacity_kg IS NULL OR capacity_kg >= 0)
        AND (volume_m3  IS NULL OR volume_m3  >= 0) )
);

CREATE INDEX ix_vehicle_mode_fk ON companyvehicles(mode_id_fk);

CREATE SEQUENCE seq_companyvehicles START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_companyvehicles_bi
BEFORE INSERT ON companyvehicles
FOR EACH ROW
WHEN (NEW.vehicle_id IS NULL)
BEGIN
  :NEW.vehicle_id := seq_companyvehicles.NEXTVAL;
END;
/


CREATE TABLE vehicleservices (
  vehicle_service_id  NUMBER       NOT NULL,
  vehicle_id_fk       NUMBER       NOT NULL,
  supplier_id_fk      NUMBER       NOT NULL,
  service_type_id_fk  NUMBER       NOT NULL,
  start_date          DATE         NOT NULL,
  end_date            DATE,
  notes               VARCHAR2(4000),
  CONSTRAINT pk_vehicleservices PRIMARY KEY (vehicle_service_id),
  CONSTRAINT fk_vs_vehicle
    FOREIGN KEY (vehicle_id_fk) REFERENCES companyvehicles(vehicle_id),
  CONSTRAINT fk_vs_supplier
    FOREIGN KEY (supplier_id_fk) REFERENCES suppliers(supplier_id),
  CONSTRAINT fk_vs_servicetype
    FOREIGN KEY (service_type_id_fk) REFERENCES servicetype(service_type_id),
  CONSTRAINT ck_vs_dates CHECK (end_date IS NULL OR end_date >= start_date)
);


-- Helpful FK indexes
CREATE INDEX ix_vs_vehicle_fk     ON vehicleservices(vehicle_id_fk);
CREATE INDEX ix_vs_supplier_fk    ON vehicleservices(supplier_id_fk);
CREATE INDEX ix_vs_servicetype_fk ON vehicleservices(service_type_id_fk);

CREATE SEQUENCE seq_vehicleservices START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_vehicleservices_bi
BEFORE INSERT ON vehicleservices
FOR EACH ROW
WHEN (NEW.vehicle_service_id IS NULL)
BEGIN
  :NEW.vehicle_service_id := seq_vehicleservices.NEXTVAL;
END;
/

-- Constraints created?
SELECT table_name, constraint_name, constraint_type, status
FROM user_constraints
WHERE table_name IN ('WAREHOUSE','HUB','COMPANYVEHICLES','VEHICLESERVICES')
ORDER BY table_name, constraint_type;

-- Indexes created?
SELECT table_name, index_name, uniqueness
FROM user_indexes
WHERE table_name IN ('WAREHOUSE','HUB','COMPANYVEHICLES','VEHICLESERVICES')
ORDER BY table_name, index_name;

---------------------------------------------------------------------------------


CREATE TABLE shipment (
  shipment_id         NUMBER           NOT NULL,
  client_id_fk        NUMBER           NOT NULL,         -- customer for this shipment
  booking_timestamp   TIMESTAMP        DEFAULT SYSTIMESTAMP NOT NULL,
  delivery_deadline   TIMESTAMP,
  cargo_weight_kg     NUMBER(12,2),
  volume_m3           NUMBER(12,3),
  priority_flag       CHAR(1)          DEFAULT 'N' NOT NULL,  -- 'Y'/'N'
  insurance_flag      CHAR(1)          DEFAULT 'N' NOT NULL,  -- 'Y'/'N'
  client_reference_no VARCHAR2(60),
  perishable_flag     CHAR(1)          DEFAULT 'N' NOT NULL,  -- 'Y'/'N'
  flammable_flag      CHAR(1)          DEFAULT 'N' NOT NULL,  -- 'Y'/'N'
  CONSTRAINT pk_shipment PRIMARY KEY (shipment_id),
  CONSTRAINT fk_shipment_client
    FOREIGN KEY (client_id_fk) REFERENCES clients(client_id),
  CONSTRAINT ck_ship_flags
    CHECK (priority_flag IN ('Y','N')
       AND insurance_flag IN ('Y','N')
       AND perishable_flag IN ('Y','N')
       AND flammable_flag IN ('Y','N')),
  CONSTRAINT ck_ship_nonneg
    CHECK ( (cargo_weight_kg IS NULL OR cargo_weight_kg >= 0)
        AND (volume_m3      IS NULL OR volume_m3      >= 0) )
);

CREATE INDEX ix_shipment_client_fk ON shipment(client_id_fk);

CREATE SEQUENCE seq_shipment START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_shipment_bi
BEFORE INSERT ON shipment
FOR EACH ROW
WHEN (NEW.shipment_id IS NULL)
BEGIN
  :NEW.shipment_id := seq_shipment.NEXTVAL;
END;
/




CREATE TABLE shipmenttrip (
  trip_id               NUMBER          NOT NULL,
  shipment_id_fk        NUMBER          NOT NULL,
  mode_id_fk            NUMBER          NOT NULL,        -- ROAD/RAIL/AIR/SEA
  origin_location_id_fk NUMBER          NOT NULL,
  dest_location_id_fk   NUMBER          NOT NULL,
  expected_departure    TIMESTAMP,
  expected_arrival      TIMESTAMP,
  actual_departure      TIMESTAMP,
  actual_arrival        TIMESTAMP,
  distance_km           NUMBER(12,2),
  tracking_no           VARCHAR2(60),
  vehicle_id_fk         NUMBER,
  staff_id_fk           NUMBER,                           -- driver/lead
  CONSTRAINT pk_shipmenttrip PRIMARY KEY (trip_id),
  CONSTRAINT fk_trip_shipment
    FOREIGN KEY (shipment_id_fk)        REFERENCES shipment(shipment_id)
      ON DELETE CASCADE,
  CONSTRAINT fk_trip_mode
    FOREIGN KEY (mode_id_fk)            REFERENCES transportmode(mode_id),
  CONSTRAINT fk_trip_origin
    FOREIGN KEY (origin_location_id_fk) REFERENCES location(location_id),
  CONSTRAINT fk_trip_dest
    FOREIGN KEY (dest_location_id_fk)   REFERENCES location(location_id),
  CONSTRAINT fk_trip_vehicle
    FOREIGN KEY (vehicle_id_fk)         REFERENCES companyvehicles(vehicle_id),
  CONSTRAINT fk_trip_staff
    FOREIGN KEY (staff_id_fk)           REFERENCES staff(staff_id),
  CONSTRAINT ck_trip_dates
    CHECK (
      (expected_departure IS NULL OR expected_arrival IS NULL OR expected_arrival >= expected_departure) AND
      (actual_departure   IS NULL OR actual_arrival   IS NULL OR actual_arrival   >= actual_departure)
    ),
  CONSTRAINT ck_trip_distance CHECK (distance_km IS NULL OR distance_km >= 0)
);

-- Helpful FK indexes
CREATE INDEX ix_trip_shipment_fk ON shipmenttrip(shipment_id_fk);
CREATE INDEX ix_trip_mode_fk     ON shipmenttrip(mode_id_fk);
CREATE INDEX ix_trip_origin_fk   ON shipmenttrip(origin_location_id_fk);
CREATE INDEX ix_trip_dest_fk     ON shipmenttrip(dest_location_id_fk);
CREATE INDEX ix_trip_vehicle_fk  ON shipmenttrip(vehicle_id_fk);
CREATE INDEX ix_trip_staff_fk    ON shipmenttrip(staff_id_fk);

CREATE SEQUENCE seq_shipmenttrip START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_shipmenttrip_bi
BEFORE INSERT ON shipmenttrip
FOR EACH ROW
WHEN (NEW.trip_id IS NULL)
BEGIN
  :NEW.trip_id := seq_shipmenttrip.NEXTVAL;
END;
/


CREATE TABLE perishabledetails (
  shipment_id_fk    NUMBER        NOT NULL,
  temperature_min_c NUMBER(6,2),
  temperature_max_c NUMBER(6,2),
  humidity_req_pct  NUMBER(5,2),         -- 0..100
  monetary_value    NUMBER(12,2),
  expiry_date       DATE,
  CONSTRAINT pk_perishable PRIMARY KEY (shipment_id_fk),
  CONSTRAINT fk_perishable_shipment
    FOREIGN KEY (shipment_id_fk) REFERENCES shipment(shipment_id)
      ON DELETE CASCADE,
  CONSTRAINT ck_perish_temp
    CHECK (temperature_min_c IS NULL OR temperature_max_c IS NULL
           OR temperature_max_c >= temperature_min_c),
  CONSTRAINT ck_perish_humidity
    CHECK (humidity_req_pct IS NULL OR (humidity_req_pct BETWEEN 0 AND 100))
);


CREATE TABLE flammabledetails (
  shipment_id_fk   NUMBER        NOT NULL,
  max_temp_for_item NUMBER(6,2),
  min_temp_for_item NUMBER(6,2),
  viscosity         NUMBER(12,4),
  combustibility    VARCHAR2(40),        -- e.g., class label
  CONSTRAINT pk_flammable PRIMARY KEY (shipment_id_fk),
  CONSTRAINT fk_flammable_shipment
    FOREIGN KEY (shipment_id_fk) REFERENCES shipment(shipment_id)
      ON DELETE CASCADE
);


CREATE TABLE shipment_status_history (
  status_hist_id   NUMBER        NOT NULL,
  shipment_id_fk   NUMBER        NOT NULL,
  status           VARCHAR2(40)  NOT NULL,   -- e.g., BOOKED, IN_TRANSIT, DELIVERED, CANCELLED
  status_timestamp TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
  notes            VARCHAR2(1000),
  staff_id_fk      NUMBER,
  CONSTRAINT pk_ship_status_hist PRIMARY KEY (status_hist_id),
  CONSTRAINT fk_ssh_shipment
    FOREIGN KEY (shipment_id_fk) REFERENCES shipment(shipment_id)
      ON DELETE CASCADE,
  CONSTRAINT fk_ssh_staff
    FOREIGN KEY (staff_id_fk) REFERENCES staff(staff_id)
);

CREATE INDEX ix_ssh_shipment_fk ON shipment_status_history(shipment_id_fk);
CREATE INDEX ix_ssh_staff_fk    ON shipment_status_history(staff_id_fk);

CREATE SEQUENCE seq_ship_status_hist START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_ship_status_hist_bi
BEFORE INSERT ON shipment_status_history
FOR EACH ROW
WHEN (NEW.status_hist_id IS NULL)
BEGIN
  :NEW.status_hist_id := seq_ship_status_hist.NEXTVAL;
END;
/


-- INVOICES
CREATE TABLE invoices (
  invoice_id      NUMBER           NOT NULL,
  client_id_fk    NUMBER           NOT NULL,
  invoice_no      VARCHAR2(40)     NOT NULL,                 -- business-facing number
  invoice_date    DATE             DEFAULT TRUNC(SYSDATE) NOT NULL,
  due_date        DATE,
  status          VARCHAR2(20)     DEFAULT 'ISSUED' NOT NULL, -- DRAFT/ISSUED/PART_PAID/PAID/VOID
  currency_code   VARCHAR2(3)      DEFAULT 'GBP' NOT NULL,    -- simple 3-char ISO code
  header_notes    VARCHAR2(1000),
  header_shipment_id_fk NUMBER,                               -- optional: if invoice is for one shipment
  CONSTRAINT pk_invoices PRIMARY KEY (invoice_id),
  CONSTRAINT uq_invoices_no UNIQUE (invoice_no),
  CONSTRAINT fk_inv_client
    FOREIGN KEY (client_id_fk) REFERENCES clients(client_id),
  CONSTRAINT fk_inv_header_shipment
    FOREIGN KEY (header_shipment_id_fk) REFERENCES shipment(shipment_id),
  CONSTRAINT ck_inv_status
    CHECK (status IN ('DRAFT','ISSUED','PART_PAID','PAID','VOID')),
  CONSTRAINT ck_inv_dates
    CHECK (due_date IS NULL OR due_date >= invoice_date)
);

-- Helpful FK indexes
CREATE INDEX ix_inv_client_fk          ON invoices(client_id_fk);
CREATE INDEX ix_inv_header_shipment_fk ON invoices(header_shipment_id_fk);

-- Sequence + trigger
CREATE SEQUENCE seq_invoices START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_invoices_bi
BEFORE INSERT ON invoices
FOR EACH ROW
WHEN (NEW.invoice_id IS NULL)
BEGIN
  :NEW.invoice_id := seq_invoices.NEXTVAL;
END;
/


-- INVOICE_LINE
CREATE TABLE invoice_line (
  invoice_line_id       NUMBER         NOT NULL,
  invoice_id_fk         NUMBER         NOT NULL,
  shipment_id_fk        NUMBER,                    -- optional: line-level link
  description           VARCHAR2(200)  NOT NULL,
  quantity              NUMBER(12,2)   DEFAULT 1   NOT NULL,
  unit_price            NUMBER(12,2)   DEFAULT 0   NOT NULL,
  line_total            NUMBER(14,2)   GENERATED ALWAYS AS (quantity * unit_price) VIRTUAL,
  CONSTRAINT pk_invoice_line PRIMARY KEY (invoice_line_id),
  CONSTRAINT fk_il_invoice
    FOREIGN KEY (invoice_id_fk)  REFERENCES invoices(invoice_id)
      ON DELETE CASCADE,         -- deleting an invoice deletes its lines
  CONSTRAINT fk_il_shipment
    FOREIGN KEY (shipment_id_fk) REFERENCES shipment(shipment_id),
  CONSTRAINT ck_il_qty CHECK (quantity >= 0),
  CONSTRAINT ck_il_price CHECK (unit_price >= 0)
);

-- Helpful FK indexes
CREATE INDEX ix_il_invoice_fk  ON invoice_line(invoice_id_fk);
CREATE INDEX ix_il_shipment_fk ON invoice_line(shipment_id_fk);

-- Sequence + trigger
CREATE SEQUENCE seq_invoice_line START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_invoice_line_bi
BEFORE INSERT ON invoice_line
FOR EACH ROW
WHEN (NEW.invoice_line_id IS NULL)
BEGIN
  :NEW.invoice_line_id := seq_invoice_line.NEXTVAL;
END;
/


-- PAYMENTS
CREATE TABLE payments (
  payment_id      NUMBER         NOT NULL,
  client_id_fk    NUMBER         NOT NULL,
  payment_date    DATE           DEFAULT TRUNC(SYSDATE) NOT NULL,
  amount          NUMBER(14,2)   NOT NULL,
  payment_method  VARCHAR2(20)   DEFAULT 'BANK_TRANSFER' NOT NULL, -- BANK_TRANSFER/CARD/CASH/CHEQUE/OTHER
  reference       VARCHAR2(80),
  notes           VARCHAR2(1000),
  CONSTRAINT pk_payments PRIMARY KEY (payment_id),
  CONSTRAINT fk_pay_client
    FOREIGN KEY (client_id_fk) REFERENCES clients(client_id),
  CONSTRAINT ck_pay_amount CHECK (amount > 0),
  CONSTRAINT ck_pay_method CHECK (payment_method IN ('BANK_TRANSFER','CARD','CASH','CHEQUE','OTHER'))
);

CREATE INDEX ix_pay_client_fk ON payments(client_id_fk);

CREATE SEQUENCE seq_payments START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_payments_bi
BEFORE INSERT ON payments
FOR EACH ROW
WHEN (NEW.payment_id IS NULL)
BEGIN
  :NEW.payment_id := seq_payments.NEXTVAL;
END;
/

-- PAYMENT_ALLOCATION
CREATE TABLE payment_allocation (
  payment_id_fk   NUMBER       NOT NULL,
  invoice_id_fk   NUMBER       NOT NULL,
  amount_allocated NUMBER(14,2) NOT NULL,
  CONSTRAINT pk_payment_allocation PRIMARY KEY (payment_id_fk, invoice_id_fk),
  CONSTRAINT fk_pa_payment
    FOREIGN KEY (payment_id_fk) REFERENCES payments(payment_id)
      ON DELETE CASCADE,
  CONSTRAINT fk_pa_invoice
    FOREIGN KEY (invoice_id_fk) REFERENCES invoices(invoice_id)
      ON DELETE CASCADE,
  CONSTRAINT ck_pa_amount CHECK (amount_allocated > 0)
);

-- Helpful FK indexes (PK already covers both, but these can help deletes)
CREATE INDEX ix_pa_payment_fk ON payment_allocation(payment_id_fk);
CREATE INDEX ix_pa_invoice_fk ON payment_allocation(invoice_id_fk);


-- Constraints
SELECT table_name, constraint_name, constraint_type, status
FROM user_constraints
WHERE table_name IN ('INVOICES','INVOICE_LINE','PAYMENTS','PAYMENT_ALLOCATION')
ORDER BY table_name, constraint_type, constraint_name;

-- Indexes
SELECT table_name, index_name, uniqueness
FROM user_indexes
WHERE table_name IN ('INVOICES','INVOICE_LINE','PAYMENTS','PAYMENT_ALLOCATION')
ORDER BY table_name, index_name;



--Part 6

-- SHIPMENT lookups by dates / flags / client
CREATE INDEX ix_shipment_deadline ON shipment(delivery_deadline);
CREATE INDEX ix_shipment_client_flags ON shipment(client_id_fk, priority_flag, perishable_flag, flammable_flag);

-- SHIPMENTTRIP common filters
CREATE INDEX ix_trip_expected ON shipmenttrip(expected_departure, expected_arrival);
CREATE INDEX ix_trip_actual   ON shipmenttrip(actual_departure, actual_arrival);

-- STATUS history reporting
CREATE INDEX ix_ssh_status_time ON shipment_status_history(status, status_timestamp);

-- INVOICE queries by status/due date
CREATE INDEX ix_inv_status_due ON invoices(status, due_date);
CREATE INDEX ix_inv_client_date ON invoices(client_id_fk, invoice_date);

-- PAYMENTS by date
CREATE INDEX ix_pay_date ON payments(payment_date);

-- VEHICLESERVICES by date range / supplier
CREATE INDEX ix_vs_dates_supplier ON vehicleservices(start_date, end_date, supplier_id_fk);


-- Addresses
INSERT INTO address(address_id, line_1_address, city, postcode, county, country)
VALUES (seq_address.NEXTVAL, '1 Main St', 'Birmingham', 'B1 1AA', 'West Midlands', 'UK');
INSERT INTO address(address_id, line_1_address, city, postcode, county, country)
VALUES (seq_address.NEXTVAL, '2 Rail Yard', 'Manchester', 'M1 2BB', 'Greater Manchester', 'UK');

-- Locations
INSERT INTO location(location_id, name, location_building_type, address_id_fk)
VALUES (seq_location.NEXTVAL, 'Birmingham Central Depot', 'Warehouse', 1);
INSERT INTO location(location_id, name, location_building_type, address_id_fk)
VALUES (seq_location.NEXTVAL, 'Manchester Hub A', 'Hub', 2);

-- Staff Roles & Staff
INSERT INTO staffroles(role_id, role_name, permission_level)
VALUES (seq_staffroles.NEXTVAL, 'Manager', 10);
INSERT INTO staffroles(role_id, role_name, permission_level)
VALUES (seq_staffroles.NEXTVAL, 'Driver', 3);

INSERT INTO staff(staff_id, role_id_fk, first_name, last_name, email, active_flag)
VALUES (seq_staff.NEXTVAL, 1, 'Alice', 'Nguyen', 'alice@railuk.com', 'Y');
INSERT INTO staff(staff_id, role_id_fk, first_name, last_name, email, active_flag)
VALUES (seq_staff.NEXTVAL, 2, 'Bob', 'Singh', 'bob@railuk.com', 'Y');

-- Specialise the Locations
INSERT INTO warehouse(location_id_fk, name, storage_capacity_tonnes, manager_staff_id_fk, no_of_employees, no_of_vehicles)
VALUES (1, 'Birmingham Central Depot', 2000, 1, 25, 10);
INSERT INTO hub(location_id_fk, opening_hours, manager_staff_id_fk, no_of_employees, no_of_vehicles, storage_capacity_tonnes)
VALUES (2, '06:00-22:00', 1, 18, 6, 500);

-- Transport modes & vehicles
INSERT INTO transportmode(mode_id, code, description)
VALUES (seq_transportmode.NEXTVAL, 'ROAD', 'Road freight');
INSERT INTO transportmode(mode_id, code, description)
VALUES (seq_transportmode.NEXTVAL, 'RAIL', 'Rail freight');

INSERT INTO companyvehicles(vehicle_id, mode_id_fk, vehicle_reg_no, capacity_kg, volume_m3)
VALUES (seq_companyvehicles.NEXTVAL, 1, 'RAILUK-TRK-001', 15000, 60);

-- Clients
INSERT INTO clients(client_id, name, client_type, email, billing_address_id_fk, status)
VALUES (seq_clients.NEXTVAL, 'Acme Manufacturing Ltd', 'Business', 'accounts@acme.com', 1, 'ACTIVE');

-- Suppliers & services
INSERT INTO servicetype(service_type_id, name) VALUES (seq_servicetype.NEXTVAL, 'Fuel');
INSERT INTO servicetype(service_type_id, name) VALUES (seq_servicetype.NEXTVAL, 'Maintenance');

INSERT INTO suppliers(supplier_id, name, email, address_id_fk)
VALUES (seq_suppliers.NEXTVAL, 'North Fuel Co', 'ops@northfuel.co.uk', 2);

INSERT INTO supplier_service(supplier_id_fk, service_type_id_fk) VALUES (1, 1);
INSERT INTO supplier_service(supplier_id_fk, service_type_id_fk) VALUES (1, 2);

INSERT INTO vehicleservices(vehicle_service_id, vehicle_id_fk, supplier_id_fk, service_type_id_fk, start_date, notes)
VALUES (seq_vehicleservices.NEXTVAL, 1, 1, 1, TRUNC(SYSDATE)-10, 'Fuel contract started');

-- Shipment & trip
INSERT INTO shipment(shipment_id, client_id_fk, delivery_deadline, cargo_weight_kg, priority_flag, perishable_flag, flammable_flag)
VALUES (seq_shipment.NEXTVAL, 1, SYSTIMESTAMP + 5, 1200, 'Y', 'N', 'N');

INSERT INTO shipmenttrip(trip_id, shipment_id_fk, mode_id_fk, origin_location_id_fk, dest_location_id_fk,
                         expected_departure, expected_arrival, vehicle_id_fk, staff_id_fk, distance_km)
VALUES (seq_shipmenttrip.NEXTVAL, 1, 1, 1, 2, SYSTIMESTAMP + 1, SYSTIMESTAMP + 2, 1, 2, 140.5);

-- Invoice & lines
INSERT INTO invoices(invoice_id, client_id_fk, invoice_no, invoice_date, due_date, status, currency_code, header_shipment_id_fk)
VALUES (seq_invoices.NEXTVAL, 1, 'INV-0001', TRUNC(SYSDATE), TRUNC(SYSDATE)+30, 'ISSUED', 'GBP', 1);

INSERT INTO invoice_line(invoice_line_id, invoice_id_fk, shipment_id_fk, description, quantity, unit_price)
VALUES (seq_invoice_line.NEXTVAL, 1, 1, 'Road freight Birmingham→Manchester', 1, 350.00);

-- Payment & allocation (full)
INSERT INTO payments(payment_id, client_id_fk, payment_date, amount, payment_method, reference)
VALUES (seq_payments.NEXTVAL, 1, TRUNC(SYSDATE)+1, 350.00, 'BANK_TRANSFER', 'ACME-350');

INSERT INTO payment_allocation(payment_id_fk, invoice_id_fk, amount_allocated)
VALUES (1, 1, 350.00);

COMMIT;