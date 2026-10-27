-- 1. Insert Categories
INSERT INTO category (category_id, categoryName, description, icon) VALUES
(1, 'Air Conditioner', 'AC installation, cleaning, refrigerant and repair', 'ac_unit'),
(2, 'Electrical', 'Home wiring, breakers, lighting and appliances', 'bolt'),
(3, 'Appliance Repair', 'Washing machine, refrigerator, TV and electronics', 'handyman'),
(4, 'Motorcycle', 'Motorcycle maintenance, engine tuning and roadside help', 'two_wheeler'),
(5, 'Car', 'Automotive diagnostics, battery, oil and repair', 'directions_car'),
(6, 'Water network', 'Plumbing, pipes, water pumps and leaks', 'plumbing')
ON DUPLICATE KEY UPDATE description=VALUES(description);

-- 2. Insert Service Prices
INSERT INTO service_price (category_id, starting_price, description, created_at, updated_at) VALUES
(1, 15.00, 'AC servicing starting at $15', NOW(), NOW()),
(2, 10.00, 'Electrical repair starting at $10', NOW(), NOW()),
(3, 12.00, 'Appliance repair starting at $12', NOW(), NOW()),
(4, 8.00, 'Motorcycle repair starting at $8', NOW(), NOW()),
(5, 20.00, 'Car repair starting at $20', NOW(), NOW()),
(6, 10.00, 'Plumbing repair starting at $10', NOW(), NOW())
ON DUPLICATE KEY UPDATE starting_price=VALUES(starting_price);

-- 3. Insert Users for Technicians
INSERT INTO users (Userid, Full_name, Last_name, DateofBirth, Email, Phone_number, Password_hash, ROLE, STATUS, has_password, created_at, updated_at) VALUES
(2, 'Dara', 'Pich', '1992-05-15', 'dara.tech@camfix.kh', '+85598765431', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRkgVKhPe0slGUS80kVW2rr.54u', 'TECHNICIAN', 'ACTIVE', 1, NOW(), NOW()),
(3, 'Sokha', 'Meas', '1990-08-20', 'sokha.tech@camfix.kh', '+85598765432', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRkgVKhPe0slGUS80kVW2rr.54u', 'TECHNICIAN', 'ACTIVE', 1, NOW(), NOW()),
(4, 'Vireak', 'Kosal', '1988-11-10', 'vireak.tech@camfix.kh', '+85598765433', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRkgVKhPe0slGUS80kVW2rr.54u', 'TECHNICIAN', 'ACTIVE', 1, NOW(), NOW()),
(5, 'Piseth', 'Heng', '1995-03-25', 'piseth.tech@camfix.kh', '+85598765434', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRkgVKhPe0slGUS80kVW2rr.54u', 'TECHNICIAN', 'ACTIVE', 1, NOW(), NOW()),
(6, 'Bona', 'Chou', '1993-07-12', 'bona.tech@camfix.kh', '+85598765435', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRkgVKhPe0slGUS80kVW2rr.54u', 'TECHNICIAN', 'ACTIVE', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE STATUS='ACTIVE';

-- 4. Insert Technicians
INSERT INTO technician (technician_id, user_id, category_id, business_name, experience_year, description, average_rating, verified, availability_status, approval_status, approved_at, service_area, opening_hours, rating_count, created_at, updated_at) VALUES
(1, 2, 1, 'Dara AC Services', 6, 'Expert in all AC brands, gas refill, deep cleaning and inverter repair.', 4.90, 1, 'AVAILABLE', 'APPROVED', NOW(), 'Phnom Penh (Toul Kork, Chamkarmon, BKK)', '08:00 AM - 06:00 PM', 128, NOW(), NOW()),
(2, 3, 2, 'Sokha Electrical Pro', 5, 'Licensed electrician for house wiring, breaker trips, short circuits, and solar setups.', 4.85, 1, 'AVAILABLE', 'APPROVED', NOW(), 'Phnom Penh (Sen Sok, Russey Keo, Dangkao)', '07:30 AM - 07:00 PM', 95, NOW(), NOW()),
(3, 4, 5, 'Vireak Auto Care', 8, 'Mobile automotive mechanic, emergency battery jumpstart, brake service and engine diagnosis.', 4.95, 1, 'AVAILABLE', 'APPROVED', NOW(), 'Phnom Penh (All Khan)', '24/7 Roadside Assistance', 142, NOW(), NOW()),
(4, 5, 4, 'Piseth Moto Express', 4, 'Fast roadside motorcycle mechanic, tyre change, carb tuning and oil service.', 4.75, 1, 'AVAILABLE', 'APPROVED', NOW(), 'Phnom Penh City Center', '08:00 AM - 08:00 PM', 64, NOW(), NOW()),
(5, 6, 3, 'Bona Appliance Master', 5, 'Specialized in washing machines, refrigerators, microwaves, and water heaters.', 4.80, 1, 'AVAILABLE', 'APPROVED', NOW(), 'Phnom Penh & Kandal', '08:00 AM - 05:30 PM', 76, NOW(), NOW())
ON DUPLICATE KEY UPDATE approval_status='APPROVED', availability_status='AVAILABLE', verified=1;

-- 5. Insert Live Locations
INSERT INTO technician_live_locations (technician_id, latitude, longitude, accuracy, created_at, last_update) VALUES
(1, 11.5564, 104.9282, 10.0, NOW(), NOW()),
(2, 11.5721, 104.8967, 10.0, NOW(), NOW()),
(3, 11.5432, 104.9145, 10.0, NOW(), NOW()),
(4, 11.5689, 104.9213, 10.0, NOW(), NOW()),
(5, 11.5620, 104.9050, 10.0, NOW(), NOW())
ON DUPLICATE KEY UPDATE latitude=VALUES(latitude), longitude=VALUES(longitude), last_update=NOW();
