create extension if not exists "postgis" with schema "extensions";

create table "public"."locations" (
    "id" uuid not null default gen_random_uuid(),
    "geometry" geometry(Point,3857) not null,
    "created_at" timestamp without time zone not null default (now() AT TIME ZONE 'utc'::text),
    "place_name" text
);

create policy "Enable read access for all users"
on "public"."locations"
as permissive
for select
to public
using (true);

CREATE OR REPLACE FUNCTION public.get_locations_mvt(z integer, x integer, y integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE 
	mvt_output text;
BEGIN
	 WITH 
    bounds AS (
        SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
    mvtgeom AS (
        SELECT 
            id, 
        	  created_at,
			      place_name,
            ST_AsMVTGeom(
                geometry, 
                bounds.geom,
                4096, -- The extent of the tile in pixels (commonly 256 or 4096)
                0,    -- Buffer around the tile in pixels
                true  -- Clip geometries to the tile extent
            ) AS geometry
        FROM 
            locations, bounds
        WHERE 
            ST_Intersects(geometry, bounds.geom)
    )
    SELECT INTO mvt_output encode(ST_AsMVT(mvtgeom, 'locations', 4096, 'geometry'), 'base64')
    FROM mvtgeom;

    RETURN mvt_output;
END
$function$
;

INSERT INTO "public"."locations" ("geometry", "place_name") 
VALUES 
  ('0101000020110F000000258FC89034F8C03067DB8E299F4841', 'Adrar, Algeria'),
	('0101000020110F000068437E37C0276B417A7F932C708A5E41', 'Sakha Republic'),
	('0101000020110F0000482E26E360384241D08AA1CA313C4CC1', 'Karoo Hoogland Ward 3'),
	('0101000020110F00002EDBC2D1574E34414031089A47242041', 'Centre, Cameroon'),
	('0101000020110F0000720073C627836A41301E1C4ABCD04AC1', 'Western Australia'),
	('0101000020110F00000AAB30415F7E53C1F8AD1296715C35C1', 'Bahia, Brazil'),
	('0101000020110F0000BB9C82AA99FC66414CCA8210D0334641', 'China'),
	('0101000020110F000077B94B73253C64C1F49FF77F72FC5241', 'Page, Iowa'),
	('0101000020110F00007612C68B51DB4B41400114D7E44DF640', 'Mukono, Uganda'),
	('0101000020110F00004E361CD7467E53C1479888B6015435C1', 'Bahia, Brazil');
