-- Run once against the existing CamFix database before starting the updated API.
ALTER TABLE technician ADD COLUMN id_card LONGBLOB NULL;
