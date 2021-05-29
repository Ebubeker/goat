

--THIS FILE NEEDS TO BE EXECUTED TO CREATE ALL NECESSARY TABLES FOR THE STREET LEVEL QUALITY LAYERS

/*Collect deathends close to buildings*/
DROP TABLE IF EXISTS ways_to_remove;
CREATE TABLE ways_to_remove AS 
SELECT DISTINCT w.id, class_id, w.SOURCE, w.target, 
CASE WHEN death_end = SOURCE THEN SOURCE ELSE target END AS not_death_end_vertex, w.geom
FROM ways w, buildings b
WHERE death_end IS NOT NULL 
AND highway NOT IN ('residential','living_street')
AND ST_DWITHIN(w.geom, b.geom,  3 * meter_degree())
AND w.class_id::text NOT IN (SELECT UNNEST(select_from_variable_container('excluded_class_id_walking'))) 
AND (
	w.foot NOT IN (SELECT UNNEST(select_from_variable_container('categories_no_foot'))) 
	OR w.foot IS NULL 
);

/*Remove deathends shorter then 20 meters*/
ALTER TABLE ways_to_remove ADD PRIMARY KEY(id);
INSERT INTO ways_to_remove
SELECT DISTINCT w.id, w.class_id, w.SOURCE, w.target, 
CASE WHEN w.death_end = w.SOURCE THEN w.SOURCE ELSE w.target END AS not_death_end_vertex, w.geom
FROM (
	SELECT DISTINCT *
	FROM ways 
	WHERE death_end IS NOT NULL 
	AND length_m < 20
	AND highway NOT IN ('residential','living_street')
	AND class_id::text NOT IN (SELECT UNNEST(select_from_variable_container('excluded_class_id_walking'))) 
	AND (
		foot NOT IN (SELECT UNNEST(select_from_variable_container('categories_no_foot'))) 
		OR foot IS NULL 
	)
) w
LEFT JOIN ways_to_remove e
ON w.id = e.id 
WHERE e.id IS NULL; 

/*Remove neighbor edge of deathend if also new deathend*/
INSERT INTO ways_to_remove
SELECT w.id, w.class_id, w.SOURCE, w.target,
CASE WHEN w.death_end = w.SOURCE THEN w.SOURCE ELSE w.target END AS not_death_end_vertex, w.geom
FROM ways_to_remove e, ways_vertices_pgr v, ways w 
WHERE e.not_death_end_vertex = v.id 
AND v.cnt = 2
AND w.highway NOT IN ('residential','living_street')
AND
(
	w.SOURCE = e.not_death_end_vertex 
	OR  
	w.target = e.not_death_end_vertex
)
AND e.id <> w.id
AND w.class_id::text NOT IN (SELECT UNNEST(select_from_variable_container('excluded_class_id_walking'))) 
AND (
	w.foot NOT IN (SELECT UNNEST(select_from_variable_container('categories_no_foot'))) 
	OR w.foot IS NULL 
);

/*TO IMPROVE: Loop through death ends to get new death ends*/

/*Remove linkes that are inside buildings*/
INSERT INTO ways_to_remove (id)
SELECT w.id
FROM (
	SELECT DISTINCT w.id
	FROM ways w, buildings b 
	WHERE ST_Contains(b.geom,w.geom)
) w
LEFT JOIN ways_to_remove e
ON w.id = e.id 
WHERE e.id IS NULL; 

/*Create cleaned ways table and split long links*/
DROP TABLE IF EXISTS ways_cleaned;
CREATE TABLE ways_cleaned AS 
SELECT w.id AS wid, w.osm_id, w.name, w.class_id, highway, surface, smoothness, maxspeed_forward, maxspeed_backward, bicycle, foot, oneway, crossing,
bicycle_road, cycleway, incline, incline_percent, lit, lit_classified, lanes, parking, parking_lane_both, parking_lane_left,
parking_lane_right, segregated, sidewalk, sidewalk_both_width, sidewalk_left_width, sidewalk_right_width, wheelchair, wheelchair_classified, width,
death_end, split_long_way(w.geom,length_m::numeric,200) AS geom 
FROM (
	SELECT w.* 
	FROM ways w, study_area s 
	WHERE ST_Intersects(w.geom, s.geom)
) w
LEFT JOIN ways_to_remove e
ON w.id = e.id
WHERE e.id IS NULL
AND w.class_id::text NOT IN (SELECT UNNEST(select_from_variable_container('excluded_class_id_walking'))) 
AND (
	w.foot NOT IN (SELECT UNNEST(select_from_variable_container('categories_no_foot'))) 
	OR w.foot IS NULL 
)
AND length_m >= 200;

