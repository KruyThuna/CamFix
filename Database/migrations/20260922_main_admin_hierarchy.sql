-- MySQL. Select the existing owner account explicitly before running:
-- SET @main_admin_user_id = <owner user ID>;
-- Do not automatically promote every Admin.
ALTER TABLE users MODIFY COLUMN ROLE VARCHAR(20) NOT NULL;
UPDATE users SET ROLE = 'MAIN_ADMIN'
WHERE Userid = @main_admin_user_id AND ROLE = 'ADMIN' AND STATUS = 'ACTIVE';
-- Convert the former delegated-user role to the new Admin role.
UPDATE users SET ROLE = 'ADMIN' WHERE ROLE = 'SUPER_USER';
