-- Adds the two columns Technician.java expects (@Lob photo, photoContentType)
-- that camfix's technician table never had. Confirmed live:
-- GET /api/technician 500'd with "Unknown column 't1_0.photo'" before this ran
-- - not just photo-upload paths, but the plain technician listing, since
-- Hibernate includes every mapped column in its default SELECT.
-- Both nullable: existing rows are unaffected, no data loss.
ALTER TABLE technician
    ADD COLUMN photo LONGBLOB NULL,
    ADD COLUMN photo_content_type VARCHAR(100) NULL;
