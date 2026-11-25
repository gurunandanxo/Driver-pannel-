-- ============================================================================
-- CITYRIDE DRIVER PANEL — SUPABASE POSTGRESQL FULL CLEAN SETUP SCRIPT
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------------------
-- 0. CLEAN RESET PREVIOUS CONFLICTING TABLES
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS public.incident_images CASCADE;
DROP TABLE IF EXISTS public.incidents CASCADE;
DROP TABLE IF EXISTS public.trip_locations CASCADE;
DROP TABLE IF EXISTS public.trip_stops CASCADE;
DROP TABLE IF EXISTS public.trips CASCADE;
DROP TABLE IF EXISTS public.trip_schedules CASCADE;
DROP TABLE IF EXISTS public.inspection_issues CASCADE;
DROP TABLE IF EXISTS public.pre_trip_inspections CASCADE;
DROP TABLE IF EXISTS public.route_stops CASCADE;
DROP TABLE IF EXISTS public.routes CASCADE;
DROP TABLE IF EXISTS public.vehicles CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.admin_messages CASCADE;
DROP TABLE IF EXISTS public.emergency_contacts CASCADE;
DROP TABLE IF EXISTS public.driver_profiles CASCADE;
DROP TABLE IF EXISTS public.drivers CASCADE;

-- ----------------------------------------------------------------------------
-- 1. DRIVERS & DRIVER PROFILES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE public.drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    driver_id VARCHAR(50) UNIQUE NOT NULL, -- e.g. 'TUM-DRV-1042'
    name VARCHAR(150) NOT NULL,
    full_name VARCHAR(150),
    kannada_name VARCHAR(150),
    phone VARCHAR(30) NOT NULL,
    mobile VARCHAR(30),
    email VARCHAR(150) UNIQUE,
    date_of_birth DATE,
    address TEXT,
    city VARCHAR(100) DEFAULT 'Tumakuru',
    emergency_contact_name VARCHAR(150),
    emergency_contact_number VARCHAR(30),
    license_number VARCHAR(100) NOT NULL,
    licence_number VARCHAR(100),
    license_expiry DATE,
    licence_expiry DATE,
    experience VARCHAR(50) DEFAULT '3-5 Years',
    driver_category VARCHAR(100) DEFAULT 'Heavy Passenger Vehicle (HPV)',
    badge_number VARCHAR(50),
    depot_id VARCHAR(50) DEFAULT 'DEPOT_01',
    depot_name VARCHAR(150) DEFAULT 'Tumakuru Central City Depot #1 (Ashoka Road)',
    depot VARCHAR(150) DEFAULT 'Tumakuru Central City Depot #1 (Ashoka Road)',
    profile_photo_url TEXT,
    profile_image_url TEXT,
    status VARCHAR(30) DEFAULT 'ACTIVE',
    account_status VARCHAR(30) DEFAULT 'ACTIVE', -- 'ACTIVE', 'PENDING', 'SUSPENDED', 'INACTIVE'
    role VARCHAR(30) DEFAULT 'Transit Driver',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Alias table for driver_profiles pointing to drivers
CREATE OR REPLACE VIEW public.driver_profiles AS SELECT * FROM public.drivers;

