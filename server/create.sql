CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS trace (
		"trace_id"           BIGSERIAL PRIMARY KEY,
		"journey_id"         TEXT NOT NULL,
		"timestamp"          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp
);

CREATE TABLE IF NOT EXISTS plan (
		"plan_id"            BIGSERIAL PRIMARY KEY,
		"journey_id"         TEXT NOT NULL,
		"timestamp"          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp
);

CREATE TABLE IF NOT EXISTS route (
		"route_id"          BIGSERIAL PRIMARY KEY,
		"journey_id"        TEXT NOT NULL,
		"timestamp"         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
		"speed"             DECIMAL(21,16) NOT NULL DEFAULT 0,
		"mode"              TEXT NOT NULL,
		"realtime"          BOOLEAN NOT NULL DEFAULT TRUE
);

SELECT AddGeometryColumn('trace', 'geometry', 4326, 'POINT', 3);
SELECT AddGeometryColumn('plan', 'geometry', 4326, 'LINESTRING', 3);
SELECT AddGeometryColumn('route', 'geometry', 4326, 'LINESTRING', 3);
CREATE INDEX trace_geometry_gix ON trace USING GIST (geometry);
CREATE INDEX plan_geometry_gix ON plan USING GIST (geometry);
CREATE INDEX route_geometry_gix ON route USING GIST (geometry);

CREATE INDEX route_timestamp_gix ON route (timestamp);
CREATE INDEX route_journey_gix ON route (journey_id);
CREATE INDEX route_mode_gix ON route (mode);

CREATE TABLE IF NOT EXISTS report (
		"report_id"         BIGSERIAL PRIMARY KEY,
		"speed"             DECIMAL(21,16) NOT NULL DEFAULT 0,
		"type"              TEXT NOT NULL DEFAULT 'realtime',
		"reading"           DECIMAL(21,16) NOT NULL DEFAULT 0,
		"timestamp"         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp
);

SELECT AddGeometryColumn('report', 'geometry', 4326, 'LINESTRING', 3);
CREATE INDEX report_geometry_gix ON report USING GIST (geometry);

CREATE INDEX report_timestamp_gix ON route (timestamp);

-- CREATE OR REPLACE VIEW journey AS
--    SELECT  journey_id,
--            MIN(timestamp) AS start_time,
--            MAX(timestamp) AS end_time,
--            ST_LineMerge(ST_Collect(geometry)) as geometry
--            array_agg(speed) AS speed
--    FROM route
--    GROUP BY journey_id;


-- mt prefix stands for "mass transit"

CREATE TABLE IF NOT EXISTS mt_city (
		"city_id"         	BIGSERIAL PRIMARY KEY,
		"name"        			TEXT NOT NULL,
		"country"						TEXT NOT NULL,
		UNIQUE ("name", "country")
);

CREATE TABLE IF NOT EXISTS mt_agency (
		"agency_id"         BIGINT PRIMARY KEY,
		"city_id"						BIGINT NOT NULL REFERENCES mt_city ("city_id") ON DELETE CASCADE,
		"name"        			TEXT NOT NULL,
		"url"               TEXT NOT NULL,
		"language"          TEXT NOT NULL DEFAULT 'english',
		"timezone"          TEXT NOT NULL DEFAULT 'UTC',
		"phone"             TEXT NULL,
		UNIQUE ("city_id", "agency_id")
);

CREATE TABLE IF NOT EXISTS mt_route (
		"route_id"         	BIGINT PRIMARY KEY,
		"agency_id"					BIGINT NOT NULL REFERENCES mt_agency ("agency_id") ON DELETE CASCADE,
		"short_name"   			TEXT NOT NULL,
		"full_name"    			TEXT NOT NULL,
		"type"         			INT,
		"description"  			TEXT NULL,
		"url"              	TEXT NULL,
		UNIQUE ("route_id", "agency_id")
);
SELECT AddGeometryColumn('mt_route', 'geometry', 4326, 'LINESTRING', 3);

CREATE TABLE IF NOT EXISTS mt_stop (
		"stop_id"           BIGINT PRIMARY KEY,
		"city_id"						BIGINT NOT NULL REFERENCES mt_city ("city_id") ON DELETE CASCADE,
		"code"        			TEXT NOT NULL,
		"name"        			TEXT NOT NULL,
		"description"    		TEXT NULL,
		"timezone"          TEXT NOT NULL DEFAULT 'UTC',
		UNIQUE ("city_id", "stop_id")
);
SELECT AddGeometryColumn('mt_stop', 'geometry', 4326, 'POINT', 3);

CREATE TABLE IF NOT EXISTS mt_stop_visit (
		"stop_id"								BIGINT NOT NULL REFERENCES mt_stop ("stop_id") ON DELETE CASCADE,
		"aimed_arrival_time"    TIMESTAMP WITH TIME ZONE NOT NULL,
		"expected_arrival_time" TIMESTAMP WITH TIME ZONE NOT NULL,
		UNIQUE ("stop_id", "aimed_arrival_time")
);

