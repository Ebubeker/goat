import { library } from "@fortawesome/fontawesome-svg-core";
import type { IconDefinition } from "@fortawesome/fontawesome-svg-core";
import {
  faLayerGroup,
  faList,
  faChartSimple,
  faFileInvoice,
  faQuestionCircle,
  faToolbox,
  faFilter,
  faCompassDrafting,
  faPalette,
  faSignOut,
  faBuilding,
  faMap,
  faClose,
  faHouse,
  faFolder,
  faGears,
  faCircleCheck,
  faCircleExclamation,
  faEnvelope,
  faRocket,
  faPersonRunning,
  faBus,
  faPlus,
  faMinus,
  faMaximize,
  faMinimize,
  faStar,
  faEllipsis
  faSearch,
  faChevronLeft,
  faChevronRight,
} from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { SvgIcon } from "@mui/material";
import type { SvgIconProps } from "@mui/material";

export enum ICON_NAME {
  LAYERS = "layers",
  LEGEND = "legend",
  CHART = "chart",
  REPORT = "report",
  HELP = "help",
  TOOLBOX = "toolbox",
  FILTER = "filter",
  SCENARIO = "scenario",
  STYLE = "style",
  SIGNOUT = "signout",
  ORGANIZATION = "organization",
  MAP = "map",
  CLOSE = "close",
  HOUSE = "house",
  FOLDER = "folder",
  SETTINGS = "settings",
  CIRCLECHECK = "circleCheck",
  CIRCLEINFO = "circleInfo",
  EMAIL = "email",
  ROCKET = "rocket",
  RUN = "run",
  BUS = "bus",
  PLUS = "plus",
  MINUS = "minus",
  MAXIMIZE = "maximize",
  MINIMIZE = "minimize",
  STAR = "star",
  ELLIPSIS = "ellipsis",
  SEARCH = "search",
  CHEVRON_LEFT = "chevron-left",
  CHEVRON_RIGHT = "chevron-right",
}

const nameToIcon: { [k in ICON_NAME]: IconDefinition } = {
  [ICON_NAME.LAYERS]: faLayerGroup,
  [ICON_NAME.LEGEND]: faList,
  [ICON_NAME.CHART]: faChartSimple,
  [ICON_NAME.REPORT]: faFileInvoice,
  [ICON_NAME.HELP]: faQuestionCircle,
  [ICON_NAME.TOOLBOX]: faToolbox,
  [ICON_NAME.FILTER]: faFilter,
  [ICON_NAME.SCENARIO]: faCompassDrafting,
  [ICON_NAME.STYLE]: faPalette,
  [ICON_NAME.SIGNOUT]: faSignOut,
  [ICON_NAME.ORGANIZATION]: faBuilding,
  [ICON_NAME.MAP]: faMap,
  [ICON_NAME.CLOSE]: faClose,
  [ICON_NAME.HOUSE]: faHouse,
  [ICON_NAME.FOLDER]: faFolder,
  [ICON_NAME.SETTINGS]: faGears,
  [ICON_NAME.CIRCLECHECK]: faCircleCheck,
  [ICON_NAME.CIRCLEINFO]: faCircleExclamation,
  [ICON_NAME.EMAIL]: faEnvelope,
  [ICON_NAME.ROCKET]: faRocket,
  [ICON_NAME.RUN]: faPersonRunning,
  [ICON_NAME.BUS]: faBus,
  [ICON_NAME.PLUS]: faPlus,
  [ICON_NAME.MINUS]: faMinus,
  [ICON_NAME.MAXIMIZE]: faMaximize,
  [ICON_NAME.MINIMIZE]: faMinimize,
  [ICON_NAME.STAR]: faStar,
  [ICON_NAME.ELLIPSIS]: faEllipsis,
  [ICON_NAME.SEARCH]: faSearch,
  [ICON_NAME.CHEVRON_LEFT]: faChevronLeft,
  [ICON_NAME.CHEVRON_RIGHT]: faChevronRight
};

library.add(...Object.values(nameToIcon));

export function Icon({ iconName, ...rest }: SvgIconProps & { iconName: ICON_NAME }) {
  if (!(iconName in nameToIcon)) {
    throw new Error(`Invalid icon name: ${iconName}`);
  }
  return (
    <SvgIcon {...rest}>
      <FontAwesomeIcon icon={nameToIcon[iconName]} />
    </SvgIcon>
  );
}
