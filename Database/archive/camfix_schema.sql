/* =====================================================================
   CamFix — SQL Server Database Schema
   Student project: technician-finder app (Cambodia)
   Engine target : Microsoft SQL Server 2019+ / Azure SQL
   Tables        : 15 (see creation order below — resolves FK dependencies)
   Author note   : all timestamps use SYSUTCDATETIME() (UTC); convert to
                    Asia/Phnom_Penh (UTC+7) in the application layer.

   NOT what's deployed: the backend actually runs on MySQL, with different
   table/column names throughout. See the ADDENDUM at the end of this file
   before running anything here against the project's real database.
   ===================================================================== */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =====================================================================
   1. Service_Categories  — no dependencies
   ===================================================================== */
CREATE TABLE Service_Categories (
    CategoryID      INT IDENTITY(1,1)   PRIMARY KEY,
    Category_Name   NVARCHAR(100)       NOT NULL,
    Description     NVARCHAR(255)       NULL,
    Is_Active       BIT                 NOT NULL DEFAULT (1),
    Created_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT UQ_ServiceCategories_Name UNIQUE (Category_Name)
);
GO

/* =====================================================================
   2. Users  — no dependencies
   ===================================================================== */
CREATE TABLE Users (
    UserID          BIGINT IDENTITY(1,1) PRIMARY KEY,
    Full_Name       NVARCHAR(100)       NOT NULL,
    Last_Name       NVARCHAR(100)       NOT NULL,
    DateOfBirth     DATE                NULL,
    Email           VARCHAR(255)        NOT NULL,
    Phone_Number    VARCHAR(20)         NOT NULL,
    Password_Hash   VARCHAR(255)        NOT NULL,
    Profile_Image   VARCHAR(500)        NULL,
    Role            VARCHAR(20)         NOT NULL,
    Status          VARCHAR(20)         NOT NULL DEFAULT ('ACTIVE'),
    Created_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    Updated_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT UQ_Users_Email  UNIQUE (Email),
    CONSTRAINT UQ_Users_Phone  UNIQUE (Phone_Number),
    CONSTRAINT CK_Users_Role   CHECK (Role IN ('CUSTOMER','TECHNICIAN','ADMIN')),
    CONSTRAINT CK_Users_Status CHECK (Status IN ('ACTIVE','SUSPENDED','DELETED'))
);
GO

/* =====================================================================
   3. Technicians  — depends on Users, Service_Categories
      1:1 with Users  → enforced by UNIQUE(UserID)
   ===================================================================== */
CREATE TABLE Technicians (
    TechnicianID     BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID           BIGINT              NOT NULL,
    CategoryID       INT                 NOT NULL,
    Business_Name    NVARCHAR(150)       NULL,
    Description      NVARCHAR(1000)      NULL,
    Experience_Years TINYINT             NOT NULL DEFAULT (0),
    Average_Rating   DECIMAL(3,2)        NOT NULL DEFAULT (0.00),
    Is_Verified      BIT                 NOT NULL DEFAULT (0),
    Created_At       DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    Updated_At       DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT UQ_Technicians_UserID UNIQUE (UserID),
    CONSTRAINT FK_Technicians_Users
        FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Technicians_Category
        FOREIGN KEY (CategoryID) REFERENCES Service_Categories(CategoryID),
    CONSTRAINT CK_Technicians_Experience CHECK (Experience_Years >= 0),
    CONSTRAINT CK_Technicians_Rating CHECK (Average_Rating BETWEEN 0 AND 5)
);
GO

/* =====================================================================
   4. Service_Prices  — depends on Service_Categories
      One standard "starting price" row per category (1:1).
   ===================================================================== */
CREATE TABLE Service_Prices (
    PriceID         INT IDENTITY(1,1)   PRIMARY KEY,
    CategoryID      INT                 NOT NULL,
    Starting_Price  DECIMAL(10,2)       NOT NULL,
    Description     NVARCHAR(255)       NULL,
    Created_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    Updated_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT UQ_ServicePrices_Category UNIQUE (CategoryID),
    CONSTRAINT FK_ServicePrices_Category
        FOREIGN KEY (CategoryID) REFERENCES Service_Categories(CategoryID),
    CONSTRAINT CK_ServicePrices_Amount CHECK (Starting_Price >= 0)
);
GO

