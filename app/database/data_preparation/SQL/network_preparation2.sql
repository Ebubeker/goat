ALTER TABLE ways ADD COLUMN impedance_surface NUMERIC;
UPDATE ways SET impedance_surface = (select_from_variable_container_o('cycling_surface') ->> surface)::NUMERIC 
WHERE surface IS NOT NULL
AND surface IN(SELECT jsonb_object_keys(select_from_variable_container_o('cycling_surface')));

--Mark vertices that are on network islands
WITH count_ids AS (
	SELECT count(*), source AS id 
	FROM ways
	GROUP by source
	UNION ALL
	SELECT count(*), target AS id
	FROM ways
	GROUP by target
),
only_once AS (
	SELECT c.id,sum(c.count), v.geom 
	FROM count_ids c, ways_vertices_pgr v
	WHERE c.id = v.id
	GROUP by c.id, v.geom
	having sum(count) < 2
),
vertices_islands AS (
	SELECT w.source, w.target
	FROM only_once o, only_once o1, ways w
	WHERE w.source = o.id 
	and w.target = o1.id
),
vertices_to_update AS (
	SELECT x.id
	FROM (
		SELECT source AS id 
		FROM vertices_islands 
		UNION ALL
		SELECT target AS id 
		FROM vertices_islands 
	) x
	, ways_vertices_pgr v
	WHERE v.id = x.id
)
UPDATE ways_vertices_pgr 
SET class_ids = array[0]
FROM vertices_to_update v
WHERE ways_vertices_pgr.id = v.id;

--Identify death_end in the network
DROP TABLE IF EXISTS death_end_v;
CREATE TEMP TABLE death_end_v AS 
WITH death_end AS (
	SELECT count(source),source 
	FROM (
		SELECT SOURCE 
		FROM ways 
		UNION ALL
		SELECT target 
		FROM ways 
	) x
	GROUP BY SOURCE 
	HAVING count(source) = 1
)
SELECT v.*
FROM ways_vertices_pgr v, death_end d
WHERE v.id = d.SOURCE;

ALTER TABLE ways ADD COLUMN death_end BIGINT;

UPDATE ways w SET death_end = w.target  
FROM death_end_v d 
WHERE d.id = w.SOURCE;

UPDATE ways w SET death_end = w.source 
FROM death_end_v d 
WHERE d.id = w.target;

ALTER TABLE ways_vertices_pgr ADD COLUMN death_end BOOLEAN;
CREATE INDEX ON ways_vertices_pgr (death_end);

WITH s AS (
	SELECT w.id,w.geom,w.target vid 
	FROM ways w, death_end_v v
	WHERE w.SOURCE = v.id
	UNION ALL 
	SELECT w.id,w.geom,w.source vid 
	FROM ways w, death_end_v v
	WHERE w.target = v.id
)
UPDATE ways_vertices_pgr v
SET death_end = TRUE
FROM s 
WHERE v.id = s.vid; 

CREATE INDEX ON ways USING btree(foot);
CREATE INDEX ON ways USING btree(id);
CREATE INDEX ON ways_vertices_pgr USING btree(cnt);

CREATE SEQUENCE ways_vertices_pgr_id_seq;
ALTER TABLE ways_vertices_pgr ALTER COLUMN id SET DEFAULT nextval('ways_vertices_pgr_id_seq');
ALTER SEQUENCE ways_vertices_pgr_id_seq OWNED BY ways_vertices_pgr.id;
SELECT setval('ways_vertices_pgr_id_seq', COALESCE(max(id), 0)) FROM ways_vertices_pgr;

CREATE SEQUENCE ways_id_seq;
ALTER TABLE ways ALTER COLUMN id SET DEFAULT nextval('ways_id_seq');
ALTER SEQUENCE ways_id_seq OWNED BY ways.id;
SELECT setval('ways_id_seq', COALESCE(max(id), 0)) FROM ways;

CREATE TABLE ways_userinput (LIKE ways INCLUDING ALL);
INSERT INTO ways_userinput
SELECT * FROM ways;

CREATE TABLE ways_userinput_vertices_pgr (LIKE ways_vertices_pgr INCLUDING ALL);
INSERT INTO ways_userinput_vertices_pgr
SELECT * FROM ways_vertices_pgr;