INSERT INTO ways_cleaned 
SELECT w.id AS wid, w.osm_id, w.name, w.class_id, highway, surface, smoothness, maxspeed_forward, maxspeed_backward, bicycle, foot, oneway, crossing,
bicycle_road, cycleway, incline, incline_percent, lit, lit_classified, lanes, parking, parking_lane_both, parking_lane_left,
parking_lane_right, segregated, sidewalk, sidewalk_both_width, sidewalk_left_width, sidewalk_right_width, wheelchair, wheelchair_classified, width,
death_end, w.geom
FROM (
	SELECT w.* 
	FROM ways w, study_area s 
	WHERE ST_Intersects(w.geom, s.geom)
) w
LEFT JOIN ways_to_remove e
ON w.id = e.id
WHERE e.id IS NULL
AND w.class_id::text NOT IN (SELECT UNNEST(select_from_variable_container('excluded_class_id_walking'))) 
AND (
	w.foot NOT IN (SELECT UNNEST(select_from_variable_container('categories_no_foot'))) 
	OR w.foot IS NULL 
)
AND length_m < 200;

ALTER TABLE ways_cleaned ADD COLUMN id serial; 
CREATE INDEX ON ways_cleaned USING GIST(geom);
ALTER TABLE ways_cleaned ADD PRIMARY KEY(id);

--Table for visualization of the footpath width
DROP TABLE IF EXISTS footpath_visualization;
CREATE TABLE footpath_visualization AS
SELECT (ST_OffsetCurve(w.geom,  4 * meter_degree(), 'join=round mitre_limit=2.0')) AS geom, w.sidewalk,
CASE WHEN w.sidewalk_left_width IS NOT NULL 
	THEN w.sidewalk_left_width
WHEN w.sidewalk_both_width IS NOT NULL 
	THEN w.sidewalk_both_width
ELSE NULL
END AS width, highway, oneway, maxspeed_forward, maxspeed_backward, crossing, incline, 
incline_percent, lanes, lit, lit_classified, parking, parking_lane_both, parking_lane_left, 
parking_lane_right, segregated, smoothness, surface, wheelchair, wheelchair_classified,
'yes_left' AS from_offset 
FROM ways_cleaned w
WHERE (w.sidewalk = 'both' OR w.sidewalk = 'left' OR (w.sidewalk IS NULL AND highway IN ('secondary','tertiary')))
AND w.class_id::text NOT IN (SELECT UNNEST(select_from_variable_container('excluded_class_id_walking'))) 
AND (
	w.foot NOT IN (SELECT UNNEST(select_from_variable_container('categories_no_foot'))) 
	OR w.foot IS NULL 
);

INSERT INTO footpath_visualization
SELECT (ST_OffsetCurve(w.geom,  -4 * meter_degree(), 'join=round mitre_limit=2.0')) AS geom, w.sidewalk,
CASE WHEN w.sidewalk_right_width IS NOT NULL 
	THEN w.sidewalk_right_width
WHEN w.sidewalk_both_width IS NOT NULL 
	THEN w.sidewalk_both_width
ELSE NULL
END AS width, highway, oneway, maxspeed_forward, maxspeed_backward, crossing, incline, 
incline_percent, lanes, lit, lit_classified, parking, parking_lane_both, parking_lane_left, 
parking_lane_right, segregated, smoothness, surface, wheelchair, wheelchair_classified,
'yes_right' AS from_offset  
FROM ways_cleaned w
WHERE (w.sidewalk = 'both' OR w.sidewalk = 'right' OR (w.sidewalk IS NULL AND highway IN ('secondary','tertiary')))
AND w.class_id::text NOT IN (SELECT UNNEST(select_from_variable_container('excluded_class_id_walking'))) 
AND (w.foot NOT IN (SELECT UNNEST(select_from_variable_container('categories_no_foot'))) 
OR w.foot IS NULL);

