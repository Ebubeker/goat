import type { PayloadAction } from "@reduxjs/toolkit";
import { createSlice } from "@reduxjs/toolkit";

interface IViewState {
  latitude: number;
  longitude: number;
  zoom: number;
  // min_zoom: number;
  // max_zoom: number;
  // bearing: number;
  // pitch: number;
}

interface IBasemap {
  value: string;
  url: string;
  title: string;
  subtitle: string;
  thumbnail: string;
}

export interface IStylingState {
  initialViewState: IViewState;
  tabValue: number;
  basemaps: IBasemap[];
  activeBasemapIndex: number[];
}

const initialState: IStylingState = {
  initialViewState: {
    latitude: 48.13780235991851,
    longitude: 11.575936741828286,
    zoom: 12,
    // min_zoom: 0,
    // max_zoom: 20,
    // bearing: 0,
    // pitch: 0,
  },
  tabValue: 0,
  basemaps: [
    {
      value: "mapbox_streets",
      url: "mapbox://styles/mapbox/streets-v12",
      title: "High Fidelity",
      subtitle: "Great for public presentations",
      thumbnail: "https://i.imgur.com/aVDMUKAm.png",
    },
    {
      value: "mapbox_satellite",
      url: "mapbox://styles/mapbox/satellite-streets-v12",
      title: "Satellite Streets",
      subtitle: "As seen from space",
      thumbnail: "https://i.imgur.com/JoMGuUOm.png",
    },
    {
      value: "mapbox_light",
      url: "mapbox://styles/mapbox/light-v11",
      title: "Light",
      subtitle: "For highlitghting data overlays",
      thumbnail: "https://i.imgur.com/jHFGEEQm.png",
    },
    {
      value: "mapbox_dark",
      url: "mapbox://styles/mapbox/dark-v11",
      title: "Dark",
      subtitle: "For highlighting data overlays",
      thumbnail: "https://i.imgur.com/PaYV5Gjm.png",
    },
    {
      value: "mapbox_navigation",
      url: "mapbox://styles/mapbox/navigation-day-v1",
      title: "Traffic",
      subtitle: "Live traffic data",
      thumbnail: "https://i.imgur.com/lfcARxZm.png",
    },
  ],
  activeBasemapIndex: [0],
};

const stylingSlice = createSlice({
  name: "styling",
  initialState,
  reducers: {
    setTabValue: (state, action: PayloadAction<number>) => {
      state.tabValue = action.payload;
    },
    setActiveBasemapIndex: (state, action: PayloadAction<number[]>) => {
      state.activeBasemapIndex = action.payload;
    },
  },
});

export const { setTabValue, setActiveBasemapIndex } = stylingSlice.actions;
export const stylingReducer = stylingSlice.reducer;