ALTER TABLE ways_userinput add column userid int4;
ALTER TABLE ways_userinput_vertices_pgr add column userid int4;
ALTER TABLE ways_userinput add column scenario_id int4;
ALTER TABLE ways_userinput_vertices_pgr add column scenario_id int4;
ALTER TABLE ways_userinput ADD COLUMN original_id BIGINT;
CREATE INDEX ON ways_userinput USING btree (userid);
CREATE INDEX ON ways_userinput_vertices_pgr USING btree (userid);
CREATE INDEX ON ways_userinput USING btree (scenario_id);
CREATE INDEX ON ways_userinput_vertices_pgr USING btree (scenario_id);
CREATE INDEX ON ways_userinput (original_id);


----------------------------------------------------
------------- IAPI NETWORK PREPARATION -------------
----------------------------------------------------

--add the required data to the table ways
alter table ways ADD COLUMN IF NOT EXISTS tunnel text;
alter table ways ADD COLUMN IF NOT EXISTS bridge text;
UPDATE ways
set tunnel = p.tunnel,
	bridge = p.bridge
FROM planet_osm_line p
WHERE ways.osm_id = p.osm_id;

--add new column to the ways table
ALTER TABLE ways ADD COLUMN IF NOT EXISTS  bridge_tunnel_classified text;
ALTER TABLE ways ADD COLUMN IF NOT EXISTS  high_peak_hour text;
ALTER TABLE ways ADD COLUMN IF NOT EXISTS  cyclepath_classified text;
ALTER TABLE ways ADD COLUMN IF NOT EXISTS  sidewalk_width  text;
ALTER TABLE ways ADD COLUMN IF NOT EXISTS  obstacle_classified text;
ALTER TABLE ways ADD COLUMN IF NOT EXISTS  extra_street_lamp text;
ALTER TABLE ways ADD COLUMN IF NOT EXISTS  extra_trees text;
ALTER TABLE ways ADD COLUMN IF NOT EXISTS  extra_bench text;
ALTER TABLE ways ADD COLUMN IF NOT EXISTS  extra_bicycle_parking text;
ALTER TABLE ways ADD COLUMN IF NOT EXISTS  extra_waste_basket text;
ALTER TABLE ways ADD COLUMN IF NOT EXISTS  extra_fountain text;

--Categories for bridge and tunnel	
with tags as
	(
		SELECT select_from_variable_container_o('bridge_tunnel')  AS bridge_tunnel
	)
	UPDATE ways w SET bridge_tunnel_classified = x.bridge_tunnel_classified
	from 
		(select w.id, 
		case
			when tunnel IN (SELECT jsonb_array_elements_text((bridge_tunnel ->> 'tunnel')::jsonb)from tags) then 'tunnel'
			when bridge IN (SELECT jsonb_array_elements_text((bridge_tunnel ->> 'bridge')::jsonb)from tags) then 'bridge'
			else 'unclassified'
		end as bridge_tunnel_classified
		from ways w
	) x
	WHERE w.id = x.id;
-- Classification of sidewalks in ideal , comfortable, acceptable and uncomfortable

	UPDATE ways t
	SET sidewalk_width = ( 
		SELECT  sidewalk_c
		FROM ways_sidewalks x 
		WHERE x.id = t.id
	);

