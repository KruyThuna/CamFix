-- MySQL: retain legacy data while allowing the current backend to insert rows.
-- Current technician IDs refer to `technician`, whereas legacy TechnicianID
-- values refer to `technicians`; never copy IDs between these two namespaces.
ALTER TABLE call_history
    MODIFY COLUMN CallerID BIGINT NULL,
    MODIFY COLUMN TechnicianID BIGINT NULL;

ALTER TABLE technician_addresses
    MODIFY COLUMN TechnicianID BIGINT NULL;

-- Preserve defaults saved through the previous entity mapping.
UPDATE user_addresses
SET Is_Default = isDefault
WHERE isDefault IS NOT NULL;
