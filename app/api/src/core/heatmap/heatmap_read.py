import pyximport

pyximport.install()
import os

import geopandas as gpd
import numpy as np
from rich import print

from src.core.heatmap import heatmap_core, heatmap_core_cython as heatmap_cython
from src.core.config import settings
from src.db.session import legacy_engine
from src.core.opportunity import opportunity
from src.schemas.heatmap import HeatmapMode, HeatmapSettings, HeatmapType
from src.schemas.isochrone import IsochroneDTO, IsochroneMode
from src.utils import create_h3_grid, print_warning, without_keys


class BaseHeatmap:
    def __init__(self, current_user=None):
        self.current_user = current_user
        self.travel_time_base_path = os.path.join(settings.CACHE_DIR, "traveltime_matrices")
        self.connectivity_base_path = os.path.join(settings.CACHE_DIR, "connectivity_matrices")

    def get_traveltime_path(self, mode: str, profile: str, h6_id: int):
        if np.issubdtype(type(h6_id), int):
            h6_id = f"{h6_id:x}"
        return os.path.join(self.travel_time_base_path, mode, profile, f"{h6_id}.npz")

    def get_connectivity_path(self, mode: str, profile: str):
        return os.path.join(self.connectivity_base_path, mode, profile)

    def get_isochrone_routing_profile(self, isochrone_dto: IsochroneDTO):
        if isochrone_dto.mode == IsochroneMode.WALKING:
            profile = isochrone_dto.settings.walking_profile.value
        elif isochrone_dto.mode == IsochroneMode.CYCLING:
            profile = isochrone_dto.settings.cycling_profile.value
        else:
            profile = ""

        return profile

    def get_heatmap_routing_profile(self, heatmap_settings: HeatmapSettings):
        if heatmap_settings.mode == HeatmapMode.walking:
            profile = heatmap_settings.walking_profile.value
        elif heatmap_settings.mode == HeatmapMode.cycling:
            profile = heatmap_settings.cycling_profile.value
        else:
            profile = ""

        return profile

    def get_aggregating_data_path(self, bulk_id, source: str):
        return os.path.join(settings.AGGREGATING_MATRICES_PATH, bulk_id, f"{source}.npz")

    def read_h3_grids_study_areas(
        self, resolution: int, buffer_size: int, study_area_ids: list[int] = []
    ) -> list[str]:

        """Reads grid ids for study areas.

        Args:
            resolution (int): H3 resolution for grids.
            buffer_size (int): Buffer size in meters.
            study_area_ids (list[int], optional): List of study area ids. Defaults to None and will use all study area.

        Returns:
            list[str]: List of grid ids.
        """

        study_areas_union_geom = (
            gpd.read_postgis(
                f"SELECT geom FROM basic.study_area sa WHERE sa.id = any(array{study_area_ids})",
                legacy_engine,
            )
            .to_crs("EPSG:3857")
            .buffer(buffer_size)
            .to_crs("EPSG:4326")
            .unary_union
        )

        bulk_ids = create_h3_grid(
            study_areas_union_geom, resolution, intersect_with_centroid=False
        )

        return bulk_ids["h3_index"].to_list()

    def read_hexagons(self, study_area_ids: int, resolution: int):
        """
        Read the hexagons from the cache in requested resolution
        returns: grids, polygons
        """
        grids = []
        polygons = []
        base_path = settings.ANALYSIS_UNIT_PATH
        for study_area_id in study_area_ids:
            directory = os.path.join(base_path, str(study_area_id), "h3")
            grids_file_name = os.path.join(directory, f"{resolution}_grids.npy")
            polygons_file_name = os.path.join(directory, f"{resolution}_polygons.npy")
            grids.append(np.load(grids_file_name))
            polygons.append(np.load(polygons_file_name, allow_pickle=True))
        grids, idx = np.unique(np.concatenate(grids), return_index=True)
        polygons = np.concatenate(polygons)[idx]
        return grids, polygons

    def read_bulk_ids(self, study_area_ids: list[int]):
        """
        Read list of bulk ids from cache
        """

        bulk_ids_list = []
        for study_area_id in study_area_ids:
            base_path = settings.ANALYSIS_UNIT_PATH
            directory = os.path.join(base_path, str(study_area_id), "h3")
            grids_file_name = os.path.join(directory, "6_grids.npy")
            bulk_ids_list.append(np.load(grids_file_name, allow_pickle=True))

        bulk_ids = []
        for bulk_ids_ in bulk_ids_list:
            for bulk_id in bulk_ids_:
                bulk_ids.append(f"{bulk_id:x}")

        return list(set(bulk_ids))