-- Classification of cyclepaths in segregated_yes , segregated_no,  and unclassified 
	with tags as
	(
		SELECT select_from_variable_container_o('class_cyclepath')  AS class_cyclepath
	)
	UPDATE ways w SET cyclepath_classified = x.cyclepath_classified
	from 
		(select w.id, 
		case
			when highway IN (SELECT jsonb_array_elements_text((class_cyclepath ->> 'segregated_yes')::jsonb)from tags) then 'segregated_yes'
			when (cycleway is not null or bicycle is not null) then 'segregated_no'
			else 'unclassified'
		end as cyclepath_classified
		from ways w
	) x
	WHERE w.id = x.id;
	
	--Classification of obstacles in light , moderate,  and strong 
	with tags as
	(
		SELECT select_from_variable_container_o('class_obstacle')  AS class_obstacle
	)
	UPDATE ways w SET obstacle_classified = x.obstacle_classified
	from 
		(select w.id, 
		case
			when wheelchair_classified IN (SELECT jsonb_array_elements_text((class_obstacle ->> 'moderate')::jsonb)from tags) then 'moderate'
			when highway IN (SELECT jsonb_array_elements_text((class_obstacle ->> 'strong')::jsonb)from tags) then 'strong'
			else 'light'
		end as obstacle_classified
		from ways w
	) x
	WHERE w.id = x.id;

	--Classification of more than 2 lanes as high peak hour
	UPDATE ways t
	SET high_peak_hour = 'yes'  FROM ( 
		SELECT osm_id 
		FROM footpath_visualization  
		WHERE lanes > 2
	) x 
	WHERE t.osm_id = x.osm_id;
	
	--Classification of street lamp in yes (with at least 1 lamp in the way) and no - taken from footpath_visualization
	UPDATE ways t
	SET extra_street_lamp  = 'street_lamp'  FROM ( 
		SELECT osm_id 
		FROM footpath_visualization  
		WHERE lit_classified = 'yes'
	) x 
	WHERE t.osm_id = x.osm_id;


	--Classification of tree in yes (with at least 1 lamp in the way) and no - taken from footpath_visualization
	UPDATE ways t
	SET extra_trees  = 'tree'  FROM ( 
		SELECT osm_id 
		FROM footpath_visualization  
		WHERE cnt_trees > 0
	) x 
	WHERE t.osm_id = x.osm_id;

	--Classification of bench in yes (with at least 1 lamp in the way) and no - taken from footpath_visualization
	UPDATE ways t
	SET extra_bench  = 'bench'  FROM ( 
		SELECT osm_id 
		FROM footpath_visualization  
		WHERE cnt_benches > 0
	) x 
	WHERE t.osm_id = x.osm_id;

	--Classification of bicycle parking in yes (with at least 1 lamp in the way) and no
	UPDATE ways t
		SET extra_bicycle_parking = 'bicycle_parking'  FROM ( 
			SELECT osm_id 
			FROM footpath_visualization  
			WHERE cnt_bicycle_parking > 0
		) x 
		WHERE t.osm_id = x.osm_id;
	
	--Classification of waste basket in yes (with at least 1 lamp in the way) and no - taken from footpath_visualization
	UPDATE ways t
		SET extra_waste_basket = 'waste_basket'  FROM ( 
			SELECT osm_id 
			FROM footpath_visualization  
			WHERE cnt_waste_baskets > 0
		) x 
		WHERE t.osm_id = x.osm_id;

	--Classification of fountains in yes (300m away from a fountain) and no
	UPDATE ways t
		SET extra_fountain = 'fountain'  FROM ( 
			SELECT osm_id 
			FROM footpath_visualization  
			WHERE cnt_fountains > 0
		) x 
		WHERE t.osm_id = x.osm_id;