/* =====================================================================
   5. User_Addresses  — depends on Users
   ===================================================================== */
CREATE TABLE User_Addresses (
    AddressID       BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID          BIGINT              NOT NULL,
    Address_Name    VARCHAR(50)         NOT NULL,
    Address_Line    NVARCHAR(255)       NOT NULL,
    City            NVARCHAR(100)       NOT NULL,
    Province        NVARCHAR(100)       NOT NULL,
    Latitude        DECIMAL(9,6)        NULL,
    Longitude       DECIMAL(9,6)        NULL,
    Is_Default      BIT                 NOT NULL DEFAULT (0),
    Created_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    Updated_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_UserAddresses_Users
        FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    CONSTRAINT CK_UserAddresses_Lat CHECK (Latitude  BETWEEN -90  AND 90),
    CONSTRAINT CK_UserAddresses_Lng CHECK (Longitude BETWEEN -180 AND 180)
);
GO
-- at most one default address per user
CREATE UNIQUE INDEX UQ_UserAddresses_OneDefault
    ON User_Addresses(UserID) WHERE Is_Default = 1;
GO

/* =====================================================================
   6. Technician_Addresses  — depends on Technicians
   ===================================================================== */
CREATE TABLE Technician_Addresses (
    AddressID       BIGINT IDENTITY(1,1) PRIMARY KEY,
    TechnicianID    BIGINT              NOT NULL,
    Address_Name    VARCHAR(50)         NOT NULL,
    Address_Line    NVARCHAR(255)       NOT NULL,
    City            NVARCHAR(100)       NOT NULL,
    Province        NVARCHAR(100)       NOT NULL,
    Latitude        DECIMAL(9,6)        NULL,
    Longitude       DECIMAL(9,6)        NULL,
    Is_Default      BIT                 NOT NULL DEFAULT (0),
    Created_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    Updated_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_TechAddresses_Technicians
        FOREIGN KEY (TechnicianID) REFERENCES Technicians(TechnicianID) ON DELETE CASCADE,
    CONSTRAINT CK_TechAddresses_Lat CHECK (Latitude  BETWEEN -90  AND 90),
    CONSTRAINT CK_TechAddresses_Lng CHECK (Longitude BETWEEN -180 AND 180)
);
GO
CREATE UNIQUE INDEX UQ_TechAddresses_OneDefault
    ON Technician_Addresses(TechnicianID) WHERE Is_Default = 1;
GO

/* =====================================================================
   7. User_live_locations  — depends on Users (1:1, PK = FK)
   ===================================================================== */
CREATE TABLE User_live_locations (
    UserID          BIGINT              PRIMARY KEY,
    Latitude        DECIMAL(9,6)        NOT NULL,
    Longitude       DECIMAL(9,6)        NOT NULL,
    Accuracy        DECIMAL(6,2)        NULL,
    Last_Update     DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_UserLiveLoc_Users
        FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    CONSTRAINT CK_UserLiveLoc_Lat CHECK (Latitude  BETWEEN -90  AND 90),
    CONSTRAINT CK_UserLiveLoc_Lng CHECK (Longitude BETWEEN -180 AND 180)
);
GO

/* =====================================================================
   8. Technician_live_locations  — depends on Technicians (1:1, PK = FK)
   ===================================================================== */
CREATE TABLE Technician_live_locations (
    TechnicianID    BIGINT              PRIMARY KEY,
    Latitude        DECIMAL(9,6)        NOT NULL,
    Longitude       DECIMAL(9,6)        NOT NULL,
    Accuracy        DECIMAL(6,2)        NULL,
    Last_Update     DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_TechLiveLoc_Technicians
        FOREIGN KEY (TechnicianID) REFERENCES Technicians(TechnicianID) ON DELETE CASCADE,
    CONSTRAINT CK_TechLiveLoc_Lat CHECK (Latitude  BETWEEN -90  AND 90),
    CONSTRAINT CK_TechLiveLoc_Lng CHECK (Longitude BETWEEN -180 AND 180)
);
GO