INSERT INTO footpath_visualization
SELECT geom, sidewalk, width, highway, oneway, maxspeed_forward, maxspeed_backward, crossing, incline, 
incline_percent, lanes, lit, lit_classified, parking, parking_lane_both, parking_lane_left, parking_lane_right, 
segregated, smoothness, surface, wheelchair, wheelchair_classified,
'no' as from_offset 
FROM ways_cleaned
WHERE sidewalk IN ('no','none')
OR highway = 'living_street' 
OR (highway in ('residential','unclassified','service') AND sidewalk IS NULL);

INSERT INTO footpath_visualization
SELECT geom, sidewalk, 
CASE WHEN segregated = 'yes'
	THEN width/2 
ELSE width
END AS width, highway, oneway, maxspeed_forward, maxspeed_backward, crossing, incline, 
incline_percent, lanes, lit, lit_classified, parking, parking_lane_both, parking_lane_left, 
parking_lane_right, segregated, smoothness, surface, wheelchair, wheelchair_classified,
'no' AS from_offset
FROM ways_cleaned
WHERE highway ='cycleway' OR (foot = 'designated' AND bicycle = 'designated');

INSERT INTO footpath_visualization
SELECT geom, sidewalk, width, highway, oneway, maxspeed_forward, maxspeed_backward, crossing, incline, 
incline_percent, lanes, lit, lit_classified, parking, parking_lane_both, parking_lane_left, parking_lane_right, 
segregated, smoothness, surface, wheelchair, wheelchair_classified,
'no' AS from_offset  
FROM ways_cleaned
WHERE sidewalk IS NULL AND highway IN ('path','track','footway','steps','service','pedestrian');

CREATE INDEX ON footpath_visualization USING gist(geom);
ALTER TABLE footpath_visualization ADD COLUMN id serial;
ALTER TABLE footpath_visualization ADD PRIMARY KEY(id);

/*Overlaps are removed. A logic is implemented that keeps the large geometry when clipped. This can also cause errors.*/
DROP TABLE splitted_geoms_to_keep;
CREATE TEMP TABLE splitted_geoms_to_keep AS 
SELECT v.id, j.geom
FROM footpath_visualization v 
CROSS JOIN LATERAL 
(
	SELECT (ST_DUMP(ST_SPLIT(v.geom, x.geom))).geom AS geom 
	FROM 
	(
		SELECT ST_UNION(geom) AS geom 
		FROM footpath_visualization fv
		WHERE ST_Intersects(v.geom, fv.geom)
		AND ST_CROSSES(fv.geom, v.geom)
	) x
	WHERE st_geometrytype(ST_Intersection(v.geom,x.geom)) = 'ST_Point' 
	ORDER BY ST_LENGTH((ST_DUMP(ST_SPLIT(v.geom, x.geom))).geom)
	DESC
	LIMIT 1
) j;

CREATE INDEX ON splitted_geoms_to_keep (id);
UPDATE footpath_visualization f
SET geom = g.geom
FROM splitted_geoms_to_keep  g
WHERE f.id = g.id;

----------------------------------
----Table for street furniture----
----------------------------------
DROP TABLE IF EXISTS street_furniture;
CREATE TABLE street_furniture AS 	
SELECT p.osm_id AS original_key, p.amenity, p.geom, 'osm' AS SOURCE
FROM pois p, study_area s
WHERE st_intersects(s.geom,p.geom) 
AND amenity IN ('bench','waste_basket','toilets','fountain','bicycle_parking','bicycle_repair_station','drinking_water');

CREATE INDEX ON street_furniture USING gist(geom);
ALTER TABLE street_furniture ADD COLUMN id serial;
ALTER TABLE street_furniture ADD PRIMARY KEY(id);

--Insert street_lamps
INSERT INTO street_furniture
SELECT p.osm_id AS original_key, p.highway AS amenity, p.way AS geom, 'osm' AS SOURCE
FROM planet_osm_point p, study_area s
WHERE st_intersects(s.geom,p.way) 
AND highway IN ('street_lamp');

--Remove duplicates from OSM & Mapillary
--Table of just duplicates
DROP TABLE IF EXISTS dups;
CREATE TABLE dups AS
SELECT p.*, ST_Distance(p.geom, s.geom) AS distance
FROM street_items p  --rename to: custom_points_walkability 
LEFT JOIN street_furniture s ON ST_DWithin(p.geom, s.geom, 0.0001)
WHERE p.value = s.amenity AND ST_Distance(p.geom, s.geom)>0;