------------------------------------------------
--add impedance factor for walking (walking)

	--add specific impedance column
	--walking_type_road
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_type_road numeric;
	--walking_peak_hour
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_peak_hour numeric;
	--walking_cyclepath
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_cyclepath numeric;
	--walking_sidewalk
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_sidewalk numeric;
	--walking_obstacle
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_obstacle numeric;
	--walking_surface
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_surface numeric;
	--walking_smoothness
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_smoothness numeric;
	--walking_park
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_park numeric;
	--walking_street_lamp
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_street_lamp numeric;
	--walking_tree
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_tree numeric;
	--walking_bench
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_bench numeric;
	--walking_bycicle_parking
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_bicycle_parking numeric;
	--walking_waste_basket
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_waste_basket numeric;
	--walking_fountain
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_fountain numeric;
	--impedance_walking_comfort
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_walking_comfort numeric;
	
	--Type of road
	UPDATE ways SET impedance_walking_type_road = (select_from_variable_container_o('walking_type_road') ->> highway)::NUMERIC 
	WHERE highway IS NOT null
	AND highway IN(SELECT jsonb_object_keys(select_from_variable_container_o('walking_type_road')));

	UPDATE ways SET impedance_walking_type_road = (select_from_variable_container_o('walking_type_road') ->> bridge_tunnel_classified)::NUMERIC 
	WHERE bridge_tunnel_classified IN(SELECT jsonb_object_keys(select_from_variable_container_o('walking_type_road')));
	
	--Peak hour 
	UPDATE ways SET impedance_walking_peak_hour  = select_from_variable_container_s('walking_peak_hour')::NUMERIC 
	WHERE high_peak_hour = 'yes';
	
	--Cyclepath
	UPDATE ways SET impedance_walking_cyclepath = (select_from_variable_container_o('walking_cyclepath') ->> cyclepath_classified)::NUMERIC 
	WHERE cyclepath_classified IN(SELECT jsonb_object_keys(select_from_variable_container_o('walking_cyclepath')));

	
	--Sidewalks
	UPDATE ways SET impedance_walking_sidewalk = (select_from_variable_container_o('walking_sidewalk') ->> sidewalk_width)::NUMERIC 
	WHERE sidewalk_width IS NOT null
	AND sidewalk_width IN(SELECT jsonb_object_keys(select_from_variable_container_o('walking_sidewalk')));
	
	--Obstacles
	UPDATE ways SET impedance_walking_obstacle = (select_from_variable_container_o('walking_obstacle') ->> obstacle_classified)::NUMERIC 
	WHERE obstacle_classified IN(SELECT jsonb_object_keys(select_from_variable_container_o('walking_obstacle')));
	     
	--Surface
	UPDATE ways SET impedance_walking_surface = (select_from_variable_container_o('walking_surface') ->> surface)::NUMERIC 
	WHERE surface IS NOT NULL
	AND surface IN(SELECT jsonb_object_keys(select_from_variable_container_o('walking_surface')));
	
	--Smoothness
	UPDATE ways SET impedance_walking_smoothness = (select_from_variable_container_o('walking_smoothness') ->> smoothness)::NUMERIC 
	WHERE smoothness IS NOT NULL
	AND smoothness IN(SELECT jsonb_object_keys(select_from_variable_container_o('walking_smoothness')));
	
	--Park
	UPDATE ways SET impedance_walking_park  = (select_from_variable_container_o('cycling_extra') ->> parks_gardens)::NUMERIC 
	WHERE parks_gardens IS NOT null;

	--Street-lamp
	UPDATE ways SET impedance_walking_street_lamp  = (select_from_variable_container_o('walking_extra') ->> extra_street_lamp)::NUMERIC 
	WHERE extra_street_lamp IS NOT null;

	--Tree
	UPDATE ways SET impedance_walking_tree = (select_from_variable_container_o('walking_extra') ->> extra_trees)::NUMERIC 
	WHERE extra_trees IS NOT null;
	
	--Bench
	UPDATE ways SET impedance_walking_bench = (select_from_variable_container_o('walking_extra') ->> extra_bench)::NUMERIC 
	WHERE extra_bench IS NOT null;

	--Bicycle parking
	UPDATE ways SET impedance_walking_bicycle_parking = (select_from_variable_container_o('walking_extra') ->> extra_bicycle_parking)::NUMERIC 
	WHERE extra_bicycle_parking IS NOT null;
	
	--Waste basket
	UPDATE ways SET impedance_walking_waste_basket = (select_from_variable_container_o('walking_extra') ->> extra_waste_basket)::NUMERIC 
	WHERE extra_waste_basket  IS NOT null;
	
	--Fountain
	
	UPDATE ways SET impedance_walking_fountain = (select_from_variable_container_o('walking_extra') ->> extra_fountain)::NUMERIC 
	WHERE extra_fountain IS NOT null;
	
	---Summary of walking speed (walking)
	UPDATE ways set impedance_walking_comfort = COALESCE(impedance_walking_type_road,0)
								+COALESCE(impedance_walking_peak_hour,0)
								+COALESCE(impedance_walking_cyclepath,0)
								+COALESCE(impedance_walking_sidewalk,0)
								+COALESCE(impedance_walking_obstacle,0)
								+COALESCE(impedance_walking_surface,0)
								+COALESCE(impedance_walking_smoothness,0)
								+COALESCE(impedance_walking_park,0)
								+COALESCE(impedance_walking_street_lamp,0)
								+COALESCE(impedance_walking_tree,0)
								+COALESCE(impedance_walking_bench,0)
								+COALESCE(impedance_walking_bicycle_parking,0)
								+COALESCE(impedance_walking_waste_basket,0)
								+COALESCE(impedance_walking_fountain,0);