/* =====================================================================
   9. Favorites  — depends on Users, Technicians (M:N junction)
   ===================================================================== */
CREATE TABLE Favorites (
    UserID          BIGINT              NOT NULL,
    TechnicianID    BIGINT              NOT NULL,
    Created_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Favorites PRIMARY KEY (UserID, TechnicianID),
    CONSTRAINT FK_Favorites_Users
        FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Favorites_Technicians
        FOREIGN KEY (TechnicianID) REFERENCES Technicians(TechnicianID)
);
GO
-- reverse lookup: "who has favorited this technician"
CREATE INDEX IX_Favorites_Technician ON Favorites(TechnicianID);
GO

/* =====================================================================
   10. Bookings  — depends on Users, Technicians, Service_Categories,
       User_Addresses
   ===================================================================== */
CREATE TABLE Bookings (
    BookingID           BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID              BIGINT              NOT NULL,
    TechnicianID        BIGINT              NULL,   -- NULL while unassigned
    CategoryID          INT                 NOT NULL,
    AddressID           BIGINT              NOT NULL,
    Problem_Description NVARCHAR(1000)      NULL,
    Booking_Date        DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    Booking_Status      VARCHAR(20)         NOT NULL DEFAULT ('PENDING'),
    Starting_Price      DECIMAL(10,2)       NOT NULL,
    Created_At          DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    Updated_At          DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Bookings_Users
        FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Bookings_Technicians
        FOREIGN KEY (TechnicianID) REFERENCES Technicians(TechnicianID),
    CONSTRAINT FK_Bookings_Category
        FOREIGN KEY (CategoryID) REFERENCES Service_Categories(CategoryID),
    CONSTRAINT FK_Bookings_Address
        FOREIGN KEY (AddressID) REFERENCES User_Addresses(AddressID),
    CONSTRAINT CK_Bookings_Status CHECK (Booking_Status IN
        ('PENDING','CONFIRMED','IN_PROGRESS','QUOTE_PENDING','COMPLETED','CANCELLED','REJECTED')),
    CONSTRAINT CK_Bookings_StartingPrice CHECK (Starting_Price >= 0)
);
GO
CREATE INDEX IX_Bookings_User        ON Bookings(UserID);
CREATE INDEX IX_Bookings_Technician  ON Bookings(TechnicianID);
CREATE INDEX IX_Bookings_Category    ON Bookings(CategoryID);
CREATE INDEX IX_Bookings_Status_Date ON Bookings(Booking_Status, Booking_Date);
GO

/* =====================================================================
   11. Reviews  — depends on Users, Technicians, Bookings (optional)
   ===================================================================== */
CREATE TABLE Reviews (
    ReviewID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID          BIGINT              NOT NULL,
    TechnicianID    BIGINT              NOT NULL,
    BookingID       BIGINT              NULL,   -- recommended addition, see notes
    Rating          TINYINT             NOT NULL,
    Comment         NVARCHAR(1000)      NULL,
    Created_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Reviews_Users
        FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Reviews_Technicians
        FOREIGN KEY (TechnicianID) REFERENCES Technicians(TechnicianID),
    CONSTRAINT FK_Reviews_Bookings
        FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID),
    CONSTRAINT CK_Reviews_Rating CHECK (Rating BETWEEN 1 AND 5),
    CONSTRAINT UQ_Reviews_OnePerBooking UNIQUE (BookingID)
);
GO
CREATE INDEX IX_Reviews_Technician ON Reviews(TechnicianID);
CREATE INDEX IX_Reviews_User       ON Reviews(UserID);
GO

/* =====================================================================
   12. Call_History  — depends on Users, Technicians
   ===================================================================== */
