CREATE ROLE employee_readonly; 
-- This creates a role (i.e. a group of permissions) for employees who should only read data

REVOKE SELECT ANY TABLE FROM employee_readonly;
REVOKE INSERT ANY TABLE FROM employee_readonly;
REVOKE UPDATE ANY TABLE FROM employee_readonly;
REVOKE DELETE ANY TABLE FROM employee_readonly;
REVOKE CREATE TABLE FROM employee_readonly;
REVOKE CREATE VIEW FROM employee_readonly;
REVOKE CREATE SEQUENCE FROM employee_readonly;
REVOKE CREATE PROCEDURE FROM employee_readonly;
REVOKE DROP ANY TABLE FROM employee_readonly;

--This enforces least privilege, the role cannot read every table, insert data, update data, delete data
--Also role can't conduct any DDL commands 

GRANT SELECT ON clients_accounts_info TO employee_readonly;
GRANT SELECT ON SUPPLIERS_SERVICES_FOR_COMPANY_VEHICLES TO employee_readonly;
--Now the role can only read from these two views

CREATE USER report_user IDENTIFIED BY "LegitPassword123!";
--This creates a database account called report_user.
--report_user is the username
--Identified by sets the password

GRANT CREATE SESSION TO report_user; --needed to allow the user to connect to session

GRANT employee_readonly TO report_user; 
-- grants permissions to report_user 
-- so report_user can:
-- Log in
-- Read only the approved views
-- Cannot change or delete anything

-----------------------------------------------------------------------------------------------------------------

-- SQL injection awareness

-- If user input is directly concatenated into SQL, it can be interpreted as code.
-- i.e, if a login form expects a client_id and the user enters '1=1',
-- the condition becomes always true and all client records are returned.

SELECT *
FROM clients
WHERE client_id = '86' OR 1=1;

-- This occurs because the database cannot distinguish between SQL code
-- and user input when values are directly embedded into the query.

------------------
-- Mitigation
------------------

-- Bind variables prevent SQL injection by treating user input as data only.

SELECT *
FROM clients
WHERE client_id = :p_client_id;

-- Using bind variables ensures that even if a user enters '1=1',
-- Oracle searches for that literal value instead of executing it as SQL.
-- As a result, the injection attempt fails.

--
-- END
