-- MySQL: only needed for installations whose ROLE column still uses ENUM.
-- VARCHAR preserves existing role values and permits SUPER_USER.
ALTER TABLE users MODIFY COLUMN ROLE VARCHAR(20) NOT NULL;
