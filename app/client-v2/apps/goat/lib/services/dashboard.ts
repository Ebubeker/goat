import axios from "@/lib/configs/axios";
import contentData from "@/lib/utils/template_content";

export const contentDataFetcher = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(contentData);
    }, 1000); // Simulate a 1-second delay
  });
};

export const contentFoldersFetcher = async (url: string) => {
  try {
    const res = await axios.get(`${url}`);
    return res.data;
  } catch (error) {
    console.error(error);
    return null;
  }
};

export const contentLayersFetcher = async (url: string, { arg }: { arg: string }) => {
  try {
    const res = await axios.get(`${url}?folder_id=${arg}`);
    return res.data;
  } catch (error) {
    console.error(error);
    return null;
  }
};

export const layerFetcher = async (url: string, { arg }: { arg: string }) => {
  try {
    const res = await axios.get(`${url}/${arg}`);
    return res.data;
  } catch (error) {
    console.error(error);
    return null;
  }
};

export const contentProjectsFetcher = async (url: string, { arg }: { arg: string }) => {
  try {
    const res = await axios.get(`${url}?folder_id=${arg}`);
    return res.data;
  } catch (error) {
    console.error(error);
    return null;
  }
};

export const contentReportsFetcher = async (url: string, { arg }: { arg: string }) => {
  try {
    const res = await axios.get(`${url}?folder_id=${arg}`);
    return res.data;
  } catch (error) {
    console.error(error);
    return null;
  }
};

export const addLayerService = async (url: string, body: object) => {
  try {
    const res = await axios.post(`${url}`, body);
    return res.data;
  } catch (error) {
    console.error(error);
    return false;
  }
};

export const loadLayerService = async (url: string) => {
  try {
    const res = await axios.get(`${url}`);
    return res.data;
  } catch (error) {
    console.error(error);
    return false;
  }
};