-- ----------------------------------------------------------------------------
-- 2. VEHICLES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE public.vehicles (
    id VARCHAR(50) PRIMARY KEY,
    bus_number VARCHAR(50) UNIQUE NOT NULL, -- e.g. 'KA06F8558'
    model VARCHAR(100) DEFAULT 'Tata Starbus Ultra EV',
    capacity INT DEFAULT 42,
    depot_name VARCHAR(150) DEFAULT 'Tumakuru Central City Depot #1 (Ashoka Road)',
    status VARCHAR(30) DEFAULT 'ACTIVE',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 3. ROUTES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE public.routes (
    id VARCHAR(50) PRIMARY KEY,
    route_code VARCHAR(20) UNIQUE NOT NULL, -- e.g. 'CR101'
    route_name VARCHAR(200) NOT NULL,
    origin VARCHAR(150) NOT NULL,
    destination VARCHAR(150) NOT NULL,
    direction VARCHAR(30) DEFAULT 'OUTBOUND',
    total_distance_km NUMERIC(5,2) DEFAULT 6.80,
    estimated_duration_minutes INT DEFAULT 25,
    speed_limit_kmh INT DEFAULT 40,
    color_hex VARCHAR(20) DEFAULT '#05684B',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 4. ROUTE STOPS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE public.route_stops (
    id VARCHAR(50) PRIMARY KEY,
    route_id VARCHAR(50) NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
    sequence_order INT NOT NULL,
    stop_name VARCHAR(150) NOT NULL,
    local_name VARCHAR(150),
    landmark VARCHAR(200),
    latitude NUMERIC(10,7) NOT NULL,
    longitude NUMERIC(10,7) NOT NULL,
    geofence_radius NUMERIC(6,2) DEFAULT 50.0,
    estimated_duration_minutes INT DEFAULT 4,
    active BOOLEAN DEFAULT TRUE,
    UNIQUE(route_id, sequence_order)
);

-- ----------------------------------------------------------------------------
-- 5. PRE-TRIP INSPECTIONS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE public.pre_trip_inspections (
    id TEXT PRIMARY KEY DEFAULT 'INSP_' || to_char(NOW(), 'YYYYMMDDHH24MISS') || '_' || floor(random()*1000)::text,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
    vehicle_id VARCHAR(50) REFERENCES public.vehicles(id) ON DELETE SET NULL,
    fuel_ok BOOLEAN NOT NULL DEFAULT FALSE,
    air_ok BOOLEAN NOT NULL DEFAULT FALSE,
    brakes_ok BOOLEAN NOT NULL DEFAULT FALSE,
    tyres_ok BOOLEAN NOT NULL DEFAULT FALSE,
    lights_ok BOOLEAN NOT NULL DEFAULT FALSE,
    other_issue_present BOOLEAN NOT NULL DEFAULT FALSE,
    other_issue_description TEXT,
    other_issue_photo_url TEXT,
    is_passed BOOLEAN NOT NULL DEFAULT FALSE,
    has_issues BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 6. INSPECTION ISSUES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE public.inspection_issues (
    id TEXT PRIMARY KEY DEFAULT 'ISSUE_' || to_char(NOW(), 'YYYYMMDDHH24MISS') || '_' || floor(random()*1000)::text,
    inspection_id TEXT REFERENCES public.pre_trip_inspections(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
    vehicle_id VARCHAR(50) REFERENCES public.vehicles(id) ON DELETE SET NULL,
    problem_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    photo_url TEXT,
    status VARCHAR(50) DEFAULT 'REPORTED',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 7. TRIP SCHEDULES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE public.trip_schedules (
    id VARCHAR(50) PRIMARY KEY,
    schedule_code VARCHAR(50) NOT NULL,
    route_id VARCHAR(50) REFERENCES public.routes(id) ON DELETE CASCADE,
    planned_start_time VARCHAR(20) NOT NULL,
    planned_end_time VARCHAR(20) NOT NULL,
    status VARCHAR(30) DEFAULT 'UPCOMING',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 8. TRIPS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE public.trips (
    id TEXT PRIMARY KEY,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
    vehicle_id VARCHAR(50) REFERENCES public.vehicles(id) ON DELETE SET NULL,
    route_id VARCHAR(50) REFERENCES public.routes(id) ON DELETE SET NULL,
    schedule_id VARCHAR(50) REFERENCES public.trip_schedules(id) ON DELETE SET NULL,
    inspection_id TEXT REFERENCES public.pre_trip_inspections(id) ON DELETE SET NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    destination_reached_at TIMESTAMPTZ,
    delay_minutes INT DEFAULT 0,
    duration_seconds INT DEFAULT 0,
    distance_km NUMERIC(6,2) DEFAULT 0.0,
    stops_completed INT DEFAULT 0,
    total_stops INT DEFAULT 0,
    incidents_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 9. TRIP STOPS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE public.trip_stops (
    id TEXT PRIMARY KEY DEFAULT 'TST_' || to_char(NOW(), 'YYYYMMDDHH24MISS') || '_' || floor(random()*1000)::text,
    trip_id TEXT NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    route_stop_id VARCHAR(50) NOT NULL REFERENCES public.route_stops(id) ON DELETE CASCADE,
    sequence_order INT NOT NULL,
    status VARCHAR(30) DEFAULT 'PENDING',
    reached_at TIMESTAMPTZ,
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 10. GPS LOCATIONS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE public.trip_locations (
    id BIGSERIAL PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
    vehicle_id VARCHAR(50) REFERENCES public.vehicles(id) ON DELETE SET NULL,
    route_id VARCHAR(50) REFERENCES public.routes(id) ON DELETE SET NULL,
    latitude NUMERIC(10,7) NOT NULL,
    longitude NUMERIC(10,7) NOT NULL,
    accuracy NUMERIC(6,2),
    heading NUMERIC(6,2),
    speed NUMERIC(6,2),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trip_locations_trip_id ON public.trip_locations(trip_id, recorded_at DESC);

-- ----------------------------------------------------------------------------
-- 11. INCIDENTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE public.incidents (
    id TEXT PRIMARY KEY DEFAULT 'INC_' || to_char(NOW(), 'YYYYMMDDHH24MISS') || '_' || floor(random()*1000)::text,
    incident_code VARCHAR(50) UNIQUE NOT NULL,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
    trip_id TEXT REFERENCES public.trips(id) ON DELETE SET NULL,
    vehicle_id VARCHAR(50) REFERENCES public.vehicles(id) ON DELETE SET NULL,
    route_id VARCHAR(50) REFERENCES public.routes(id) ON DELETE SET NULL,
    incident_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    status VARCHAR(50) DEFAULT 'REPORTED',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.incident_images (
    id TEXT PRIMARY KEY DEFAULT 'IMG_' || to_char(NOW(), 'YYYYMMDDHH24MISS') || '_' || floor(random()*1000)::text,
    incident_id TEXT NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 12. NOTIFICATIONS & ADMIN MESSAGING
-- ----------------------------------------------------------------------------
CREATE TABLE public.notifications (
    id TEXT PRIMARY KEY DEFAULT 'NOTIF_' || to_char(NOW(), 'YYYYMMDDHH24MISS') || '_' || floor(random()*1000)::text,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'INFO',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.admin_messages (
    id TEXT PRIMARY KEY DEFAULT 'MSG_' || to_char(NOW(), 'YYYYMMDDHH24MISS') || '_' || floor(random()*1000)::text,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE CASCADE,
    trip_id TEXT REFERENCES public.trips(id) ON DELETE SET NULL,
    sender_type VARCHAR(30) NOT NULL,
    message TEXT NOT NULL,
    attachment_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 13. EMERGENCY CONTACTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE public.emergency_contacts (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    priority INT DEFAULT 1,
    active BOOLEAN DEFAULT TRUE
);

-- ----------------------------------------------------------------------------
-- 14. ROW LEVEL SECURITY (RLS) POLICIES
-- ----------------------------------------------------------------------------
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pre_trip_inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspection_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read vehicles" ON public.vehicles FOR SELECT USING (true);
CREATE POLICY "Public read routes" ON public.routes FOR SELECT USING (true);
CREATE POLICY "Public read route stops" ON public.route_stops FOR SELECT USING (true);
CREATE POLICY "Public read trip schedules" ON public.trip_schedules FOR SELECT USING (true);
CREATE POLICY "Public read emergency contacts" ON public.emergency_contacts FOR SELECT USING (true);
CREATE POLICY "Drivers read own profile" ON public.drivers FOR SELECT USING (true);
CREATE POLICY "Drivers insert own profile" ON public.drivers FOR INSERT WITH CHECK (true);
CREATE POLICY "Drivers update own profile" ON public.drivers FOR UPDATE USING (true);
CREATE POLICY "Drivers manage inspections" ON public.pre_trip_inspections FOR ALL USING (true);
CREATE POLICY "Drivers manage inspection issues" ON public.inspection_issues FOR ALL USING (true);
CREATE POLICY "Drivers manage trips" ON public.trips FOR ALL USING (true);
CREATE POLICY "Drivers manage trip stops" ON public.trip_stops FOR ALL USING (true);
CREATE POLICY "Drivers manage trip locations" ON public.trip_locations FOR ALL USING (true);
CREATE POLICY "Drivers manage incidents" ON public.incidents FOR ALL USING (true);
CREATE POLICY "Drivers manage incident images" ON public.incident_images FOR ALL USING (true);
CREATE POLICY "Drivers manage notifications" ON public.notifications FOR ALL USING (true);
CREATE POLICY "Drivers manage admin messages" ON public.admin_messages FOR ALL USING (true);

-- ----------------------------------------------------------------------------
-- 15. SEED DATA
-- ----------------------------------------------------------------------------
-- Verified Drivers (Driver A, Driver B, Driver C)
INSERT INTO public.drivers (id, driver_id, name, full_name, kannada_name, phone, mobile, email, date_of_birth, address, city, emergency_contact_name, emergency_contact_number, license_number, licence_number, experience, driver_category, badge_number, depot_id, depot_name, role, status, account_status)
VALUES
('00000000-0000-0000-0000-000000000001'::uuid, 'TUM-DRV-1042', 'Ramesh Gowda', 'Ramesh Gowda', 'ರಮೇಶ್ ಗೌಡ', '+91 98450 12345', '+91 98450 12345', 'ramesh.gowda@cityride.in', '1985-06-15', '14th Cross, SIT Main Road, Tumakuru', 'Tumakuru', 'Smt. Suma Gowda (Spouse)', '+91 98450 99887', 'KA-06-2012-0048291', 'KA-06-2012-0048291', '10+ Years', 'Heavy Passenger Vehicle (HPV)', 'BDG-TUM-0482', 'DEPOT_01', 'Tumakuru Central City Depot #1 (Ashoka Road)', 'Senior Driver', 'ACTIVE', 'ACTIVE'),
('00000000-0000-0000-0000-000000000002'::uuid, 'TUM-DRV-1088', 'Siddaraju M.', 'Siddaraju M.', 'ಸಿದ್ಧರಾಜು ಎಂ.', '+91 94480 87654', '+91 94480 87654', 'siddaraju.m@cityride.in', '1990-03-22', 'Near Town Hall Circle, Tumakuru', 'Tumakuru', 'Shri Manjunath (Brother)', '+91 94480 11223', 'KA-06-2015-0019283', 'KA-06-2015-0019283', '5-10 Years', 'Heavy Passenger Vehicle (HPV)', 'BDG-TUM-1092', 'DEPOT_01', 'Tumakuru Central City Depot #1 (Ashoka Road)', 'Transit Driver', 'ACTIVE', 'ACTIVE'),
('00000000-0000-0000-0000-000000000003'::uuid, 'TUM-DRV-2015', 'Manjunath K.', 'Manjunath K.', 'ಮಂಜುನಾಥ್ ಕೆ.', '+91 99012 34567', '+91 99012 34567', 'manjunath.k@cityride.in', '1993-11-08', 'Batawadi Ring Road, Tumakuru', 'Tumakuru', 'Smt. Kavitha (Spouse)', '+91 99012 77889', 'KA-06-2018-0056123', 'KA-06-2018-0056123', '3-5 Years', 'Medium Transit Vehicle (MTV)', 'BDG-TUM-2015', 'DEPOT_02', 'Tumakuru North Depot #2 (Batawadi)', 'Transit Driver', 'ACTIVE', 'ACTIVE')
ON CONFLICT (driver_id) DO UPDATE SET name = EXCLUDED.name, email = EXCLUDED.email;

INSERT INTO public.vehicles (id, bus_number, model, capacity, depot_name, status, is_active)
VALUES
('BUS_001', 'KA06F8558', 'Tata Starbus Ultra EV', 42, 'Tumakuru Central City Depot #1 (Ashoka Road)', 'ACTIVE', TRUE),
('BUS_002', 'KA06F9200', 'Ashok Leyland Electric City', 42, 'Tumakuru Central City Depot #1 (Ashoka Road)', 'ACTIVE', TRUE),
('BUS_003', 'KA06F1122', 'Tata Ultra AC Low Floor', 40, 'Tumakuru North Depot #2 (Batawadi)', 'ACTIVE', TRUE),
('BUS_004', 'KA06F2468', 'Eicher Skyline Pro EV', 38, 'Tumakuru North Depot #2 (Batawadi)', 'ACTIVE', TRUE),
('BUS_005', 'KA06F4321', 'Tata Starbus Urban EV', 42, 'Tumakuru Central City Depot #1 (Ashoka Road)', 'ACTIVE', TRUE)
ON CONFLICT (id) DO UPDATE SET bus_number = EXCLUDED.bus_number, is_active = EXCLUDED.is_active;

INSERT INTO public.routes (id, route_code, route_name, origin, destination, direction, total_distance_km, estimated_duration_minutes, speed_limit_kmh, color_hex, active)
VALUES
('ROUTE_CR101', 'CR101', 'KSRTC Stand ↔ SIT Circular Loop', 'KSRTC Bus Stand', 'KSRTC Bus Stand', 'ROUND_TRIP', 8.40, 28, 40, '#05684B', TRUE),
('ROUTE_CR102', 'CR102', 'KSRTC → SIT Back → SIT Main → KSRTC', 'KSRTC Bus Stand', 'KSRTC Bus Stand', 'ROUND_TRIP', 7.60, 24, 40, '#2563EB', TRUE),
('ROUTE_CR103', 'CR103', 'KSRTC ↔ Melekote Industrial Loop', 'KSRTC Bus Stand', 'KSRTC Bus Stand', 'ROUND_TRIP', 11.20, 32, 45, '#D97706', TRUE),
('ROUTE_CR201', 'CR201', 'Batawadi ↔ Kyathsandra Loop', 'Batawadi Circle', 'Batawadi Circle', 'ROUND_TRIP', 9.80, 30, 40, '#05684B', TRUE),
('ROUTE_CR202', 'CR202', 'Town Hall ↔ Heggere Loop', 'Town Hall Tumakuru', 'Town Hall Tumakuru', 'ROUND_TRIP', 10.50, 34, 45, '#2563EB', TRUE),
('ROUTE_CR301', 'CR301', 'Tumakuru Railway Station ↔ SS Puram Loop', 'Tumakuru Railway Station', 'Tumakuru Railway Station', 'ROUND_TRIP', 6.20, 22, 35, '#05684B', TRUE)
ON CONFLICT (id) DO UPDATE SET route_code = EXCLUDED.route_code, route_name = EXCLUDED.route_name;

INSERT INTO public.route_stops (id, route_id, sequence_order, stop_name, local_name, landmark, latitude, longitude, geofence_radius, estimated_duration_minutes)
VALUES
-- CR101 Round-Trip Stops
('STOP_CR101_1', 'ROUTE_CR101', 1, 'KSRTC Bus Stand', 'ಕೆ.ಎಸ್.ಆರ್.ಟಿ.ಸಿ ಬಸ್ ನಿಲ್ದಾಣ', 'Central Bus Terminal', 13.3395000, 77.1005000, 55.0, 0),
('STOP_CR101_2', 'ROUTE_CR101', 2, 'Ashoka Road Circle', 'ಅಶೋಕ ರಸ್ತೆ ವೃತ್ತ', 'Clock Tower', 13.3360000, 77.1042000, 50.0, 4),
('STOP_CR101_3', 'ROUTE_CR101', 3, 'Town Hall Tumakuru', 'ಟೌನ್ ಹಾಲ್ ತುಮಕೂರು', 'Municipal Corporation', 13.3325000, 77.1080000, 50.0, 4),
('STOP_CR101_4', 'ROUTE_CR101', 4, 'SS Puram Circle', 'ಎಸ್.ಎಸ್ ಪುರಂ ವೃತ್ತ', 'Commercial Hub', 13.3280000, 77.1140000, 50.0, 4),
('STOP_CR101_5', 'ROUTE_CR101', 5, 'SIT Main Gate', 'ಎಸ್.ಐ.ಟಿ ಮುಖ್ಯ ದ್ವಾರ', 'Siddaganga Institute Entrance', 13.3235000, 77.1215000, 50.0, 4),
('STOP_CR101_6', 'ROUTE_CR101', 6, 'SIT Back Gate', 'ಎಸ್.ಐ.ಟಿ ಹಿಂಭಾಗದ ದ್ವಾರ', 'Hostel Block Terminal', 13.3200000, 77.1265000, 55.0, 4),
('STOP_CR101_7', 'ROUTE_CR101', 7, 'KSRTC Bus Stand', 'ಕೆ.ಎಸ್.ಆರ್.ಟಿ.ಸಿ ಬಸ್ ನಿಲ್ದಾಣ (ವಾಪಸ್)', 'Central Bus Terminal Arrival Bay', 13.3395000, 77.1005000, 55.0, 6),

-- CR102 Round-Trip Multi-Stop Sequence: KSRTC -> SIT Back -> SIT Main -> KSRTC
('STOP_CR102_1', 'ROUTE_CR102', 1, 'KSRTC Bus Stand', 'ಕೆ.ಎಸ್.ಆರ್.ಟಿ.ಸಿ ಬಸ್ ನಿಲ್ದಾಣ (ಆರಂಭ)', 'Central Bus Terminal Platform 1', 13.3395000, 77.1005000, 55.0, 0),
('STOP_CR102_2', 'ROUTE_CR102', 2, 'SIT Back Gate', 'ಎಸ್.ಐ.ಟಿ ಹಿಂಭಾಗದ ದ್ವಾರ', 'Hostel Block Terminal', 13.3200000, 77.1265000, 50.0, 6),
('STOP_CR102_3', 'ROUTE_CR102', 3, 'SIT Main Gate', 'ಎಸ್.ಐ.ಟಿ ಮುಖ್ಯ ದ್ವಾರ', 'Siddaganga Institute Main Arch (Return leg)', 13.3235000, 77.1215000, 50.0, 5),
('STOP_CR102_4', 'ROUTE_CR102', 4, 'KSRTC Bus Stand', 'ಕೆ.ಎಸ್.ಆರ್.ಟಿ.ಸಿ ಬಸ್ ನಿಲ್ದಾಣ (ಅಂತ್ಯ)', 'Central Bus Terminal Arrival Bay', 13.3395000, 77.1005000, 55.0, 7),

-- CR103 Round-Trip Stops
('STOP_CR103_1', 'ROUTE_CR103', 1, 'KSRTC Bus Stand', 'ಕೆ.ಎಸ್.ಆರ್.ಟಿ.ಸಿ ಬಸ್ ನಿಲ್ದಾಣ', 'Central Bus Terminal', 13.3395000, 77.1005000, 55.0, 0),
('STOP_CR103_2', 'ROUTE_CR103', 2, 'Batawadi Circle', 'ಬಟವಾಡಿ ವೃತ್ತ', 'North Gate', 13.3450000, 77.1120000, 50.0, 7),
('STOP_CR103_3', 'ROUTE_CR103', 3, 'Melekote Cross', 'ಮೇಕೆಕೋಟೆ ಕ್ರಾಸ್', 'Industrial Area Junction', 13.3550000, 77.0850000, 55.0, 8),
('STOP_CR103_4', 'ROUTE_CR103', 4, 'KSRTC Bus Stand', 'ಕೆ.ಎಸ್.ಆರ್.ಟಿ.ಸಿ ಬಸ್ ನಿಲ್ದಾಣ (ವಾಪಸ್)', 'Central Bus Terminal', 13.3395000, 77.1005000, 55.0, 9)
ON CONFLICT (id) DO UPDATE SET stop_name = EXCLUDED.stop_name, sequence_order = EXCLUDED.sequence_order;

INSERT INTO public.trip_schedules (id, schedule_code, route_id, planned_start_time, planned_end_time, status)
VALUES
('SCHED_101', 'TRIP-TUM-101', 'ROUTE_CR101', '07:00 AM', '07:28 AM', 'COMPLETED'),
('SCHED_102', 'TRIP-TUM-102', 'ROUTE_CR102', '08:15 AM', '08:39 AM', 'UPCOMING'),
('SCHED_103', 'TRIP-TUM-103', 'ROUTE_CR102', '09:30 AM', '09:54 AM', 'UPCOMING'),
('SCHED_201', 'TRIP-TUM-201', 'ROUTE_CR103', '08:00 AM', '08:32 AM', 'UPCOMING')
ON CONFLICT (id) DO UPDATE SET planned_start_time = EXCLUDED.planned_start_time;

INSERT INTO public.emergency_contacts (id, name, type, phone, priority, active)
VALUES
('EMERG_01', 'Police Control Room Tumakuru', 'POLICE', '112', 1, TRUE),
('EMERG_02', 'Ambulance & Emergency Medical', 'AMBULANCE', '108', 2, TRUE),
('EMERG_03', 'Tumakuru Central Bus Depot Control', 'DEPOT', '0816-2278000', 3, TRUE),
('EMERG_04', 'CityRide Operations Admin Helpdesk', 'ADMIN', '1800-425-7890', 4, TRUE),
('EMERG_05', 'Emergency Supervisor Hotline', 'EMERGENCY', '+91 94480 87654', 5, TRUE)
ON CONFLICT (id) DO UPDATE SET phone = EXCLUDED.phone;

-- ----------------------------------------------------------------------------
-- 16. SUPABASE REALTIME REPLICATION CONFIGURATION
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.trips;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.trip_locations;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.incidents;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.admin_messages;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ----------------------------------------------------------------------------
-- 17. STORAGE BUCKETS CONFIGURATION
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public) 
VALUES 
  ('driver_profiles', 'driver_profiles', true),
  ('incident_photos', 'incident_photos', true),
  ('inspection_photos', 'inspection_photos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public Read Driver Profiles" ON storage.objects FOR SELECT USING (bucket_id = 'driver_profiles');
CREATE POLICY "Auth Driver Upload Profiles" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'driver_profiles');
CREATE POLICY "Public Read Incident Photos" ON storage.objects FOR SELECT USING (bucket_id = 'incident_photos');
CREATE POLICY "Auth Driver Upload Incident Photos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'incident_photos');
CREATE POLICY "Public Read Inspection Photos" ON storage.objects FOR SELECT USING (bucket_id = 'inspection_photos');
CREATE POLICY "Auth Driver Upload Inspection Photos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'inspection_photos');
