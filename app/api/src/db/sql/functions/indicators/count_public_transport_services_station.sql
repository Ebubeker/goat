CREATE OR REPLACE FUNCTION basic.count_public_transport_services_station(study_area_id integer, start_time interval, end_time interval, weekday integer)
 RETURNS TABLE(stop_id text, stop_name text, trip_cnt jsonb, geom geometry)
 LANGUAGE plpgsql
AS $function$ 

BEGIN
	RETURN query 
	WITH 
	g AS 
	(
		WITH parent_stations AS 
		(	
			SELECT count(*) cnt_children, st.parent_station 
			FROM gtfs.stops st, basic.study_area s
			WHERE ST_Intersects(st.stop_loc, s.geom)
			AND st.location_type IS NULL 
			AND s.id = study_area_id
			GROUP BY st.parent_station 
		)
		SELECT c.parent_station, j.route_type, cnt AS cnt
		FROM parent_stations c  
		CROSS JOIN LATERAL 
		(
			SELECT t.route_type, SUM(weekdays[weekday]::integer) cnt 
			FROM gtfs.stop_times_optimized t, gtfs.stops s  
			WHERE t.stop_id = s.stop_id
			AND s.parent_station = c.parent_station
			AND t.arrival_time BETWEEN start_time AND end_time
			GROUP BY t.route_type 
		) j		
	),
	o AS 
	(
		SELECT g.parent_station, jsonb_object_agg(route_type, cnt) AS trip_cnt 
		FROM g 
		GROUP BY parent_station
	)
	SELECT s.stop_id, s.stop_name, o.trip_cnt, s.stop_loc 
	FROM o, gtfs.stops s 
	WHERE o.parent_station = s.stop_id;  

END; 
$function$;
/*
SELECT * 
FROM basic.count_public_transport_services_station(91620000,'08:00','09:00', 1)
WHERE stop_name = 'Ostbahnhof'
*/
