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
  faPlus,
  faMinus,
  faMaximize,
  faMinimize,
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
  PLUS = "plus",
  MINUS = "minus",
  MAXIMIZE = "maximize",
  MINIMIZE = "minimize",
  CHEVRON_RIGHT = "chevron-right"
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
  [ICON_NAME.PLUS]: faPlus,
  [ICON_NAME.MINUS]: faMinus,
  [ICON_NAME.MAXIMIZE]: faMaximize,
  [ICON_NAME.MINIMIZE]: faMinimize,
  [ICON_NAME.CHEVRON_RIGHT]: faChevronRight,
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
