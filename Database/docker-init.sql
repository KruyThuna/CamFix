/* =====================================================================
   CamFix — Docker/dev bootstrap schema (MySQL)

   Used only to seed a FRESH database (e.g. the `mysql` service in
   docker-compose.yml, or a new local install with an empty schema).
   It is NOT a migration for the team's existing/live database - if you
   already have a `CamFix` schema with data in it, do not run this against
   it.

   This is the MySQL DDL extracted from the "ADDENDUM" section at the
   bottom of camfix_schema.sql (what Hibernate/the entities actually
   expect), plus `chat_message` for the live-chat feature, which has no
   entry anywhere else. Column names/types are taken directly from each
   com.api.entity.* class's @Column annotations (naming strategy is
   PhysicalNamingStrategyStandardImpl - verbatim, no case conversion), and
   tables are ordered so every FOREIGN KEY target already exists by the
   time it's referenced. Keep this in sync by hand if an entity's schema
   changes.
   ===================================================================== */

CREATE TABLE IF NOT EXISTS category (
    category_id    BIGINT NOT NULL AUTO_INCREMENT,
    categoryName   VARCHAR(100) NOT NULL,
    description    VARCHAR(500) NULL,
    icon           VARCHAR(255) NULL,
    PRIMARY KEY (category_id),
    UNIQUE KEY uq_category_name (categoryName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS users (
    Userid         BIGINT NOT NULL AUTO_INCREMENT,
    Full_name      VARCHAR(50)  NOT NULL,
    Last_name      VARCHAR(50)  NOT NULL,
    DateofBirth    DATE         NULL,
    Email          VARCHAR(100) NOT NULL,
    Phone_number   VARCHAR(100) NOT NULL,
    Password_hash  VARCHAR(100) NOT NULL,
    Profile_image  VARCHAR(500) NULL,
    ROLE           VARCHAR(20)  NOT NULL,
    STATUS         VARCHAR(20)  NOT NULL,
    has_password         BIT NOT NULL DEFAULT 0,
    must_change_password BIT NOT NULL DEFAULT 0,
    created_at     DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at     DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (Userid),
    UNIQUE KEY uq_users_email (Email),
    UNIQUE KEY uq_users_phone (Phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1:1 with users (UNIQUE on user_id). Also carries the admin-console fields
-- (approval_status, photo, ...) added after the original 3 columns.
CREATE TABLE IF NOT EXISTS technician (
    technician_id        BIGINT NOT NULL AUTO_INCREMENT,
    user_id               BIGINT NOT NULL,
    category_id           BIGINT NOT NULL,
    business_name          VARCHAR(255) NOT NULL,
    experience_year        INT          NOT NULL,
    description            VARCHAR(500) NULL,
    average_rating         DECIMAL(3,2) NULL,
    verified               BIT NOT NULL DEFAULT 0,
    availability_status    VARCHAR(20)  NULL,
    approval_status        VARCHAR(20)  NULL,
    approved_at            DATETIME(6)  NULL,
    rejection_reason       VARCHAR(500) NULL,
    service_area           VARCHAR(255) NULL,
    opening_hours          VARCHAR(255) NULL,
    rating_count           INT          NULL,
    photo                  LONGBLOB     NULL,
    photo_content_type     VARCHAR(100) NULL,
    lastLat                DOUBLE       NULL,
    lastLng                DOUBLE       NULL,
    last_location_at       DATETIME(6)  NULL,
    created_at             DATETIME(6) NOT NULL,
    updated_at             DATETIME(6) NOT NULL,
    PRIMARY KEY (technician_id),
    UNIQUE KEY uq_technician_user (user_id),
    KEY idx_technician_category (category_id),
    CONSTRAINT fk_technician_user
        FOREIGN KEY (user_id) REFERENCES users (Userid),
    CONSTRAINT fk_technician_category
        FOREIGN KEY (category_id) REFERENCES category (category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- UserAddress.java has no @Column annotations at all; Hibernate's implicit
-- naming strategy uses each Java field name verbatim as the column name,
-- which is why these names are camelCase/mixed-case rather than the
-- snake_case used everywhere else in this file.
CREATE TABLE IF NOT EXISTS user_addresses (
    id             BIGINT NOT NULL AUTO_INCREMENT,
    userId         BIGINT       NULL,
    address_Name   VARCHAR(255) NULL,
    address_Line   VARCHAR(255) NULL,
    city           VARCHAR(255) NULL,
    province       VARCHAR(255) NULL,
    latitude       DOUBLE       NULL,
    longitude      DOUBLE       NULL,
    isDefault      BIT          NULL,
    PRIMARY KEY (id),
    KEY idx_user_addresses_user (userId),
    CONSTRAINT fk_user_addresses_user
        FOREIGN KEY (userId) REFERENCES users (Userid)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS technician_addresses (
    address_id     BIGINT NOT NULL AUTO_INCREMENT,
    technician_id  BIGINT       NULL,
    business_name  VARCHAR(255) NULL,
    address_line   VARCHAR(255) NOT NULL,
    city           VARCHAR(255) NULL,
    province       VARCHAR(255) NULL,
    latitude       DOUBLE       NULL,
    longitude      DOUBLE       NULL,
    is_default     BIT          NULL,
    create_at      DATETIME(6)  NULL,
    update_at      DATETIME(6)  NULL,
    PRIMARY KEY (address_id),
    KEY idx_technician_addresses_technician (technician_id),
    CONSTRAINT fk_technician_addresses_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS technician_live_locations (
    id             BIGINT NOT NULL AUTO_INCREMENT,
    technician_id  BIGINT NOT NULL,
    latitude       DOUBLE NOT NULL,
    longitude      DOUBLE NOT NULL,
    accuracy       DOUBLE NULL,
    created_at     DATETIME(6) NULL,
    last_update    DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_technician_live_locations_technician (technician_id),
    KEY idx_technician_live_locations_last_update (last_update),
    CONSTRAINT fk_technician_live_locations_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS favorites (
    FavoriteID     BIGINT NOT NULL AUTO_INCREMENT,
    UserID         BIGINT NOT NULL,
    TechnicianID   BIGINT NOT NULL,
    Created_At     DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (FavoriteID),
    UNIQUE KEY UQ_Favorites_User_Technician (UserID, TechnicianID),
    KEY idx_favorites_technician (TechnicianID),
    CONSTRAINT fk_favorites_user
        FOREIGN KEY (UserID) REFERENCES users (Userid)
        ON DELETE CASCADE,
    CONSTRAINT fk_favorites_technician
        FOREIGN KEY (TechnicianID) REFERENCES technician (technician_id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notification (
    notification_id  BIGINT NOT NULL AUTO_INCREMENT,
    user_id           BIGINT NOT NULL,
    title             VARCHAR(150) NOT NULL,
    message           TEXT         NOT NULL,
    title_km          VARCHAR(150) NULL,
    message_km        TEXT         NULL,
    type              VARCHAR(40)  NULL,
    job_id            BIGINT       NULL,
    is_read           BIT NULL DEFAULT 0,
    created_at        DATETIME(6)  NULL,
    PRIMARY KEY (notification_id),
    KEY idx_notification_user (user_id),
    CONSTRAINT fk_notification_user
        FOREIGN KEY (user_id) REFERENCES users (Userid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS password_reset_token (
    resetId          BIGINT NOT NULL AUTO_INCREMENT,
    userId            BIGINT       NULL,
    token             VARCHAR(255) NULL,
    expires_at_date   DATETIME(6)  NULL,
    is_used           DATETIME(6)  NULL,
    create_at         DATETIME(6)  NULL,
    PRIMARY KEY (resetId),
    KEY idx_password_reset_token_user (userId),
    CONSTRAINT fk_password_reset_token_user
        FOREIGN KEY (userId) REFERENCES users (Userid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS call_history (
    call_id           BIGINT NOT NULL AUTO_INCREMENT,
    user_id            BIGINT      NOT NULL,
    technician_id      BIGINT      NOT NULL,
    call_status        VARCHAR(20) NOT NULL,
    started_at         DATETIME(6) NULL,
    ended_at           DATETIME(6) NULL,
    duration_seconds   INT NULL DEFAULT 0,
    created_at         DATETIME(6) NULL,
    PRIMARY KEY (call_id),
    KEY idx_call_history_user (user_id),
    KEY idx_call_history_technician (technician_id),
    CONSTRAINT fk_call_history_user
        FOREIGN KEY (user_id) REFERENCES users (Userid),
    CONSTRAINT fk_call_history_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS job (
    id                 BIGINT NOT NULL AUTO_INCREMENT,
    customer_name      VARCHAR(255)  NOT NULL,
    customer_phone     VARCHAR(255)  NOT NULL,
    customer_user_id   BIGINT        NULL,
    category           VARCHAR(255)  NOT NULL,
    description        VARCHAR(2000) NOT NULL,
    address            VARCHAR(255)  NULL,
    lat                DOUBLE        NULL,
    lng                DOUBLE        NULL,
    status             VARCHAR(20)   NOT NULL,
    booking_type       VARCHAR(20)   NULL,
    starting_price     DOUBLE        NULL,
    technician_id      BIGINT        NULL,
    created_at         DATETIME(6)   NULL,
    scheduled_at       DATETIME(6)   NULL,
    assigned_at        DATETIME(6)   NULL,
    completed_at       DATETIME(6)   NULL,
    notes              VARCHAR(2000) NULL,
    PRIMARY KEY (id),
    KEY idx_job_technician_id (technician_id),
    KEY idx_job_status (status),
    KEY idx_job_customer_user_id (customer_user_id),
    CONSTRAINT fk_job_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_job_customer_user
        FOREIGN KEY (customer_user_id) REFERENCES users (Userid)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS review (
    id                BIGINT NOT NULL AUTO_INCREMENT,
    job_id            BIGINT      NOT NULL,
    customer_user_id  BIGINT      NOT NULL,
    technician_id     BIGINT      NOT NULL,
    rating            INT         NOT NULL,
    comment           VARCHAR(1000) NULL,
    created_at        DATETIME(6) NULL,
    updated_at        DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY UQ_Review_Job (job_id),
    KEY idx_review_technician_id (technician_id),
    KEY idx_review_customer_user_id (customer_user_id),
    CONSTRAINT fk_review_job
        FOREIGN KEY (job_id) REFERENCES job (id)
        ON DELETE CASCADE,
    CONSTRAINT fk_review_customer_user
        FOREIGN KEY (customer_user_id) REFERENCES users (Userid)
        ON DELETE RESTRICT,
    CONSTRAINT fk_review_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS service_price (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    category_id     BIGINT       NOT NULL,
    starting_price  DOUBLE       NOT NULL,
    description     VARCHAR(255) NULL,
    created_at      DATETIME(6)  NULL,
    updated_at      DATETIME(6)  NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_service_price_category (category_id),
    CONSTRAINT fk_service_price_category
        FOREIGN KEY (category_id) REFERENCES category (category_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS service_quote (
    id               BIGINT NOT NULL AUTO_INCREMENT,
    job_id           BIGINT       NOT NULL,
    technician_id    BIGINT       NOT NULL,
    version          INT          NOT NULL,
    inspection_fee   DOUBLE       NOT NULL DEFAULT 0,
    labor_cost       DOUBLE       NOT NULL DEFAULT 0,
    parts_cost       DOUBLE       NOT NULL DEFAULT 0,
    travel_fee       DOUBLE       NOT NULL DEFAULT 0,
    total_amount     DOUBLE       NOT NULL DEFAULT 0,
    reason           VARCHAR(500) NULL,
    status           VARCHAR(20)  NOT NULL,
    created_at       DATETIME(6)  NULL,
    updated_at       DATETIME(6)  NULL,
    PRIMARY KEY (id),
    KEY idx_service_quote_job_id (job_id),
    KEY idx_service_quote_technician_id (technician_id),
    CONSTRAINT fk_service_quote_job
        FOREIGN KEY (job_id) REFERENCES job (id)
        ON DELETE CASCADE,
    CONSTRAINT fk_service_quote_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Not in camfix_schema.sql's addendum (added after it was written) - backs
-- com.api.entity.ChatMessage / ChatService, one row per chat message on a job.
CREATE TABLE IF NOT EXISTS chat_message (
    id                BIGINT NOT NULL AUTO_INCREMENT,
    job_id            BIGINT       NOT NULL,
    sender_user_id    BIGINT       NOT NULL,
    text              VARCHAR(2000) NOT NULL,
    created_at        DATETIME(6)  NULL,
    PRIMARY KEY (id),
    KEY idx_chat_message_job (job_id),
    KEY idx_chat_message_sender (sender_user_id),
    CONSTRAINT fk_chat_message_job
        FOREIGN KEY (job_id) REFERENCES job (id)
        ON DELETE CASCADE,
    CONSTRAINT fk_chat_message_sender
        FOREIGN KEY (sender_user_id) REFERENCES users (Userid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
