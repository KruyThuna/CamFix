USE CamFix;

-- 1. Create missing tables first
CREATE TABLE IF NOT EXISTS service_category (
    serviceCategoryId  BIGINT       NOT NULL AUTO_INCREMENT,
    categoryName       VARCHAR(255) NULL,
    description        VARCHAR(255) NULL,
    icon               VARCHAR(255) NULL,
    create_at          TIMESTAMP    NULL,
    update_at          TIMESTAMP    NULL,
    PRIMARY KEY (serviceCategoryId)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS technician_service (
    id                  BIGINT       NOT NULL AUTO_INCREMENT,
    technician_id       BIGINT       NOT NULL,
    title               VARCHAR(120) NOT NULL,
    price               DOUBLE       NOT NULL,
    description         VARCHAR(500) NULL,
    created_at          DATETIME(6)  NULL,
    photo_content_type  VARCHAR(100) NULL,
    photo_version       BIGINT       NULL,
    PRIMARY KEY (id),
    KEY idx_technician_service_technician (technician_id),
    CONSTRAINT fk_technician_service_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS technician_service_photo (
    listing_id    BIGINT       NOT NULL,
    data          LONGBLOB     NOT NULL,
    content_type  VARCHAR(100) NOT NULL,
    PRIMARY KEY (listing_id),
    CONSTRAINT fk_technician_service_photo_listing
        FOREIGN KEY (listing_id) REFERENCES technician_service (id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS quote_item (
    id           BIGINT       NOT NULL AUTO_INCREMENT,
    quote_id     BIGINT       NOT NULL,
    title        VARCHAR(120) NOT NULL,
    price        DOUBLE       NOT NULL,
    note         VARCHAR(300) NULL,
    recommended  BIT          NOT NULL DEFAULT 0,
    approved     BIT          NULL,
    PRIMARY KEY (id),
    KEY idx_quote_item_quote (quote_id),
    CONSTRAINT fk_quote_item_quote
        FOREIGN KEY (quote_id) REFERENCES service_quote (id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payment (
    id              BIGINT      NOT NULL AUTO_INCREMENT,
    job_id          BIGINT      NOT NULL,
    quote_id        BIGINT      NOT NULL,
    base_amount     DOUBLE      NOT NULL,
    platform_fee    DOUBLE      NOT NULL,
    tax_amount      DOUBLE      NOT NULL,
    total_amount    DOUBLE      NOT NULL,
    payment_method  VARCHAR(20) NOT NULL,
    card_last4      VARCHAR(4)  NULL,
    service_ref     VARCHAR(20) NOT NULL,
    created_at      DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_payment_quote (quote_id),
    KEY idx_payment_job (job_id),
    CONSTRAINT fk_payment_job
        FOREIGN KEY (job_id) REFERENCES job (id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_payment_quote
        FOREIGN KEY (quote_id) REFERENCES service_quote (id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS khqr_payment (
    id           BIGINT       NOT NULL AUTO_INCREMENT,
    job_id       BIGINT       NOT NULL,
    quote_id     BIGINT       NOT NULL,
    md5          VARCHAR(32)  NOT NULL,
    qr_string    VARCHAR(600) NOT NULL,
    amount       DOUBLE       NOT NULL,
    status       VARCHAR(10)  NOT NULL,
    created_at   DATETIME(6)  NOT NULL,
    expires_at   DATETIME(6)  NOT NULL,
    bakong_hash  VARCHAR(100) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_khqr_payment_md5 (md5),
    KEY idx_khqr_payment_job (job_id),
    KEY idx_khqr_payment_quote (quote_id),
    CONSTRAINT fk_khqr_payment_job
        FOREIGN KEY (job_id) REFERENCES job (id)
        ON DELETE CASCADE,
    CONSTRAINT fk_khqr_payment_quote
        FOREIGN KEY (quote_id) REFERENCES service_quote (id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- 2. Alter job table
ALTER TABLE job ADD COLUMN bench_fee DOUBLE NULL AFTER status;
ALTER TABLE job ADD COLUMN technician_service_id BIGINT NULL AFTER technician_id;
ALTER TABLE job ADD KEY idx_job_technician_service_id (technician_service_id);
ALTER TABLE job ADD CONSTRAINT fk_job_technician_service
    FOREIGN KEY (technician_service_id) REFERENCES technician_service (id)
    ON DELETE SET NULL;

-- 3. Alter service_price table
ALTER TABLE service_price ADD COLUMN bench_fee DOUBLE NULL AFTER description;
ALTER TABLE service_price ADD COLUMN travel_fee DOUBLE NULL AFTER bench_fee;
UPDATE service_price SET bench_fee = 5.0, travel_fee = 3.0 WHERE bench_fee IS NULL;

-- 4. Alter chat_message table
ALTER TABLE chat_message ADD COLUMN sender_role VARCHAR(12) NOT NULL DEFAULT 'CUSTOMER' AFTER sender_user_id;
ALTER TABLE chat_message ADD COLUMN read_at DATETIME(6) NULL AFTER created_at;

-- 5. Fix column names in user_addresses
ALTER TABLE user_addresses RENAME COLUMN id TO AddressID;
ALTER TABLE user_addresses RENAME COLUMN isDefault TO Is_Default;

-- 6. Fix column names in technician_addresses
ALTER TABLE technician_addresses RENAME COLUMN address_id TO AddressID;

-- 7. Fix column names in call_history
ALTER TABLE call_history RENAME COLUMN call_id TO CallID;
