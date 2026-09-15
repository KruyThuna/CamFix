/* =====================================================================
   CamFix — SQL Server Database Schema
   Student project: technician-finder app (Cambodia)
   Engine target : Microsoft SQL Server 2019+ / Azure SQL
   Tables        : 15 (see creation order below — resolves FK dependencies)
   Author note   : all timestamps use SYSUTCDATETIME() (UTC); convert to
                    Asia/Phnom_Penh (UTC+7) in the application layer.
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
