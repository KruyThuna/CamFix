-- Add photo/image storage columns to job table for issue attachments
ALTER TABLE `job`
  ADD COLUMN `photo` MEDIUMBLOB NULL,
  ADD COLUMN `photo_content_type` VARCHAR(100) NULL,
  ADD COLUMN `photo_url` VARCHAR(500) NULL;