class ReadHeatmap(BaseHeatmap):
    def read(
        self,
        heatmap_settings: HeatmapSettings,
    ) -> list[dict]:

        bulk_ids = self.read_bulk_ids(heatmap_settings.study_area_ids)
        grids, h_polygons = self.read_hexagons(
            heatmap_settings.study_area_ids, heatmap_settings.resolution
        )
        result = {
            "h3_grid_ids": grids,
            "h3_polygons": h_polygons,
        }
        if heatmap_settings.heatmap_type != HeatmapType.aggregated_data:
            profile = self.get_heatmap_routing_profile(heatmap_settings)

        if heatmap_settings.heatmap_type == HeatmapType.connectivity:
            connectivity_heatmaps_sorted, uniques = self.read_connectivity_heatmaps_sorted(
                bulk_ids, heatmap_settings, profile
            )
            areas = heatmap_cython.sums(connectivity_heatmaps_sorted, uniques)
            areas_reordered = heatmap_cython.reorder_connectivity_heatmaps(
                uniques[0], areas, grids
            )
            quantiles = heatmap_core.quantile_classify(areas_reordered)
            result["area"] = areas_reordered
            result["area_class"] = quantiles
            return result

        elif heatmap_settings.heatmap_type == HeatmapType.aggregated_data:
            source = heatmap_settings.heatmap_config.source.value
            aggregated_data_heatmaps_sorted, uniques = self.read_aggregating_data_sorted(
                bulk_ids, heatmap_settings, source
            )
            aggregated_data = heatmap_cython.sums(aggregated_data_heatmaps_sorted, uniques)
            aggregated_data_reordered = heatmap_cython.reorder_connectivity_heatmaps(
                uniques[0], aggregated_data, grids
            )
            quantiles = heatmap_core.quantile_classify(aggregated_data_reordered)
            result[source] = aggregated_data_reordered
            result[source + "_class"] = quantiles
            return result

        else:

            matrix_base_path = os.path.join(
                settings.OPPORTUNITY_MATRICES_PATH, heatmap_settings.mode.value, profile
            )
            grid_ids, traveltimes, weights, uids = self.read_opportunity_matrix(
                matrix_base_path=matrix_base_path,
                bulk_ids=bulk_ids,
                heatmap_config=heatmap_settings.heatmap_config,
            )
            if heatmap_settings.scenario.id not in (0, 1):
                scenario_id = heatmap_settings.scenario.id
                scenario_matrix_base_path = (
                    f"{settings.CACHE_PATH}/user/scenario/{scenario_id}/walking/standard"
                )
                # list folders in scenario_matrix_base_path
                bulk_ids = os.listdir(scenario_matrix_base_path)
                (
                    grid_ids_scenario,
                    traveltimes_scenario,
                    weights_scenario,
                    uids_scenario,
                ) = self.read_opportunity_matrix(
                    matrix_base_path=scenario_matrix_base_path,
                    bulk_ids=bulk_ids,
                    heatmap_config=heatmap_settings.heatmap_config,
                )
                opportunities_modified = opportunity.read_modified_data(
                    db=legacy_engine, layer="poi", scenario_id=scenario_id
                )
                modified_deleted_uids = opportunities_modified.loc[
                    opportunities_modified["edit_type"] != "n", "uid"
                ].tolist()
                modified_deleted_category = opportunities_modified.loc[
                    opportunities_modified["edit_type"] != "n", "category"
                ].unique()

                new_categories = opportunities_modified.loc[
                    opportunities_modified["edit_type"] == "n", "category"
                ].unique()

                diff_data = {
                    "grid_ids": [],
                    "traveltimes": [],
                    "weights": [],
                }
                for category in modified_deleted_category:
                    uids_in_category = uids[category]
                    indexes_diff = ~np.in1d(uids_in_category, modified_deleted_uids)
                    diff_data["grid_ids"].extend(grid_ids[category][indexes_diff])
                    diff_data["traveltimes"].extend(traveltimes[category][indexes_diff])
                    diff_data["weights"].extend(weights[category][indexes_diff])

                for category in new_categories:
                    diff_data["grid_ids"].extend(grid_ids_scenario[category])
                    diff_data["traveltimes"].extend(traveltimes_scenario[category])
                    diff_data["weights"].extend(weights_scenario[category])

            grid_ids = self.convert_grid_ids_to_parent(grid_ids, heatmap_settings.resolution)
            travel_times_sorted, weights_sorted, uniques = self.sort_and_unique(
                grid_ids, traveltimes, weights
            )
            calculations = self.do_calculations(
                travel_times_sorted, weights_sorted, uniques, heatmap_settings
            )
            calculations = self.reorder_calculations(calculations, grids, uniques)
            quantiles = self.create_quantile_arrays(calculations)
            agg_classes = self.calculate_agg_class(quantiles, heatmap_settings.heatmap_config)

            quantiles = {key + "_class": value for key, value in quantiles.items()}

            result = {
                **result,
                **calculations,
                "agg_class": agg_classes,
                **quantiles,
            }

            return result

    def read_opportunity_matrix(
        self, matrix_base_path: str, bulk_ids: list[str], heatmap_config: dict
    ):
        travel_times_dict = {}
        grid_ids_dict = {}
        weight_dict = {}
        uids_dict = {}
        relation_sizes_dict = {}
        opportunity_types = list(heatmap_config.keys())
        opportunity_categories = {}

        for opportunity_type in opportunity_types:
            opportunity_categories[opportunity_type] = list(
                heatmap_config[opportunity_type].keys()
            )
            for cat in opportunity_categories[opportunity_type]:
                travel_times_dict[cat] = []
                grid_ids_dict[cat] = []
                weight_dict[cat] = []
                uids_dict[cat] = []
                relation_sizes_dict[cat] = []

        for bulk_id in np.array(bulk_ids):
            for opportunity_type in opportunity_types:
                try:
                    base_path = os.path.join(matrix_base_path, bulk_id, opportunity_type)

                    categories = np.load(
                        os.path.join(base_path, "categories.npy"),
                        allow_pickle=True,
                    )
                    travel_times = np.load(
                        os.path.join(base_path, "travel_times.npy"),
                        allow_pickle=True,
                    )
                    if travel_times.size == 0:
                        continue
                    grid_ids = np.load(
                        os.path.join(base_path, "grid_ids.npy"),
                        allow_pickle=True,
                    )
                    weight = np.load(
                        os.path.join(base_path, "weight.npy"),
                        allow_pickle=True,
                    )
                    uid = np.load(
                        os.path.join(base_path, "uids.npy"),
                        allow_pickle=True,
                    )
                    relation_size = np.load(
                        os.path.join(base_path, "relation_size.npy"),
                        allow_pickle=True,
                    )
                    for cat in opportunity_categories[opportunity_type]:
                        selected_category_index = np.in1d(categories, np.array([cat]))
                        travel_times_dict[cat].extend(travel_times[selected_category_index])
                        grid_ids_dict[cat].extend(grid_ids[selected_category_index])
                        weight_dict[cat].extend(weight[selected_category_index])
                        uids_dict[cat].extend(uid[selected_category_index])
                        relation_sizes_dict[cat].extend(relation_size[selected_category_index])

                except FileNotFoundError:
                    print(base_path)
                    print(f"File not found for bulk_id {bulk_id}")
                    continue
        for cat in travel_times_dict.keys():
            if grid_ids_dict[cat]:
                grid_ids_dict[cat] = np.concatenate(
                    np.concatenate(grid_ids_dict[cat], axis=None), axis=None
                )
                travel_times_dict[cat] = np.concatenate(
                    np.concatenate(travel_times_dict[cat], axis=None), axis=None
                )
                weight_dict[cat] = np.concatenate(
                    np.concatenate(weight_dict[cat], axis=None), axis=None
                )
                uids_dict[cat] = np.concatenate(
                    np.concatenate(uids_dict[cat], axis=None), axis=None
                )
                relation_sizes_dict[cat] = np.concatenate(
                    np.concatenate(relation_sizes_dict[cat], axis=None), axis=None
                )
            else:
                grid_ids_dict[cat] = np.array([], np.int64)
                travel_times_dict[cat] = np.array([], np.int8)
                weight_dict[cat] = np.array([], np.float64)
                uids_dict[cat] = np.array([], np.str_)
                relation_sizes_dict[cat] = np.array([], np.int64)

        return grid_ids_dict, travel_times_dict, weight_dict, uids_dict

    def read_connectivity_heatmaps_sorted(
        self, bulk_ids: np.ndarray, heatmap_settings: HeatmapSettings, profile: str
    ) -> dict:
        connectivity_base_path = self.get_connectivity_path(heatmap_settings.mode.value, profile)
        target_resolution = heatmap_settings.resolution
        connectivity_heatmaps = []
        uniques = []
        max_traveltime = heatmap_settings.heatmap_config.max_traveltime
        for bulk_id in bulk_ids:
            file_path = os.path.join(connectivity_base_path, f"{bulk_id}.npz")
            if not os.path.exists(file_path):
                print_warning(f"File {file_path} does not exist")
                continue
            connectivity = np.load(file_path, allow_pickle=True)
            areas = heatmap_cython.get_connectivity_average(connectivity["areas"], max_traveltime)
            grids = heatmap_cython.convert_to_parents(connectivity["grid_ids"], target_resolution)
            connectivity_areas_sorted, unique = heatmap_cython.sort_and_unique_by_grid_ids(
                grids, areas
            )
            connectivity_heatmaps.append(connectivity_areas_sorted)
            uniques.append(unique)
        uniques = heatmap_cython.concatenate_and_fix_uniques_index_order(
            uniques, connectivity_heatmaps
        )
        connectivity_heatmaps = np.concatenate(connectivity_heatmaps)
        return connectivity_heatmaps, uniques

    def read_aggregating_data_sorted(self, bulk_ids, heatmap_settings, source):
        target_resolution = heatmap_settings.resolution
        aggregating_data = []
        uniques = []
        for bulk_id in bulk_ids:
            file_path = self.get_aggregating_data_path(bulk_id, source)
            if not os.path.exists(file_path):
                print_warning(f"File {file_path} does not exist")
                continue
            data = np.load(file_path, allow_pickle=True)
            grids = heatmap_cython.convert_to_parents(data["grid_id"], target_resolution)
            data_sorted, unique = heatmap_cython.sort_and_unique_by_grid_ids(grids, data["value"])
            aggregating_data.append(data_sorted)
            uniques.append(unique)
        uniques = heatmap_cython.concatenate_and_fix_uniques_index_order(uniques, aggregating_data)
        aggregating_data = np.concatenate(aggregating_data)
        return aggregating_data, uniques

    def calculate_agg_class(self, quantiles: dict, heatmap_config: dict):
        """
        Calculate the aggregated class for each grid cell based on the opportunity weights.
        """

        weighted_quantiles = []
        weight_agg = 0
        categories = {}
        for opportunity_categories in heatmap_config.values():
            categories = {**categories, **opportunity_categories}

        for key, quantile in quantiles.items():
            if quantile.size:
                weighted_quantiles.append(quantile * categories[key].get("weight", 1))
            weight_agg += categories[key].get("weight", 1)

        agg_class = np.array(weighted_quantiles).sum(axis=0) / weight_agg
        return agg_class

    def sort_and_unique(self, grid_ids: dict, traveltimes: dict, weights: dict):
        """
        Sort grid_ids in order to do calculations on travel times faster.
        Also find the uniques which used as ids (h3 index)

        returing unique is dict[tuple(unique_ids, unique_index)]
        sorted_table is dict[Array[grid_ids, travel_times]]
        """

        travel_times_sorted, weights_sorted, unique = {}, {}, {}
        for op in traveltimes.keys():
            (
                travel_times_sorted[op],
                weights_sorted[op],
                unique[op],
            ) = heatmap_cython.sort_and_unique_by_grid_ids2(
                grid_ids[op], traveltimes[op], weights[op]
            )
        return travel_times_sorted, weights_sorted, unique

    def do_calculations(
        self, travel_times_sorted: dict, weights_sorted, uniques: dict, heatmap_settings: dict
    ):
        # TODO: find a better name for this function
        """
        connect the heatmap core calculations to the heatmap method
        """

        method_map = {
            "modified_gaussian": "modified_gaussian_per_grid",
            "combined_cumulative_modified_gaussian": "combined_modified_gaussian_per_grid",
            "connectivity": "connectivity",
            "cumulative": "counts",
            "closest_average": "mins",
        }
        output = {}

        if heatmap_settings.heatmap_type.value == "modified_gaussian":
            for opportunity_type in heatmap_settings.heatmap_config.keys():
                categories = heatmap_settings.heatmap_config[opportunity_type]
                for category in categories:
                    heatmap_config = categories[category]
                    output[category] = heatmap_core.modified_gaussian_per_grid(
                        travel_times_sorted[category],
                        uniques[category],
                        heatmap_config["sensitivity"],
                        heatmap_config["max_traveltime"],
                        weights_sorted[category],
                    )

        elif heatmap_settings.heatmap_type.value == "combined_cumulative_modified_gaussian":
            for opportunity_type in heatmap_settings.heatmap_config.keys():
                categories = heatmap_settings.heatmap_config[opportunity_type]
                for category in categories:
                    heatmap_config = categories[category]
                    output[category] = heatmap_core.combined_modified_gaussian_per_grid(
                        travel_times_sorted[category],
                        uniques[category],
                        heatmap_config["sensitivity"],
                        heatmap_config["max_traveltime"],
                        heatmap_config["static_traveltime"],
                        weights_sorted[category],
                    )
        else:
            method_name = method_map[heatmap_settings.heatmap_type.value]
            method = getattr(heatmap_core, method_name)
            for opportunity_type in heatmap_settings.heatmap_config.keys():
                categories = heatmap_settings.heatmap_config[opportunity_type]
                for category in categories:
                    heatmap_config = categories[category]
                    output[category] = method(
                        travel_times_sorted[category], uniques[category], weights_sorted[category]
                    )

        return output

    def convert_grid_ids_to_parent(self, grid_ids: dict, target_resolution: int):
        for key, grid_id in grid_ids.items():
            if not grid_id.size:
                continue
            grid_ids[key] = heatmap_cython.get_h3_parents(grid_id, target_resolution)
        return grid_ids

    def create_calculation_arrays(self, grids, grid_pointers, calculations):
        """
        each calculation with their grid_pointers can be considered as a sparse array
        This function converts the sparse array to a dense array
        """

        calculation_arrays = {}
        for key, grid_pointer in grid_pointers.items():
            if not grid_pointer.size:
                calculation_arrays[key] = grid_pointer.copy()
                continue
            calculation_arrays[key] = np.full(grids.size, np.nan, np.float32)
            mask = grid_pointer != -1
            masked_grid_pointer = grid_pointer[mask]
            calculation_arrays[key][masked_grid_pointer] = calculations[key][mask]
        return calculation_arrays

    def create_quantile_arrays(self, calculations):
        """
        Classify each calculation to a quantile
        returns dict[quantile_array]
        """

        quantile_arrays = {}
        for key, calculation in calculations.items():
            quantile_arrays[key] = heatmap_core.quantile_classify(calculation)
        return quantile_arrays

    def reorder_calculations(self, calculations: dict, grids, uniques: dict):
        """
        First we create kind of a sparse array for each calculation
        Then we convert the sparse array to a dense array targeting the hexagon grids
        """

        grids_unordered_map = dict(zip(grids, range(grids.size)))
        grid_pointer = heatmap_cython.create_grid_pointers(grids_unordered_map, uniques)
        calculations = self.create_calculation_arrays(grids, grid_pointer, calculations)
        return calculations

    def to_geojson(
        self,
        results: dict,
    ):
        """
        Convert the results to geojson format

        Parameters
        ----------
        results : dict
            The results from the heatmap calculation

        Returns
        -------
        geojson : dict
        """
        if "h3_grid_ids" not in results or "h3_polygons" not in results:
            raise ValueError("h3_grid_ids and h3_polygons are required keys")

        h3_grid_ids = results["h3_grid_ids"]
        h3_polygons = results["h3_polygons"]
        properties = without_keys(results, ["h3_grid_ids", "h3_polygons"])
        features = []
        for i in range(len(h3_grid_ids)):
            h3_grid_id = h3_grid_ids[i]
            h3_polygon = h3_polygons[i]

            properties_ = {}
            for key, arr in properties.items():
                value = arr[i]
                if arr.dtype.kind in ["f", "c"]:
                    value = round(float(value), 2)
                if arr.dtype.kind in ["i", "u"]:
                    value = int(value)
                if np.isnan(value):
                    value = None
                properties_[key] = value

            features.append(
                {
                    "type": "Feature",
                    "properties": {"id": int(h3_grid_id), **properties_},
                    "geometry": {
                        "type": "Polygon",
                        "coordinates": [h3_polygon.tolist()],
                    },
                }
            )
        geojson = {"type": "FeatureCollection", "features": features}
        return geojson


read_heatmap = ReadHeatmap