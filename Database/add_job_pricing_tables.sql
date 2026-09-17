-- Adds the three tables the backend's entities expect but that camfix never
-- had: job, service_price, service_quote (see com.api.entity.Job /
-- ServicePrice / ServiceQuote). ddl-auto=none, so Hibernate never creates
-- them itself; every endpoint touching one 500s with "table doesn't exist"
-- until this runs.
--
-- Column names/types/nullability are taken directly from the @Column
-- annotations on each entity (naming strategy is PhysicalNamingStrategyStandardImpl,
-- so those names are used verbatim - no camelCase conversion to account for).
-- CREATE TABLE IF NOT EXISTS makes this safe to re-run.
--
-- Run against the `camfix` schema (the only one this project's
-- application.properties points at):
--   mysql -u root -p camfix < add_job_pricing_tables.sql

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
