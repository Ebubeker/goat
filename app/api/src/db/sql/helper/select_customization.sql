CREATE OR REPLACE FUNCTION basic.select_customization(setting_type text)
RETURNS jsonb
 LANGUAGE sql
AS $function$

	SELECT setting -> c.type
	FROM customer.customization c 
	WHERE c.type = setting_type;

$function$ IMMUTABLE;
/*
SELECT basic.select_customization('categories_no_foot');
*/