CREATE TABLE Call_History (
    CallID           BIGINT IDENTITY(1,1) PRIMARY KEY,
    CallerID         BIGINT              NOT NULL,
    TechnicianID     BIGINT              NOT NULL,
    Started_At       DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    Ended_At         DATETIME2           NULL,
    Duration_Seconds AS (DATEDIFF(SECOND, Started_At, Ended_At)) PERSISTED,
    CONSTRAINT FK_CallHistory_Caller
        FOREIGN KEY (CallerID) REFERENCES Users(UserID),
    CONSTRAINT FK_CallHistory_Technician
        FOREIGN KEY (TechnicianID) REFERENCES Technicians(TechnicianID),
    CONSTRAINT CK_CallHistory_Timing CHECK (Ended_At IS NULL OR Ended_At >= Started_At)
);
GO
CREATE INDEX IX_CallHistory_Caller     ON Call_History(CallerID);
CREATE INDEX IX_CallHistory_Technician ON Call_History(TechnicianID);
GO

/* =====================================================================
   13. Notifications  — depends on Users
   ===================================================================== */
CREATE TABLE Notifications (
    NotificationID    BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID            BIGINT              NOT NULL,
    Title             NVARCHAR(150)       NOT NULL,
    Message           NVARCHAR(1000)      NOT NULL,
    Notification_Type VARCHAR(30)         NOT NULL,
    Is_Read           BIT                 NOT NULL DEFAULT (0),
    Created_At        DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Notifications_Users
        FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT CK_Notifications_Type CHECK (Notification_Type IN
        ('BOOKING_UPDATE','QUOTE_UPDATE','SYSTEM','GENERAL'))
);
GO
CREATE INDEX IX_Notifications_User_Unread ON Notifications(UserID, Is_Read, Created_At);
GO

/* =====================================================================
   14. Password_Reset_Tokens  — depends on Users
   ===================================================================== */
CREATE TABLE Password_Reset_Tokens (
    TokenID         BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID          BIGINT              NOT NULL,
    Token           VARCHAR(255)        NOT NULL,
    Expires_At      DATETIME2           NOT NULL,
    Is_Used         BIT                 NOT NULL DEFAULT (0),
    Created_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_PasswordReset_Users
        FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT UQ_PasswordReset_Token UNIQUE (Token)
);
GO
CREATE INDEX IX_PasswordReset_User ON Password_Reset_Tokens(UserID);
GO

/* =====================================================================
   15. Service_Quotes  — depends on Bookings, Technicians
   ===================================================================== */
CREATE TABLE Service_Quotes (
    QuoteID         BIGINT IDENTITY(1,1) PRIMARY KEY,
    BookingID       BIGINT              NOT NULL,
    TechnicianID    BIGINT              NOT NULL,
    Version         INT                 NOT NULL,
    Inspection_Fee  DECIMAL(10,2)       NOT NULL DEFAULT (0),
    Labor_Cost      DECIMAL(10,2)       NOT NULL DEFAULT (0),
    Parts_Cost      DECIMAL(10,2)       NOT NULL DEFAULT (0),
    Travel_Fee      DECIMAL(10,2)       NOT NULL DEFAULT (0),
    Total_Amount    AS (Inspection_Fee + Labor_Cost + Parts_Cost + Travel_Fee) PERSISTED,
    Reason          NVARCHAR(500)       NULL,
    Quote_Status    VARCHAR(20)         NOT NULL DEFAULT ('PENDING'),
    Created_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    Updated_At      DATETIME2           NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_ServiceQuotes_Bookings
        FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID),
    CONSTRAINT FK_ServiceQuotes_Technicians
        FOREIGN KEY (TechnicianID) REFERENCES Technicians(TechnicianID),
    CONSTRAINT CK_ServiceQuotes_Version CHECK (Version >= 1),
    CONSTRAINT CK_ServiceQuotes_Fees CHECK (
        Inspection_Fee >= 0 AND Labor_Cost >= 0 AND Parts_Cost >= 0 AND Travel_Fee >= 0),
    CONSTRAINT CK_ServiceQuotes_Status CHECK (Quote_Status IN
        ('PENDING','ACCEPTED','REJECTED','REVISED','EXPIRED')),
    CONSTRAINT UQ_ServiceQuotes_BookingVersion UNIQUE (BookingID, Version)
);
GO
-- a booking may have at most one ACCEPTED quote
CREATE UNIQUE INDEX UQ_ServiceQuotes_OneAccepted
    ON Service_Quotes(BookingID) WHERE Quote_Status = 'ACCEPTED';