--Table of no duplicates
DROP TABLE IF EXISTS no_dups;
CREATE TABLE no_dups AS SELECT p.*
FROM street_items p --rename to: custom_points_walkability
LEFT JOIN dups ON p.id = dups.id
WHERE dups.id IS NULL;

--Insert data from Mapillary 
INSERT INTO street_furniture
SELECT p.original_key, amenity, p.geom, p.data_source
FROM no_dups p 
WHERE value IN ('bench','street_lamp');

DROP TABLE dups;
DROP TABLE no_dups;

----------------------------------------------------------	
--Precalculation of visualized features for illuminance---
----------------------------------------------------------
WITH variables AS 
(
    SELECT select_from_variable_container_o('lit') AS lit
)
UPDATE footpath_visualization f SET lit_classified = x.lit_classified
FROM
    (SELECT f.id,
    CASE WHEN 
        lit IN ('yes','Yes','automatic','24/7','sunset-sunrise') 
        OR (lit IS NULL AND highway IN (SELECT jsonb_array_elements_text((lit ->> 'highway_yes')::jsonb) FROM variables)
			AND maxspeed_forward<80)
        THEN 'yes' 
    WHEN
        lit IN ('no','No','disused')
        OR (lit IS NULL AND (highway IN (SELECT jsonb_array_elements_text((lit ->> 'highway_no')::jsonb) FROM variables) 
        OR surface IN (SELECT jsonb_array_elements_text((lit ->> 'surface_no')::jsonb) FROM variables)
		OR maxspeed_forward>=80)
        )
        THEN 'no'
    ELSE 'unclassified'
    END AS lit_classified 
    FROM footpath_visualization f
    ) x
WHERE f.id = x.id;

--Precalculation of visualized features for lit
DROP TABLE IF EXISTS buffer_lamps;
CREATE TABLE buffer_lamps as
SELECT (ST_DUMP(ST_UNION(ST_BUFFER(geom,15 * meter_degree())))).geom AS geom 
FROM street_furniture
WHERE amenity = 'street_lamp';

CREATE INDEX ON buffer_lamps USING gist(geom);

CREATE TEMP TABLE lit_share AS 
SELECT f.id, SUM(ST_LENGTH(ST_Intersection(b.geom, f.geom)))/ST_LENGTH(f.geom) AS share_intersection, f.geom 
FROM buffer_lamps b, footpath_visualization f 
WHERE ST_Intersects(b.geom,f.geom) 
GROUP BY id; 
ALTER TABLE lit_share ADD PRIMARY KEY(id);

UPDATE footpath_visualization f 
SET lit_classified = 'yes'
FROM lit_share l  
WHERE (f.lit IS NULL OR f.lit = '') 
AND l.share_intersection > 0.3
AND f.id = l.id; 

ALTER TABLE footpath_visualization ADD COLUMN IF NOT EXISTS lit_share numeric;

UPDATE footpath_visualization f  
SET lit_share = l.share_intersection
FROM lit_share l 
WHERE f.id = l.id;

DROP TABLE lit_share;

----------------------
---Add landuse data---
----------------------
--clean landuse ##copy this query to the "buildings_residential.sql" script when finished
DROP TABLE IF EXISTS inner_polygons;
CREATE TABLE inner_polygons AS
SELECT lo.*
FROM landuse_osm l 
JOIN landuse_osm lo ON (ST_Contains(l.geom, lo.geom)) WHERE l.gid != lo.gid;

UPDATE landuse_osm l
SET geom = st_difference(l.geom, i.geom)
FROM inner_polygons i
WHERE l.gid=i.gid;

INSERT INTO landuse_osm 
SELECT * FROM inner_polygons; 
--TODO: maybe insert a loop (for polygons inside the inner_polygons)

DROP TABLE inner_polygons;

--assign info about landuse to footpath_visualization
ALTER TABLE footpath_visualization ADD COLUMN IF NOT EXISTS landuse text;

UPDATE footpath_visualization f  
SET landuse = l.landuse_simplified
FROM landuse_osm l
WHERE ST_CONTAINS(l.geom,f.geom);

