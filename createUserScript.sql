-- Run this script as SYSTEM or SYS to create a new user
-- IMPORTANT: This must be run as a privileged user

-- Create UCMS user (use a strong password in a real environment)
CREATE USER ucms_chakib IDENTIFIED BY ucms_pass;

-- Grant necessary privileges
GRANT CONNECT, RESOURCE TO ucms_chakib;
GRANT CREATE VIEW TO ucms_chakib;
GRANT CREATE SYNONYM TO ucms_chakib;
GRANT CREATE TRIGGER TO ucms_chakib;
GRANT UNLIMITED TABLESPACE TO ucms_chakib;

-- Verify the user was created
SELECT username, account_status FROM dba_users WHERE username = 'UCMS_CHAKIB';
