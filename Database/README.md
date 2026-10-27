# CamFix Database Documentation

This directory contains the database schemas, migrations, test seeds, and archive for the CamFix backend (MySQL 8.0).

---

## 📁 Directory Structure

```text
Database/
├── camfix_database.sql       # 🌟 Complete MySQL Schema (Single source of truth, 21 tables)
├── docker-init.sql           # 🐳 Docker bootstrap schema for docker-compose
├── migrations/               # 📦 Incremental patches and versioned SQL migrations
├── seeds/                    # 🌱 Sample seed data (technicians, test accounts)
└── archive/                  # 🏛️ Historical legacy files (e.g. old MS SQL Server schema)
```

---

## 🚀 Usage

### 1. Fresh Database Setup (MySQL 8.0)
For a clean/new MySQL database installation:
```bash
mysql -u root -p < Database/camfix_database.sql
```

### 2. Docker Compose
When running `docker-compose up`, Docker automatically uses [docker-init.sql](file:///c:/Users/Oxy/CamFix/Database/docker-init.sql) to initialize the MySQL container.

### 3. Test Data (Seeds)
To insert sample mock technicians for testing:
```bash
mysql -u root -p CamFix < Database/seeds/seed_technicians.sql
```

### 4. Incremental Updates
All incremental fixes and versioned migrations are stored inside [migrations/](file:///c:/Users/Oxy/CamFix/Database/migrations/).
