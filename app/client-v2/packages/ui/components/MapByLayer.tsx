import "mapbox-gl/dist/mapbox-gl.css";
import React from "react";
import Map, { Layer,  Source } from "react-map-gl";

const MAPBOX_TOKEN =
  "pk.eyJ1IjoiZWxpYXNwYWphcmVzIiwiYSI6ImNqOW1scnVyOTRxcWwzMm5yYWhta2N2cXcifQ.aDCgidtC9cjf_O75frn9lA";

const stylesObj = {
  poi: {
    version: 8,
    name: "poi",
    metadata: {
      "mapbox:type": "default",
      "mapbox:origin": "basic-v1",
      "mapbox:sdk-support": {
        js: "1.6.0",
        android: "7.4.0",
        ios: "4.11.0",
      },
      "mapbox:autocomposite": true,
      "mapbox:groups": {
        "Point of interest labels, poi-labels": {
          name: "Point of interest labels, poi-labels",
          collapsed: false,
        },
        "Transit, transit-labels": {
          name: "Transit, transit-labels",
          collapsed: true,
        },
        "Administrative boundaries, admin": {
          name: "Administrative boundaries, admin",
          collapsed: false,
        },
        "Transit, built": {
          name: "Transit, built",
          collapsed: false,
        },
      },
    },
    center: [11.831704345197693, 48.124458667004006],
    zoom: 10.116890419844134,
    bearing: 0,
    pitch: 0,
    sources: {
      composite: {
        url: "mapbox://eliaspajares.cljxyaynj02532aqi9rh1kz0g-77qff",
        type: "vector",
      },
    },
    sprite: "mapbox://sprites/eliaspajares/cljxz3bl1003v01qy7k5m0apj/8afuqmyv1thq4ryczim4v3y9o",
    glyphs: "mapbox://fonts/mapbox/{fontstack}/{range}.pbf",
    layers: [
      {
        id: "poi",
        type: "symbol",
        paint: {},
        source: "composite",
        "source-layer": "poi",
        layout: {
          "icon-image": [
            "match",
            ["get", "category"],
            ["dentist"],
            "dentist-15",
            ["bakery"],
            "bakery-11",
            ["nursery"],
            "hospital-15",
            "",
          ],
        },
      },
    ],
    created: "2023-07-11T07:30:35.749Z",
    modified: "2023-07-11T14:38:16.070Z",
    id: "cljxz3bl1003v01qy7k5m0apj",
    owner: "eliaspajares",
    visibility: "private",
    protected: false,
    draft: false,
  },
  aoi: {
    version: 8,
    name: "aoi",
    metadata: {
      "mapbox:type": "default",
      "mapbox:origin": "basic-v1",
      "mapbox:sdk-support": {
        js: "1.6.0",
        android: "7.4.0",
        ios: "4.11.0",
      },
      "mapbox:autocomposite": true,
      "mapbox:groups": {
        "Point of interest labels, poi-labels": {
          name: "Point of interest labels, poi-labels",
          collapsed: false,
        },
        "Transit, transit-labels": {
          name: "Transit, transit-labels",
          collapsed: true,
        },
        "Administrative boundaries, admin": {
          name: "Administrative boundaries, admin",
          collapsed: false,
        },
        "Transit, built": {
          name: "Transit, built",
          collapsed: false,
        },
      },
    },
    center: [11.594104600206947, 48.188916237574745],
    zoom: 11.382344111015525,
    bearing: 0,
    pitch: 0,
    sources: {
      composite: {
        url: "mapbox://eliaspajares.cljxc2rek01ow2alyl0cy0y2j-63c9z",
        type: "vector",
      },
    },
    sprite: "mapbox://sprites/eliaspajares/cljyel7yl005r01pfcd4h0epj/8afuqmyv1thq4ryczim4v3y9o",
    glyphs: "mapbox://fonts/mapbox/{fontstack}/{range}.pbf",
    layers: [
      {
        id: "aoi",
        type: "fill",
        paint: {
          "fill-color": [
            "match",
            ["get", "category"],
            ["forest"],
            "hsl(137, 37%, 30%)",
            ["park"],
            "hsl(135, 69%, 70%)",
            "#000000",
          ],
        },
        layout: {},
        source: "composite",
        "source-layer": "aoi",
      },
    ],
    created: "2023-07-11T14:44:25.101Z",
    modified: "2023-07-11T14:45:57.461Z",
    id: "cljyel7yl005r01pfcd4h0epj",
    owner: "eliaspajares",
    visibility: "private",
    protected: false,
    draft: false,
  },
  edge: {
    version: 8,
    name: "edge",
    metadata: {
      "mapbox:type": "default",
      "mapbox:origin": "basic-v1",
      "mapbox:sdk-support": { js: "1.6.0", android: "7.4.0", ios: "4.11.0" },
      "mapbox:autocomposite": true,
      "mapbox:groups": {
        "Point of interest labels, poi-labels": {
          name: "Point of interest labels, poi-labels",
          collapsed: false,
        },
        "Transit, transit-labels": { name: "Transit, transit-labels", collapsed: true },
        "Administrative boundaries, admin": { name: "Administrative boundaries, admin", collapsed: false },
        "Transit, built": { name: "Transit, built", collapsed: false },
      },
    },
    center: [11.528194263293472, 48.22292619640828],
    zoom: 13.339429637563455,
    bearing: 0,
    pitch: 0,
    sources: { composite: { url: "mapbox://eliaspajares.cljxyjs6x02672oqimtbmde3u-92yjl", type: "vector" } },
    sprite: "mapbox://sprites/eliaspajares/cljxzoemb003y01qr59fx3mpq/8afuqmyv1thq4ryczim4v3y9o",
    glyphs: "mapbox://fonts/mapbox/{fontstack}/{range}.pbf",
    layers: [
      {
        id: "edge",
        type: "line",
        layout: {},
        source: "composite",
        "source-layer": "edge",
        paint: {
          "line-color": [
            "interpolate",
            ["linear"],
            ["get", "class_id"],
            101,
            [
              "match",
              ["get", "class_id"],
              [101, 102, 108, 109],
              "hsl(0, 100%, 47%)",
              [110, 111, 112, 113, 114, 117, 118, 119],
              "hsl(0, 23%, 67%)",
              "#000000",
            ],
            401,
            [
              "match",
              ["get", "class_id"],
              [101, 102, 108, 109],
              "hsl(0, 100%, 47%)",
              [110, 111, 112, 113, 114, 117, 118, 119],
              "hsl(0, 23%, 67%)",
              [120, 122, 123, 124],
              "hsl(58, 100%, 71%)",
              "#000000",
            ],
            701,
            [
              "match",
              ["get", "class_id"],
              [101, 102, 108, 109],
              "hsl(0, 100%, 47%)",
              [110, 111, 112, 113, 114, 117, 118, 119],
              "hsl(0, 23%, 67%)",
              "#000000",
            ],
          ],
          "line-width": [
            "match",
            ["get", "class_id"],
            [101, 102, 108, 109, 110],
            3,
            [111, 112, 113, 114, 117, 118, 119],
            2,
            1,
          ],
        },
      },
    ],
    created: "2023-07-11T07:46:59.459Z",
    modified: "2023-07-11T14:14:32.502Z",
    id: "cljxzoemb003y01qr59fx3mpq",
    owner: "eliaspajares",
    visibility: "public",
    protected: false,
    draft: false,
  },
  xyz: {
    id: "123e4567-e89b-12d3-a456-426614174004",
    name: "Example Image Layer XYZ",
    group: "Example Group 2",
    description: "This is an example for a image layer",
    center: [12, 48],
    zoom: 10,
    type: "image_layer",
    created_at: "2023-07-11T00:00:00",
    created_by: "example_user",
    updated_at: "2023-07-11T00:00:00",
    updated_by: "example_user",
    active: "True",
    data_source_name: "Example Data Source",
    data_reference_year: 2020,
    url: "https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey=402ce1ca8eb54457bdf65e2b261c5132",
    data_type: "xyz",
  },
  wms:  {
    id: "123e4567-e89b-12d3-a456-426614174003",
    name: "Example Image Layer",
    center: [11.831704345197693, 48.124458667004006],
    zoom: 10.116890419844134,
    group: "Example Group 2",
    description: "This is an example for an image layer",
    type: "image_layer",
    created_at: "2023-07-11T00:00:00",
    created_by: "example_user",
    updated_at: "2023-07-11T00:00:00",
    updated_by: "example_user",
    active: "True",
    data_source_name: "Example Data Source",
    data_reference_year: 2020,
    url: "https://www.lfu.bayern.de/gdi/wms/laerm/hauptverkehrsstrassen?bbox={bbox-epsg-3857}&format=image/png&service=WMS&version=1.1.1&request=GetMap&srs=EPSG:3857&transparent=true&width=256&height=256&layers=mroadbyln2022,mroadbylden2022&styles=",
    legend_urls: [
      "https://www.lfu.bayern.de/gdi/wms/laerm/hauptverkehrsstrassen?request=GetLegendGraphic&version=1.3.0&format=image/png&layer=mroadbyln&SERVICE=WMS&SLD_VERSION=1.1.0&STYLE=&TRANSPARENT=true",
      "https://www.lfu.bayern.de/gdi/wms/laerm/hauptverkehrsstrassen?request=GetLegendGraphic&version=1.3.0&format=image/png&layer=mroadbyln&SERVICE=WMS&SLD_VERSION=1.1.0&STYLE=&TRANSPARENT=true",
    ],
    data_type: "wms",
  }
};