-----------------------------------------------
-----------------------------------------------
							
-----------------------------------------------
--add impedance factor for cycling (cycling)

	--add specific impedance column
	--cycling_type_road
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_type_road numeric;
	--cycling_peak_hour
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_peak_hour numeric;
	--cycling_cyclepath
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_cyclepath numeric;
	--cycling_sidewalk
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_sidewalk numeric;
	--cycling_obstacle
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_obstacle numeric;
	--cycling_surface
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_surface numeric;
	--cycling_smoothness
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_smoothness numeric;
	--cycling_park
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_park numeric;
	--cycling_street_lamp
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_street_lamp numeric;
	--cycling_tree
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_tree numeric;
	--cycling_bench
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_bench numeric;
	--cycling_bycicle_parking
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_bicycle_parking numeric;
	--cycling_waste_basket
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_waste_basket numeric;
	--cycling_fountain
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_fountain numeric;
	--impedance_cycling_comfort
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_cycling_comfort numeric;
	
	--Type of road
	UPDATE ways SET impedance_cycling_type_road = (select_from_variable_container_o('cycling_type_road') ->> highway)::NUMERIC 
	WHERE highway IS NOT null
	AND highway IN(SELECT jsonb_object_keys(select_from_variable_container_o('cycling_type_road')));

	UPDATE ways SET impedance_cycling_type_road = (select_from_variable_container_o('cycling_type_road') ->> bridge_tunnel_classified)::NUMERIC 
	WHERE bridge_tunnel_classified IN(SELECT jsonb_object_keys(select_from_variable_container_o('cycling_type_road')));
	
	--Peak hour 
	UPDATE ways SET impedance_cycling_peak_hour  = select_from_variable_container_s('cycling_peak_hour')::NUMERIC 
	WHERE high_peak_hour = 'yes';
	
	--Cyclepath
	UPDATE ways SET impedance_cycling_cyclepath = (select_from_variable_container_o('cycling_cyclepath') ->> cyclepath_classified)::NUMERIC 
	WHERE cyclepath_classified IN(SELECT jsonb_object_keys(select_from_variable_container_o('cycling_cyclepath')));

	
	--Sidewalks
	UPDATE ways SET impedance_cycling_sidewalk = (select_from_variable_container_o('cycling_sidewalk') ->> sidewalk_width)::NUMERIC 
	WHERE sidewalk_width IS NOT null
	AND sidewalk_width IN(SELECT jsonb_object_keys(select_from_variable_container_o('cycling_sidewalk')));
	
	--Obstacles
	UPDATE ways SET impedance_cycling_obstacle = (select_from_variable_container_o('cycling_obstacle') ->> obstacle_classified)::NUMERIC 
	WHERE obstacle_classified IN(SELECT jsonb_object_keys(select_from_variable_container_o('cycling_obstacle')));
	     
	--Surface
	UPDATE ways SET impedance_cycling_surface = (select_from_variable_container_o('cycling_surface') ->> surface)::NUMERIC 
	WHERE surface IS NOT NULL
	AND surface IN(SELECT jsonb_object_keys(select_from_variable_container_o('cycling_surface')));
	
	--Smoothness
	UPDATE ways SET impedance_cycling_smoothness = (select_from_variable_container_o('cycling_smoothness') ->> smoothness)::NUMERIC 
	WHERE smoothness IS NOT NULL
	AND smoothness IN(SELECT jsonb_object_keys(select_from_variable_container_o('cycling_smoothness')));
	
	--Park
	UPDATE ways SET impedance_cycling_park  = (select_from_variable_container_o('cycling_extra') ->> parks_gardens)::NUMERIC 
	WHERE parks_gardens IS NOT null;

	--Street-lamp
	UPDATE ways SET impedance_cycling_street_lamp  = (select_from_variable_container_o('cycling_extra') ->> extra_street_lamp)::NUMERIC 
	WHERE extra_street_lamp IS NOT null;

	--Tree
	UPDATE ways SET impedance_cycling_tree = (select_from_variable_container_o('cycling_extra') ->> extra_trees)::NUMERIC 
	WHERE extra_trees IS NOT null;
	
	--Bench
	UPDATE ways SET impedance_cycling_bench = (select_from_variable_container_o('cycling_extra') ->> extra_bench)::NUMERIC 
	WHERE extra_bench IS NOT null;

	--Bicycle parking
	UPDATE ways SET impedance_cycling_bicycle_parking = (select_from_variable_container_o('cycling_extra') ->> extra_bicycle_parking)::NUMERIC 
	WHERE extra_bicycle_parking IS NOT null;

	--Waste basket
	
	UPDATE ways SET impedance_cycling_waste_basket = (select_from_variable_container_o('cycling_extra') ->> extra_waste_basket)::NUMERIC 
	WHERE extra_waste_basket  IS NOT null;
	
	--Fountain
	
	UPDATE ways SET impedance_cycling_fountain = (select_from_variable_container_o('cycling_extra') ->> extra_fountain)::NUMERIC 
	WHERE extra_fountain IS NOT null;
	
	---Summary of cycling speed (cycling)
	UPDATE ways set impedance_cycling_comfort = COALESCE(impedance_cycling_type_road,0)
								+COALESCE(impedance_cycling_peak_hour,0)
								+COALESCE(impedance_cycling_cyclepath,0)
								+COALESCE(impedance_cycling_sidewalk,0)
								+COALESCE(impedance_cycling_obstacle,0)
								+COALESCE(impedance_cycling_surface,0)
								+COALESCE(impedance_cycling_smoothness,0)
								+COALESCE(impedance_cycling_park,0)
								+COALESCE(impedance_cycling_street_lamp,0)
								+COALESCE(impedance_cycling_tree,0)
								+COALESCE(impedance_cycling_bench,0)
								+COALESCE(impedance_cycling_bicycle_parking,0)
								+COALESCE(impedance_cycling_waste_basket,0)
								+COALESCE(impedance_cycling_fountain,0);