CREATE INDEX IX_ServiceQuotes_Booking    ON Service_Quotes(BookingID);
CREATE INDEX IX_ServiceQuotes_Technician ON Service_Quotes(TechnicianID);
GO


/* =====================================================================
   SAMPLE DATA — golden-path walkthrough for one booking end to end
   ===================================================================== */

INSERT INTO Service_Categories (Category_Name, Description) VALUES
    (N'Air Conditioner', N'AC installation, repair and servicing'),
    (N'Motorcycle',       N'Motorcycle repair and maintenance'),
    (N'Car',              N'Car repair and maintenance'),
    (N'Plumbing',         N'Pipes, leaks, water heaters'),
    (N'Electrical',       N'Home electrical repair and wiring');
GO

INSERT INTO Service_Prices (CategoryID, Starting_Price, Description) VALUES
    (1, 10.00, N'AC Repair — starting from $10'),
    (2, 5.00,  N'Motorcycle Repair — starting from $5'),
    (3, 15.00, N'Car Repair — starting from $15'),
    (4, 5.00,  N'Plumbing — starting from $5'),
    (5, 5.00,  N'Electrical — starting from $5');
GO

INSERT INTO Users (Full_Name, Last_Name, Email, Phone_Number, Password_Hash, Role) VALUES
    (N'Sokha',  N'Chan',  'sokha.customer@camfix.kh',   '+85512345678', 'HASH_PLACEHOLDER_1', 'CUSTOMER'),
    (N'Dara',   N'Pich',  'dara.tech@camfix.kh',        '+855987654321', 'HASH_PLACEHOLDER_2', 'TECHNICIAN'),
    (N'Admin',  N'User',  'admin@camfix.kh',            '+855700000000', 'HASH_PLACEHOLDER_3', 'ADMIN');
GO

INSERT INTO Technicians (UserID, CategoryID, Business_Name, Description, Experience_Years, Is_Verified) VALUES
    (2, 1, N'Dara AC Services', N'Fast, reliable AC repair across Phnom Penh', 5, 1);
GO

INSERT INTO User_Addresses (UserID, Address_Name, Address_Line, City, Province, Latitude, Longitude, Is_Default) VALUES
    (1, 'Home', N'St. 271, Sangkat Boeung Tumpun', N'Phnom Penh', N'Phnom Penh', 11.539500, 104.884900, 1);
GO

INSERT INTO Technician_Addresses (TechnicianID, Address_Name, Address_Line, City, Province, Latitude, Longitude, Is_Default) VALUES
    (1, 'Shop', N'St. 128, Sangkat Mittapheap', N'Phnom Penh', N'Phnom Penh', 11.568000, 104.921000, 1);
GO

INSERT INTO User_live_locations (UserID, Latitude, Longitude, Accuracy) VALUES
    (1, 11.539500, 104.884900, 15.0);
INSERT INTO Technician_live_locations (TechnicianID, Latitude, Longitude, Accuracy) VALUES
    (1, 11.562000, 104.925000, 12.0);
GO

INSERT INTO Favorites (UserID, TechnicianID) VALUES (1, 1);
GO

-- The booking: customer requests AC repair, starting price snapshotted at $10
INSERT INTO Bookings (UserID, TechnicianID, CategoryID, AddressID, Problem_Description, Booking_Status, Starting_Price) VALUES
    (1, 1, 1, 1, N'AC is not cooling at all', 'QUOTE_PENDING', 10.00);
GO