DROP TABLE IF EXISTS footpath_ids_landuse;
CREATE TABLE footpath_ids_landuse AS --TODO: use buffer and intersect with area 
WITH i AS 
(
    SELECT f.id, f.geom, ST_LENGTH(ST_Intersection(l.geom, f.geom)) len_intersection, l.landuse_simplified AS landuse
    FROM  landuse_osm l, footpath_visualization f
    WHERE ST_Intersects(f.geom, l.geom)  
    AND f.landuse IS NULL
    AND l.landuse_simplified IS NOT NULL
)   
SELECT id, get_attr_for_max_val(array_agg((len_intersection * 1000000000)::integer), array_agg(landuse)) AS landuse 
FROM i
GROUP BY id; 

ALTER TABLE footpath_ids_landuse ADD PRIMARY KEY(id); 

UPDATE footpath_visualization f  
SET landuse = l.landuse 
FROM footpath_ids_landuse l 
WHERE f.id = l.id; 

DROP TABLE footpath_ids_landuse;

--assign info about population density
ALTER TABLE footpath_visualization ADD COLUMN IF NOT EXISTS population text;
--TODO: assign "high","medium","low","no" accoridng to buffer -> intersection with pop.

-- assign info about POIs
ALTER TABLE footpath_visualization ADD COLUMN IF NOT EXISTS pois text;

-- pois
-- Create temp table to count pois
DROP TABLE IF EXISTS pois_buffer;
CREATE TEMP TABLE pois_buffer (id serial, number_pois int8);
INSERT INTO pois_buffer
WITH buffer AS (
	SELECT id, st_buffer(geom::geography, 60) AS geom FROM footpath_visualization),
poi AS (SELECT geom FROM pois WHERE amenity NOT IN ('parking','bench','parking_space','waste_basket','fountain','toilets','carging_station','bicycle_parking','parking_entrance','motorcycle_parking','hunting_stand'))
SELECT b.id, count(poi.geom) AS number_pois
FROM buffer b
LEFT JOIN poi ON st_contains(b.geom::geometry, poi.geom)
GROUP BY b.id;

-- Assign info to footpaths
UPDATE footpath_visualization 
SET pois = 'no'
FROM pois_buffer
WHERE pois_buffer.id = footpath_visualization.id AND pois_buffer.number_pois = 0;

UPDATE footpath_visualization 
SET pois = 'low'
FROM pois_buffer
WHERE pois_buffer.id = footpath_visualization.id AND pois_buffer.number_pois <= 5 and pois_buffer.number_pois > 0;

DROP TABLE pois_buffer;

--Table for visualization of parking
DROP TABLE IF EXISTS parking;
CREATE TABLE parking AS
	SELECT (ST_OffsetCurve(w.geom,  0.00005, 'join=round mitre_limit=2.0')) AS geom, 
		w.parking,
			CASE WHEN w.parking_lane_left IS NOT NULL 
				THEN w.parking_lane_left
			WHEN w.parking_lane_both IS NOT NULL 
				THEN w.parking_lane_both
			ELSE NULL
			END AS parking_lane, 
		highway
	FROM ways_cleaned w
	WHERE (w.parking_lane_left IS NOT NULL OR w.parking_lane_both IS NOT NULL)
UNION
	SELECT (ST_OffsetCurve(w.geom,  -0.00005, 'join=round mitre_limit=2.0')) AS geom, 
		w.parking,
			CASE WHEN w.parking_lane_right IS NOT NULL 
				THEN w.parking_lane_right
			WHEN w.parking_lane_both IS NOT NULL 
				THEN w.parking_lane_both
			ELSE NULL
			END AS parking_lane, 
		highway
	FROM ways_cleaned w
	WHERE (w.parking_lane_right IS NOT NULL OR w.parking_lane_both IS NOT NULL)
UNION
	SELECT (ST_OffsetCurve(w.geom,  0.00005, 'join=round mitre_limit=2.0')), w.parking, 'no' AS parking_lane, w.highway FROM ways_cleaned w
	WHERE w.parking = 'no'
UNION
	SELECT (ST_OffsetCurve(w.geom,  -0.00005, 'join=round mitre_limit=2.0')), w.parking, 'no' AS parking_lane, w.highway FROM ways_cleaned w
	WHERE w.parking = 'no'
UNION
	SELECT geom, parking, NULL AS parking_lane, highway FROM ways_cleaned
	WHERE parking IS NULL AND parking_lane_right IS NULL AND parking_lane_left IS NULL AND parking_lane_both IS NULL
	AND highway IN ('secondary','tertiary','residential','living_street','service','unclassified');