export type MapProps = {
  layer: string;
};

export default function MapByLayer(props: MapProps) {
  const { layer } = props;

  console.log(layer);

  const sourcesObj = {
    poi: (
      <Source id={stylesObj["poi"].id} type="vector" url={stylesObj["poi"].sources.composite.url}>
        <Layer {...stylesObj["poi"].layers[0]} />
      </Source>
    ),
    aoi: (
      <Source id={stylesObj["aoi"].id} type="vector" url={stylesObj["aoi"].sources.composite.url}>
        <Layer {...stylesObj["aoi"].layers[0]} />
      </Source>
    ),
    edge: (
      <Source id={stylesObj["edge"].id} type="vector" url={stylesObj["edge"].sources.composite.url}>
        <Layer {...stylesObj["edge"].layers[0]} />
      </Source>
    ),
    xyz: (
      <Source id={stylesObj["xyz"].id} type="raster" tiles={[stylesObj["xyz"].url]}>
        <Layer type="raster" id={stylesObj["xyz"].id} source={stylesObj["xyz"].id} />
      </Source>
    ),
    wms: (
      <Source id={stylesObj["xyz"].id} type="raster" tiles={[stylesObj["wms"].url]} tileSize={256}>
        <Layer type="raster" id={stylesObj["xyz"].id} source={stylesObj["xyz"].id} />
      </Source>
    )
  };

  return (
    <div style={{ width: "100%", height: "100vh" }}>
        <Map
          initialViewState={{
            latitude: stylesObj[layer].center[1],
            longitude: stylesObj[layer].center[0],
            zoom: stylesObj[layer].zoom,
          }}
          style={{width: "100%", height: "100%"}}
          mapStyle="mapbox://styles/mapbox/streets-v11"
          mapboxAccessToken={MAPBOX_TOKEN}>
          {layer === "poi" && sourcesObj.poi}
          {layer === "aoi" && sourcesObj.aoi}
          {layer === "edge" && sourcesObj.edge}
          {layer === "xyz" && sourcesObj.xyz}
          {layer === "wms" && sourcesObj.wms}
        </Map>
    </div>
  );
}