-- Quote #1: technician's first inspection quote
INSERT INTO Service_Quotes (BookingID, TechnicianID, Version, Inspection_Fee, Labor_Cost, Parts_Cost, Travel_Fee, Reason, Quote_Status) VALUES
    (1, 1, 1, 10.00, 20.00, 0.00, 3.00, N'Initial inspection — refrigerant low', 'REVISED');
GO

-- Quote #2: revised after discovering a damaged compressor
INSERT INTO Service_Quotes (BookingID, TechnicianID, Version, Inspection_Fee, Labor_Cost, Parts_Cost, Travel_Fee, Reason, Quote_Status) VALUES
    (1, 1, 2, 10.00, 20.00, 35.00, 3.00, N'Compressor damaged — additional part required', 'ACCEPTED');
GO

INSERT INTO Notifications (UserID, Title, Message, Notification_Type) VALUES
    (1, N'Quote updated', N'Dara AC Services sent a revised quote of $68.00 for your booking.', 'QUOTE_UPDATE');
GO

INSERT INTO Call_History (CallerID, TechnicianID, Started_At, Ended_At) VALUES
    (1, 1, '2026-09-10T09:00:00', '2026-09-10T09:03:40');
GO

INSERT INTO Reviews (UserID, TechnicianID, BookingID, Rating, Comment) VALUES
    (1, 1, 1, 5, N'Fixed it fast and explained the extra cost clearly.');
GO


/* =====================================================================
   SAMPLE QUERIES — verifying the relationships
   ===================================================================== */

-- 1. A customer's booking with its current ACCEPTED quote (or none yet)
SELECT b.BookingID, b.Booking_Status, b.Starting_Price,
       q.Version, q.Total_Amount, q.Quote_Status
FROM Bookings b
LEFT JOIN Service_Quotes q
       ON q.BookingID = b.BookingID AND q.Quote_Status = 'ACCEPTED'
WHERE b.UserID = 1;

-- 2. Full quote history for a booking (all versions, latest first)
SELECT Version, Total_Amount, Quote_Status, Reason, Created_At
FROM Service_Quotes
WHERE BookingID = 1
ORDER BY Version DESC;

-- 3. Technicians in a category, sorted by rating, with their live location
SELECT t.TechnicianID, u.Full_Name, t.Business_Name, t.Average_Rating,
       tl.Latitude, tl.Longitude
FROM Technicians t
JOIN Users u               ON u.UserID = t.UserID
JOIN Service_Categories c   ON c.CategoryID = t.CategoryID
LEFT JOIN Technician_live_locations tl ON tl.TechnicianID = t.TechnicianID
WHERE c.Category_Name = N'Air Conditioner' AND u.Status = 'ACTIVE'
ORDER BY t.Average_Rating DESC;

