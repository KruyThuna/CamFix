-- Adds the fourth table missing from camfix: review (see com.api.entity.Review).
-- Confirmed live: GET /api/technicians/{id}/reviews 500'd with
-- "Table 'camfix.review' doesn't exist" before this ran.
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
    UNIQUE KEY `UQ_Review_Job` (job_id),
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
