/* =====================================================================
   CamFix — Complete Database Schema with Relations (MySQL 8.0)

   21 tables, all foreign keys declared. Column names/types are taken
   from the current com.api.entity.* classes (the backend's source of
   truth; naming strategy is PhysicalNamingStrategyStandardImpl, so names
   are used verbatim). Tables are created in dependency order so every
   FOREIGN KEY target exists before it is referenced.

   Use this on a FRESH, empty database only:
       mysql -u root -p < camfix_database.sql
   It is not a migration for an existing CamFix schema that holds data.
   Full documentation: database.docx (same folder).
   ===================================================================== */

CREATE DATABASE IF NOT EXISTS CamFix
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE CamFix;

/* ---------------------------------------------------------------------
   1. users — every account: CUSTOMER, TECHNICIAN or ADMIN
   --------------------------------------------------------------------- */
CREATE TABLE users (
    Userid         BIGINT       NOT NULL AUTO_INCREMENT,
    Full_name      VARCHAR(50)  NOT NULL,
    Last_name      VARCHAR(50)  NOT NULL,
    DateofBirth    DATE         NULL,
    Email          VARCHAR(100) NOT NULL,
    Phone_number   VARCHAR(100) NOT NULL,
    Password_hash  VARCHAR(100) NOT NULL,
    Profile_image  VARCHAR(500) NULL,
    ROLE           VARCHAR(20)  NOT NULL,          -- CUSTOMER | TECHNICIAN | ADMIN
    STATUS         VARCHAR(20)  NOT NULL,          -- ACTIVE | SUSPENDED
    created_at     DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at     DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (Userid),
    UNIQUE KEY uq_users_email (Email),
    UNIQUE KEY uq_users_phone (Phone_number)
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   2. category — repair categories a technician belongs to
   --------------------------------------------------------------------- */
CREATE TABLE category (
    category_id    BIGINT       NOT NULL AUTO_INCREMENT,
    categoryName   VARCHAR(100) NOT NULL,
    description    VARCHAR(500) NULL,
    icon           VARCHAR(255) NULL,
    PRIMARY KEY (category_id),
    UNIQUE KEY uq_category_name (categoryName)
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   3. service_category — standalone catalogue used by ServiceCategory
      entity (no foreign keys in or out)
   --------------------------------------------------------------------- */
CREATE TABLE service_category (
    serviceCategoryId  BIGINT       NOT NULL AUTO_INCREMENT,
    categoryName       VARCHAR(255) NULL,
    description        VARCHAR(255) NULL,
    icon               VARCHAR(255) NULL,
    create_at          TIMESTAMP    NULL,
    update_at          TIMESTAMP    NULL,
    PRIMARY KEY (serviceCategoryId)
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   4. technician — technician profile, 1:1 with users
   --------------------------------------------------------------------- */
CREATE TABLE technician (
    technician_id            BIGINT       NOT NULL AUTO_INCREMENT,
    user_id                  BIGINT       NOT NULL,
    category_id              BIGINT       NOT NULL,
    business_name            VARCHAR(255) NOT NULL,
    experience_year          INT          NOT NULL,
    description              VARCHAR(500) NULL,
    average_rating           DECIMAL(3,2) NULL,
    verified                 BIT          NOT NULL DEFAULT 0,
    availability_status      VARCHAR(20)  NULL,    -- AVAILABLE | ONLINE | OFFLINE
    approval_status          VARCHAR(20)  NULL,    -- PENDING | APPROVED | REJECTED
    approved_at              DATETIME(6)  NULL,
    rejection_reason         VARCHAR(500) NULL,
    service_area             VARCHAR(255) NULL,
    opening_hours            VARCHAR(255) NULL,
    rating_count             INT          NULL,
    photo                    LONGBLOB     NULL,
    photo_content_type       VARCHAR(100) NULL,
    banner                   LONGBLOB     NULL,
    banner_content_type      VARCHAR(100) NULL,
    banner_title             VARCHAR(120) NULL,
    id_card                  LONGBLOB     NULL,
    face_photo               LONGBLOB     NULL,
    identity_email_verified  BIT          NOT NULL DEFAULT 0,
    created_at               DATETIME(6)  NOT NULL,
    updated_at               DATETIME(6)  NOT NULL,
    PRIMARY KEY (technician_id),
    UNIQUE KEY uq_technician_user (user_id),
    KEY idx_technician_category (category_id),
    CONSTRAINT fk_technician_user
        FOREIGN KEY (user_id) REFERENCES users (Userid),
    CONSTRAINT fk_technician_category
        FOREIGN KEY (category_id) REFERENCES category (category_id)
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   5. user_addresses — saved addresses of a customer (1:N)
   --------------------------------------------------------------------- */
CREATE TABLE user_addresses (
    AddressID      BIGINT       NOT NULL AUTO_INCREMENT,
    userId         BIGINT       NULL,
    address_Name   VARCHAR(255) NULL,
    address_Line   VARCHAR(255) NULL,
    city           VARCHAR(255) NULL,
    province       VARCHAR(255) NULL,
    latitude       DOUBLE       NULL,
    longitude      DOUBLE       NULL,
    Is_Default     BIT          NULL DEFAULT 0,
    PRIMARY KEY (AddressID),
    KEY idx_user_addresses_user (userId),
    CONSTRAINT fk_user_addresses_user
        FOREIGN KEY (userId) REFERENCES users (Userid)
        ON DELETE CASCADE
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   6. technician_addresses — shop / business addresses (1:N)
   --------------------------------------------------------------------- */
CREATE TABLE technician_addresses (
    AddressID      BIGINT       NOT NULL AUTO_INCREMENT,
    technician_id  BIGINT       NULL,
    business_name  VARCHAR(255) NULL,
    address_line   VARCHAR(255) NULL,
    city           VARCHAR(255) NULL,
    province       VARCHAR(255) NULL,
    latitude       DOUBLE       NULL,
    longitude      DOUBLE       NULL,
    is_default     BIT          NULL,
    create_at      DATETIME(6)  NULL,
    update_at      DATETIME(6)  NULL,
    PRIMARY KEY (AddressID),
    KEY idx_technician_addresses_technician (technician_id),
    CONSTRAINT fk_technician_addresses_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   7. technician_live_locations — latest GPS fix, 1:1 with technician
   --------------------------------------------------------------------- */
CREATE TABLE technician_live_locations (
    id             BIGINT      NOT NULL AUTO_INCREMENT,
    technician_id  BIGINT      NOT NULL,
    latitude       DOUBLE      NOT NULL,
    longitude      DOUBLE      NOT NULL,
    accuracy       DOUBLE      NULL,
    created_at     DATETIME(6) NULL,
    last_update    DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_technician_live_locations_technician (technician_id),
    KEY idx_tech_location_last_update (last_update),
    CONSTRAINT fk_technician_live_locations_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   8. technician_service — services a technician lists with a price (1:N)
   --------------------------------------------------------------------- */
CREATE TABLE technician_service (
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

/* ---------------------------------------------------------------------
   9. technician_service_photo — photo of a listing, 1:1 (shared PK)
   --------------------------------------------------------------------- */
CREATE TABLE technician_service_photo (
    listing_id    BIGINT       NOT NULL,
    data          LONGBLOB     NOT NULL,
    content_type  VARCHAR(100) NOT NULL,
    PRIMARY KEY (listing_id),
    CONSTRAINT fk_technician_service_photo_listing
        FOREIGN KEY (listing_id) REFERENCES technician_service (id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   10. service_price — default starting price per category, 1:1
   --------------------------------------------------------------------- */
CREATE TABLE service_price (
    id              BIGINT       NOT NULL AUTO_INCREMENT,
    category_id     BIGINT       NOT NULL,
    starting_price  DOUBLE       NOT NULL,
    description     VARCHAR(255) NULL,
    bench_fee       DOUBLE       NULL,
    travel_fee      DOUBLE       NULL,
    created_at      DATETIME(6)  NULL,
    updated_at      DATETIME(6)  NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_service_price_category (category_id),
    CONSTRAINT fk_service_price_category
        FOREIGN KEY (category_id) REFERENCES category (category_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   11. favorites — customer ↔ technician bookmark (M:N junction)
   --------------------------------------------------------------------- */
CREATE TABLE favorites (
    FavoriteID     BIGINT      NOT NULL AUTO_INCREMENT,
    UserID         BIGINT      NOT NULL,
    TechnicianID   BIGINT      NOT NULL,
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
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   12. password_reset_token — reset / OTP tokens (1:N from users)
   --------------------------------------------------------------------- */
CREATE TABLE password_reset_token (
    resetId          BIGINT       NOT NULL AUTO_INCREMENT,
    userId           BIGINT       NULL,
    token            VARCHAR(255) NULL,
    expires_at_date  DATETIME(6)  NULL,
    is_used          DATETIME(6)  NULL,          -- time the token was used; NULL = unused
    create_at        DATETIME(6)  NULL,
    PRIMARY KEY (resetId),
    KEY idx_password_reset_token_user (userId),
    CONSTRAINT fk_password_reset_token_user
        FOREIGN KEY (userId) REFERENCES users (Userid)
        ON DELETE CASCADE
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   13. call_history — in-app calls customer → technician
   --------------------------------------------------------------------- */
CREATE TABLE call_history (
    CallID            BIGINT      NOT NULL AUTO_INCREMENT,
    user_id           BIGINT      NOT NULL,
    technician_id     BIGINT      NOT NULL,
    call_status       VARCHAR(20) NOT NULL,     -- ONGOING | COMPLETED
    started_at        DATETIME(6) NULL,
    ended_at          DATETIME(6) NULL,
    duration_seconds  INT         NULL DEFAULT 0,
    created_at        DATETIME(6) NULL,
    PRIMARY KEY (CallID),
    KEY idx_call_history_user (user_id),
    KEY idx_call_history_technician (technician_id),
    CONSTRAINT fk_call_history_user
        FOREIGN KEY (user_id) REFERENCES users (Userid),
    CONSTRAINT fk_call_history_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   14. job — a booking / repair request (the central table)
   --------------------------------------------------------------------- */
CREATE TABLE job (
    id                     BIGINT        NOT NULL AUTO_INCREMENT,
    customer_name          VARCHAR(255)  NOT NULL,
    customer_phone         VARCHAR(255)  NOT NULL,
    customer_user_id       BIGINT        NULL,
    category               VARCHAR(255)  NOT NULL,   -- category name (text copy)
    description            VARCHAR(2000) NOT NULL,
    address                VARCHAR(255)  NULL,
    lat                    DOUBLE        NULL,
    lng                    DOUBLE        NULL,
    status                 VARCHAR(20)   NOT NULL,   -- REQUESTED | ASSIGNED | ON_THE_WAY | ARRIVED
                                                     -- | QUOTE_PENDING | IN_PROGRESS | COMPLETED | CANCELLED
    bench_fee              DOUBLE        NULL,
    booking_type           VARCHAR(20)   NULL,       -- IMMEDIATE | SCHEDULED | SELF_DROP
    starting_price         DOUBLE        NULL,
    technician_id          BIGINT        NULL,
    technician_service_id  BIGINT        NULL,
    created_at             DATETIME(6)   NULL,
    scheduled_at           DATETIME(6)   NULL,
    assigned_at            DATETIME(6)   NULL,
    completed_at           DATETIME(6)   NULL,
    notes                  VARCHAR(2000) NULL,
    PRIMARY KEY (id),
    KEY idx_job_status (status),
    KEY idx_job_customer_user_id (customer_user_id),
    KEY idx_job_technician_id (technician_id),
    KEY idx_job_technician_service_id (technician_service_id),
    CONSTRAINT fk_job_customer_user
        FOREIGN KEY (customer_user_id) REFERENCES users (Userid)
        ON DELETE SET NULL,
    CONSTRAINT fk_job_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_job_technician_service
        FOREIGN KEY (technician_service_id) REFERENCES technician_service (id)
        ON DELETE SET NULL
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   15. service_quote — technician's price quote for a job (versioned)
   --------------------------------------------------------------------- */
CREATE TABLE service_quote (
    id              BIGINT       NOT NULL AUTO_INCREMENT,
    job_id          BIGINT       NOT NULL,
    technician_id   BIGINT       NOT NULL,
    version         INT          NOT NULL,
    inspection_fee  DOUBLE       NOT NULL DEFAULT 0,
    labor_cost      DOUBLE       NOT NULL DEFAULT 0,
    parts_cost      DOUBLE       NOT NULL DEFAULT 0,
    travel_fee      DOUBLE       NOT NULL DEFAULT 0,
    total_amount    DOUBLE       NOT NULL DEFAULT 0,
    reason          VARCHAR(500) NULL,
    status          VARCHAR(20)  NOT NULL,       -- PENDING | REVISED | ACCEPTED | REJECTED
    created_at      DATETIME(6)  NULL,
    updated_at      DATETIME(6)  NULL,
    PRIMARY KEY (id),
    KEY idx_service_quote_job_id (job_id),
    KEY idx_service_quote_technician_id (technician_id),
    CONSTRAINT fk_service_quote_job
        FOREIGN KEY (job_id) REFERENCES job (id)
        ON DELETE CASCADE,
    CONSTRAINT fk_service_quote_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   16. quote_item — line items of a quote (1:N)
   --------------------------------------------------------------------- */
CREATE TABLE quote_item (
    id           BIGINT       NOT NULL AUTO_INCREMENT,
    quote_id     BIGINT       NOT NULL,
    title        VARCHAR(120) NOT NULL,
    price        DOUBLE       NOT NULL,
    note         VARCHAR(300) NULL,
    recommended  BIT          NOT NULL DEFAULT 0,
    approved     BIT          NULL,              -- NULL = customer hasn't decided
    PRIMARY KEY (id),
    KEY idx_quote_item_quote (quote_id),
    CONSTRAINT fk_quote_item_quote
        FOREIGN KEY (quote_id) REFERENCES service_quote (id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   17. payment — completed payment for an accepted quote (1:1 quote)
   --------------------------------------------------------------------- */
CREATE TABLE payment (
    id              BIGINT      NOT NULL AUTO_INCREMENT,
    job_id          BIGINT      NOT NULL,
    quote_id        BIGINT      NOT NULL,
    base_amount     DOUBLE      NOT NULL,
    platform_fee    DOUBLE      NOT NULL,
    tax_amount      DOUBLE      NOT NULL,
    total_amount    DOUBLE      NOT NULL,
    payment_method  VARCHAR(20) NOT NULL,        -- APPLE_PAY | CARD | PAYPAL | KHQR
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

/* ---------------------------------------------------------------------
   18. khqr_payment — Bakong KHQR code generated for a quote
   --------------------------------------------------------------------- */
CREATE TABLE khqr_payment (
    id           BIGINT       NOT NULL AUTO_INCREMENT,
    job_id       BIGINT       NOT NULL,
    quote_id     BIGINT       NOT NULL,
    md5          VARCHAR(32)  NOT NULL,
    qr_string    VARCHAR(600) NOT NULL,
    amount       DOUBLE       NOT NULL,
    status       VARCHAR(10)  NOT NULL,          -- PENDING | PAID | EXPIRED | CANCELLED
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

/* ---------------------------------------------------------------------
   19. review — customer rating of a finished job (1:1 with job)
   --------------------------------------------------------------------- */
CREATE TABLE review (
    id                BIGINT        NOT NULL AUTO_INCREMENT,
    job_id            BIGINT        NOT NULL,
    customer_user_id  BIGINT        NOT NULL,
    technician_id     BIGINT        NOT NULL,
    rating            INT           NOT NULL,
    comment           VARCHAR(1000) NULL,
    created_at        DATETIME(6)   NULL,
    updated_at        DATETIME(6)   NULL,
    PRIMARY KEY (id),
    UNIQUE KEY UQ_Review_Job (job_id),
    KEY idx_review_customer_user_id (customer_user_id),
    KEY idx_review_technician_id (technician_id),
    CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT fk_review_job
        FOREIGN KEY (job_id) REFERENCES job (id)
        ON DELETE CASCADE,
    CONSTRAINT fk_review_customer_user
        FOREIGN KEY (customer_user_id) REFERENCES users (Userid)
        ON DELETE RESTRICT,
    CONSTRAINT fk_review_technician
        FOREIGN KEY (technician_id) REFERENCES technician (technician_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   20. chat_message — chat between customer and technician on a job
   --------------------------------------------------------------------- */
CREATE TABLE chat_message (
    id              BIGINT        NOT NULL AUTO_INCREMENT,
    job_id          BIGINT        NOT NULL,
    sender_user_id  BIGINT        NOT NULL,
    sender_role     VARCHAR(12)   NOT NULL,      -- CUSTOMER | TECHNICIAN
    text            VARCHAR(2000) NOT NULL,
    created_at      DATETIME(6)   NOT NULL,
    read_at         DATETIME(6)   NULL,
    PRIMARY KEY (id),
    KEY idx_chat_message_job (job_id),
    KEY idx_chat_message_sender (sender_user_id),
    CONSTRAINT fk_chat_message_job
        FOREIGN KEY (job_id) REFERENCES job (id)
        ON DELETE CASCADE,
    CONSTRAINT fk_chat_message_sender
        FOREIGN KEY (sender_user_id) REFERENCES users (Userid)
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   21. notification — in-app notifications (EN + Khmer text)
   --------------------------------------------------------------------- */
CREATE TABLE notification (
    notification_id  BIGINT       NOT NULL AUTO_INCREMENT,
    user_id          BIGINT       NOT NULL,
    title            VARCHAR(150) NOT NULL,
    message          TEXT         NOT NULL,
    title_km         VARCHAR(150) NULL,
    message_km       TEXT         NULL,
    type             VARCHAR(40)  NULL,          -- BOOKING_REQUESTED, JOB_ASSIGNED, QUOTE_SUBMITTED, ...
    job_id           BIGINT       NULL,
    is_read          BIT          NULL DEFAULT 0,
    created_at       DATETIME(6)  NULL,
    PRIMARY KEY (notification_id),
    KEY idx_notification_user (user_id),
    KEY idx_notification_job (job_id),
    CONSTRAINT fk_notification_user
        FOREIGN KEY (user_id) REFERENCES users (Userid)
        ON DELETE CASCADE,
    CONSTRAINT fk_notification_job
        FOREIGN KEY (job_id) REFERENCES job (id)
        ON DELETE SET NULL
) ENGINE=InnoDB;