-- 4. Unread notifications for a user (matches the app's polling pattern)
SELECT NotificationID, Title, Message, Created_At
FROM Notifications
WHERE UserID = 1 AND Is_Read = 0
ORDER BY Created_At DESC;

-- 5. A technician's favorited-by count
SELECT TechnicianID, COUNT(*) AS FavoritedByCount
FROM Favorites
GROUP BY TechnicianID;

-- 6. Starting price shown to a customer before booking (from the catalog, not a booking)
SELECT c.Category_Name, p.Starting_Price, p.Description
FROM Service_Prices p
JOIN Service_Categories c ON c.CategoryID = p.CategoryID
WHERE c.Category_Name = N'Air Conditioner';




/* =====================================================================
   ADDENDUM — what Hibernate actually expects (MySQL, not SQL Server)
   =====================================================================
   Everything above this line is the original SQL Server design doc. It was
   never implemented that way: the running backend (application.properties)
   connects to MySQL, and every com.api.entity.* class declares its own
   table/column names via @Table/@Column - those, not the design above, are
   what the backend actually reads and writes (naming strategy is
   PhysicalNamingStrategyStandardImpl, so no implicit case/snake_case
   conversion happens; a name not given explicitly is used verbatim).

   The 14 tables below are that real schema - one CREATE TABLE per entity
   that is actually wired into a repository somewhere (com.api.entity has a
   15th class, ServiceCategory, that maps to a table but has no repository
   ever injected anywhere - it and its table are dead code, not included
   here). Column types/nullability/defaults are taken directly from each
   entity's @Column annotations, cross-checked line-by-line against
   `SHOW CREATE TABLE` for the ones that already exist live.

   Four of these tables did not exist in `camfix` until this file's history:
   job, service_price, service_quote, review - every endpoint touching one
   500'd with "table doesn't exist" until each was added (see
   add_job_pricing_tables.sql and add_review_table.sql, which are the files
   actually run; this section is kept in sync with them, not a substitute).

   IMPORTANT - this section describes what a table SHOULD look like to match
   its entity, not necessarily what the live table currently IS. The other
   10 tables already exist, but several of them still carry leftover columns
   and foreign keys from an earlier schema iteration that the entities below
   were never updated to match, and at least one of those leftovers is an
   active bug, not just unused clutter:

     - favorites.TechnicianID carries TWO foreign keys at once: one to
       `technician` (what Technician.java actually maps to) and one to the
       orphaned `technicians` table (1 unrelated leftover row). Every insert
       must satisfy BOTH simultaneously. Confirmed live: favoriting
       technician_id=1 succeeds only because id 1 happens to also exist in
       the orphan table; favoriting technician_id=2 fails outright with
       "foreign key constraint fails (FK_Favorites_Technicians ...
       REFERENCES technicians)". This is not a hypothetical - it is actively
       blocking the favorites feature for most technicians today.

     - call_history and technician_addresses each still have their old
       PascalCase columns (CallerID, TechnicianID, ...) alongside the
       lowercase ones the entities actually populate (user_id,
       technician_id, ...). The old columns are NOT NULL with no default,
       and no entity sets them, so - given this server's sql_mode
       (STRICT_TRANS_TABLES) - every insert into either table fails outright
       ("Field 'CallerID' doesn't have a default value"). Confirmed by
       column inspection, not yet reproduced through the API.

     - technician_live_locations has no `id` column at all, even though
       TechnicianLiveLocation.java declares one as its @Id
       (@GeneratedValue(IDENTITY)). Its primary key is the legacy
       `TechnicianID` column instead. Two services (AdminService,
       BookingService) actively inject this repository, so this is wired-up,
       not dead code - any .save() through it should fail on the missing
       identity column.

   None of the three are touched by this addendum or by the two .sql files
   it references - fixing them means dropping/renaming columns and
   constraints on tables that already hold real rows (technician has 2,
   users has ~35), which is a different, riskier kind of change than adding
   a table that doesn't exist yet. Flagged here for a deliberate follow-up.

   The tables below are ordered so every FOREIGN KEY target already exists
   by the time it's referenced.
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
-- naming strategy uses each Java field name verbatim as the column name
-- (PhysicalNamingStrategyStandardImpl performs no transformation on top of
-- that), which is why these names are camelCase/mixed-case rather than the
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

-- TechnicianLiveLocation.java expects an auto-increment `id` primary key
-- distinct from technician_id (which only carries a UNIQUE constraint,
-- enforcing 1:1 without being the key itself). See the note above the
-- ADDENDUM heading - the live table today uses technician_id AS the primary
-- key instead, with no `id` column, which does not match this.
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

-- See the note above the ADDENDUM heading - the live `favorites` table
-- today also has a second, conflicting foreign key to the orphaned
-- `technicians` table that is not shown here and actively breaks inserts.
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

-- See the note above the ADDENDUM heading - the live `call_history` table
-- today also has legacy CallerID/TechnicianID columns not shown here,
-- NOT NULL with no default, that this entity never populates.
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

/* =====================================================================
   Tables that exist live but that NO entity maps to - orphaned leftovers
   from earlier iterations, not part of the schema above, not touched by
   anything in this addendum:
     technicians, notifications, service_categories, password_reset_tokens,
     user_live_locations, reviews (plural - unrelated to `review` above)
   ===================================================================== */
