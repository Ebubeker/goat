CREATE OR REPLACE FUNCTION basic.get_poi_one_entrance_3857(user_id_input integer, modus text, extent geometry, scenario_id_input integer DEFAULT 0, active_upload_ids integer[] DEFAULT '{}'::integer[])
 RETURNS TABLE(coords float[], category text)
 LANGUAGE plpgsql
AS $function$
DECLARE 
	poi_categories jsonb = basic.poi_categories(user_id_input);
	pois_one_entrance jsonb = poi_categories -> 'false'; 
	excluded_pois_id text[] := ARRAY[]::text[]; 
	data_upload_poi_categories text[];
BEGIN 		
	
	IF modus = 'scenario' THEN
		excluded_pois_id = basic.modified_pois(scenario_id_input);
	ELSE 
		scenario_id_input = 0;
	END IF;

	data_upload_poi_categories = basic.poi_categories_data_uploads(user_id_input);
    
	IF data_upload_poi_categories IS NULL THEN 
    	data_upload_poi_categories = '{}'::text[];
    END IF;
 	
   	RETURN QUERY 
	SELECT ARRAY[ST_X(ST_TRANSFORM(p.geom, 3857)), ST_Y(ST_TRANSFORM(p.geom, 3857))] AS coords, p.category
	FROM basic.poi p
	WHERE ST_Intersects(extent, p.geom)
	AND p.category IN (SELECT jsonb_array_elements_text(pois_one_entrance))
	AND p.uid NOT IN (SELECT UNNEST(excluded_pois_id))
	AND p.category NOT IN (SELECT UNNEST(data_upload_poi_categories))
	UNION ALL 
	SELECT ARRAY[ST_X(ST_TRANSFORM(p.geom, 3857)), ST_Y(ST_TRANSFORM(p.geom, 3857))] AS coords, p.category
	FROM customer.poi_user p
	WHERE ST_Intersects(extent, p.geom)
	AND p.category IN (SELECT jsonb_array_elements_text(pois_one_entrance))
	AND p.uid NOT IN (SELECT UNNEST(excluded_pois_id))
	AND p.data_upload_id IN (SELECT UNNEST(active_upload_ids))
	UNION ALL 
	SELECT ARRAY[ST_X(ST_TRANSFORM(p.geom, 3857)), ST_Y(ST_TRANSFORM(p.geom, 3857))] AS coords, p.category
	FROM customer.poi_modified p
	WHERE ST_Intersects(extent, p.geom)
	AND p.category IN (SELECT jsonb_array_elements_text(pois_one_entrance))
	AND p.scenario_id = scenario_id_input; 

END ;
$function$;

/* Example without data uploads and scenarios
SELECT * 
FROM basic.get_poi_one_entrance_3857(15, 'default'::text, ST_SETSRID(ST_BUFFER(ST_MAKEPOINT(11.57616,48.13168)::geography, 200000)::geometry, 4326))
 */