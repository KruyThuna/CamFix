-- technician_live_locations had no `id` column at all, even though
-- TechnicianLiveLocation.java declares one as its @Id (@GeneratedValue(IDENTITY)).
-- Confirmed live: this broke 4 of 5 admin panel endpoints (/api/admin/stats,
-- /api/admin/technicians, /api/admin/technicians/locations,
-- /api/admin/technicians/{id}) with "Unknown column 'tll1_0.id'" - any admin
-- page that lists or loads a technician touches this table.
--
-- Table had 0 rows at the time of this migration, so this rebuilds it
-- cleanly rather than working around the gap:
--   - adds `id` as the real AUTO_INCREMENT primary key the entity expects
--   - drops the legacy `TechnicianID` column: fully redundant with
--     technician_id, and its foreign key pointed at the orphaned
--     `technicians` table rather than the real `technician` table
--   - adds a foreign key on technician_id -> technician (technician_id),
--     which technician_id never had before this
ALTER TABLE technician_live_locations
    DROP FOREIGN KEY FK_TechnicianLiveLocation_Technician,
    DROP PRIMARY KEY,
    DROP COLUMN TechnicianID,
    ADD COLUMN id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST,
    ADD CONSTRAINT fk_technician_live_locations_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
        ON DELETE CASCADE;
