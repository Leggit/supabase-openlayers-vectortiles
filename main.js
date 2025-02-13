import Map from "ol/Map.js";
import View from "ol/View.js";
import MVT from "ol/format/MVT.js";
import VectorTileLayer from "ol/layer/VectorTile.js";
import VectorTileSource from "ol/source/VectorTile.js";
import TileLayer from "ol/layer/Tile.js";
import OSM from "ol/source/OSM.js";
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

const base64ToArrayBuffer = (base64) => {
  const binaryString = window.atob(base64);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);

  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }

  return bytes.buffer;
};

const fetchTile = async (z, x, y) => {
  const { data, error } = await supabase.rpc("get_locations_mvt", {
    z,
    x,
    y,
  });

  if (error) {
    console.error("Error fetching tile:", error);
    return null;
  }

  return base64ToArrayBuffer(data);
};

const locationsLayer = new VectorTileLayer({
  source: new VectorTileSource({
    tileLoadFunction: (tile, src) => {
      tile.setLoader((extent, resolution, projection) => {
        const [z, x, y] = src.match(/\d+/g).map(Number);
        fetchTile(z, x, y).then((data) => {
          if (data) {
            const format = new MVT();
            const features = format.readFeatures(data, {
              extent,
              featureProjection: projection,
            });
            tile.setFeatures(features);
          }
        });
      });
    },
    tileUrlFunction: (tileCoord) =>
      `/${tileCoord[0]}/${tileCoord[1]}/${tileCoord[2]}`,
  }),
});

const map = new Map({
  layers: [
    new TileLayer({
      source: new OSM(),
    }),
    locationsLayer,
  ],
  target: "map",
  view: new View({
    center: [0, 0],
    zoom: 2,
  }),
});