-----------------------------------------------
------------------------------------------------
--add impedance factor for wheelchair (wheelchair)

	--add specific impedance column
	--wheelchair_type_road
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_type_road numeric;
	--wheelchair_peak_hour
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_peak_hour numeric;
	--wheelchair_cyclepath
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_cyclepath numeric;
	--wheelchair_sidewalk
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_sidewalk numeric;
	--wheelchair_obstacle
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_obstacle numeric;
	--wheelchair_surface
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_surface numeric;
	--wheelchair_smoothness
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_smoothness numeric;
	--wheelchair_park
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_park numeric;
	--wheelchair_street_lamp
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_street_lamp numeric;
	--wheelchair_tree
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_tree numeric;
	--wheelchair_bench
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_bench numeric;
	--wheelchair_bycicle_parking
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_bicycle_parking numeric;
	--wheelchair_waste_basket
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_waste_basket numeric;
	--wheelchair_fountain
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_fountain numeric;
	--impedance_wheelchair_comfort
	ALTER TABLE ways ADD COLUMN IF NOT EXISTS impedance_wheelchair_comfort numeric;
	
	--Type of road
	UPDATE ways SET impedance_wheelchair_type_road = (select_from_variable_container_o('wheelchair_type_road') ->> highway)::NUMERIC 
	WHERE highway IS NOT null
	AND highway IN(SELECT jsonb_object_keys(select_from_variable_container_o('wheelchair_type_road')));

	UPDATE ways SET impedance_wheelchair_type_road = (select_from_variable_container_o('wheelchair_type_road') ->> bridge_tunnel_classified)::NUMERIC 
	WHERE bridge_tunnel_classified IN(SELECT jsonb_object_keys(select_from_variable_container_o('wheelchair_type_road')));
	
	--Peak hour 
	UPDATE ways SET impedance_wheelchair_peak_hour  = select_from_variable_container_s('wheelchair_peak_hour')::NUMERIC 
	WHERE high_peak_hour = 'yes';
	
	--Cyclepath
	UPDATE ways SET impedance_wheelchair_cyclepath = (select_from_variable_container_o('wheelchair_cyclepath') ->> cyclepath_classified)::NUMERIC 
	WHERE cyclepath_classified IN(SELECT jsonb_object_keys(select_from_variable_container_o('wheelchair_cyclepath')));

	
	--Sidewalks
	UPDATE ways SET impedance_wheelchair_sidewalk = (select_from_variable_container_o('wheelchair_sidewalk') ->> sidewalk_width)::NUMERIC 
	WHERE sidewalk_width IS NOT null
	AND sidewalk_width IN(SELECT jsonb_object_keys(select_from_variable_container_o('wheelchair_sidewalk')));
	
	--Obstacles
	UPDATE ways SET impedance_wheelchair_obstacle = (select_from_variable_container_o('wheelchair_obstacle') ->> obstacle_classified)::NUMERIC 
	WHERE obstacle_classified IN(SELECT jsonb_object_keys(select_from_variable_container_o('wheelchair_obstacle')));
	     
	--Surface
	UPDATE ways SET impedance_wheelchair_surface = (select_from_variable_container_o('wheelchair_surface') ->> surface)::NUMERIC 
	WHERE surface IS NOT NULL
	AND surface IN(SELECT jsonb_object_keys(select_from_variable_container_o('wheelchair_surface')));
	
	--Smoothness
	UPDATE ways SET impedance_wheelchair_smoothness = (select_from_variable_container_o('wheelchair_smoothness') ->> smoothness)::NUMERIC 
	WHERE smoothness IS NOT NULL
	AND smoothness IN(SELECT jsonb_object_keys(select_from_variable_container_o('wheelchair_smoothness')));
	
	--Park
	UPDATE ways SET impedance_wheelchair_park  = (select_from_variable_container_o('wheelchair_extra') ->> parks_gardens)::NUMERIC 
	WHERE parks_gardens IS NOT null;

	--Street-lamp
	UPDATE ways SET impedance_wheelchair_street_lamp  = (select_from_variable_container_o('wheelchair_extra') ->> extra_street_lamp)::NUMERIC 
	WHERE extra_street_lamp IS NOT null;

	--Tree
	UPDATE ways SET impedance_wheelchair_tree = (select_from_variable_container_o('wheelchair_extra') ->> extra_trees)::NUMERIC 
	WHERE extra_trees IS NOT null;
	
	--Bench
	UPDATE ways SET impedance_wheelchair_bench = (select_from_variable_container_o('wheelchair_extra') ->> extra_bench)::NUMERIC 
	WHERE extra_bench IS NOT null;

	--Bicycle parking
	UPDATE ways SET impedance_wheelchair_bicycle_parking = (select_from_variable_container_o('wheelchair_extra') ->> extra_bicycle_parking)::NUMERIC 
	WHERE extra_bicycle_parking IS NOT null;
	
	--Waste basket
	UPDATE ways SET impedance_wheelchair_waste_basket = (select_from_variable_container_o('wheelchair_extra') ->> extra_waste_basket)::NUMERIC 
	WHERE extra_waste_basket  IS NOT null;
	
	--Fountain
	UPDATE ways SET impedance_wheelchair_fountain = (select_from_variable_container_o('wheelchair_extra') ->> extra_fountain)::NUMERIC 
	WHERE extra_fountain IS NOT null;
	
	---Summary of wheelchair speed (wheelchair)
	UPDATE ways set impedance_wheelchair_comfort = COALESCE(impedance_wheelchair_type_road,0)
								+COALESCE(impedance_wheelchair_peak_hour,0)
								+COALESCE(impedance_wheelchair_cyclepath,0)
								+COALESCE(impedance_wheelchair_sidewalk,0)
								+COALESCE(impedance_wheelchair_obstacle,0)
								+COALESCE(impedance_wheelchair_surface,0)
								+COALESCE(impedance_wheelchair_smoothness,0)
								+COALESCE(impedance_wheelchair_park,0)
								+COALESCE(impedance_wheelchair_street_lamp,0)
								+COALESCE(impedance_wheelchair_tree,0)
								+COALESCE(impedance_wheelchair_bench,0)
								+COALESCE(impedance_wheelchair_bicycle_parking,0)
								+COALESCE(impedance_wheelchair_waste_basket,0)
								+COALESCE(impedance_wheelchair_fountain,0);
-----------------------------------------------
								