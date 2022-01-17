import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-geofences' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

type AndroidInitialTriggersType = 1 | 2 | 4;
type AndroidTypeTransactionsType = 1 | 2 | 4;

export enum InitialTriggers {
  ENTER = (Platform.OS === 'android' ? 1 : 1) as
    | AndroidInitialTriggersType
    | number,
  EXIT = Platform.OS === 'android' ? 2 : 2,
  DWELL = Platform.OS === 'android' ? 4 : 4,
}

export enum TypeTransactions {
  ENTER = (Platform.OS === 'android' ? 1 : 1) as
    | AndroidTypeTransactionsType
    | number,
  EXIT = (Platform.OS === 'android' ? 2 : 2) as
    | AndroidTypeTransactionsType
    | number,
  DWELL = (Platform.OS === 'android' ? 4 : 4) as
    | AndroidTypeTransactionsType
    | number,
}

const Geofences = NativeModules.Geofences
  ? NativeModules.Geofences
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export interface Coordinate {
  longitude: number;
  latitude: number;
  radius?: number;
}

export interface Geofence {
  position: Coordinate;
  name: string;
  typeTransactions: {
    type: AndroidTypeTransactionsType | number;
    notification?: NotificationData | null;
    extraData?: Object | null;
  }[];
  expiredDuration: number;
}

export interface GeofenceHolder {
  initialTriggers?: AndroidInitialTriggersType[] | number[];
  geofences: Geofence[];
}

export interface NotificationData {
  message?: string | null;
  actionUri?: string | null;
}

export interface PermissionData {
  result: Object;
}

export type Rationale = {
  title?: string | null;
  message?: string | null;
  confirmLabel?: string | null;
  cancelLabel?: string | null;
};

export interface NotificationPermissionData {
  settings: NotificationSettings;
  authorizationStatus: Object;
}

export type NotificationOption =
  | 'alert'
  | 'badge'
  | 'sound'
  | 'criticalAlert'
  | 'carPlay'
  | 'provisional';

export type NotificationSettings = {
  // properties only available on iOS
  // unavailable settings will not be included in the response object
  alert?: boolean;
  badge?: boolean;
  sound?: boolean;
  carPlay?: boolean;
  criticalAlert?: boolean;
  provisional?: boolean;
  lockScreen?: boolean;
  notificationCenter?: boolean;
};

export enum IOSErrors {
  GEOFENCES_MISSING_ERROR_CODE = '10',
  DEVICE_IS_NOT_SUPPORTED_GEOFENCES_ERROR_CODE = '11',
  UNKNOWN_ERROR_CODE = '-1',
}

export function startMonitoring(): Promise<string[]> {
  return Geofences.startMonitoring();
}

export function stopMonitoring(): Promise<boolean> {
  return Geofences.stopMonitoring();
}

export function requestPermissions(
  rationaleDialog: Rationale
): Promise<PermissionData> {
  return Platform.OS === 'android'
    ? Geofences.requestPermissions(
        'android.permission.ACCESS_FINE_LOCATION',
        rationaleDialog
      ).then((value: PermissionData) => {
        return Promise.all([
          Promise.resolve(value),
          Geofences.requestPermissions(
            'android.permission.ACCESS_BACKGROUND_LOCATION',
            rationaleDialog
          ),
        ]);
      })
    : Geofences.requestPermissions();
}

export function permissionsStatus(): Promise<PermissionData> {
  return Geofences.permissionsStatus();
}

export function clearIconBadgeNumber(): Promise<boolean> {
  return Geofences.clearIconBadgeNumber();
}

export function notificationPermissionStatus(): Promise<NotificationPermissionData> {
  return Geofences.notificationPermissionStatus();
}

export function requestNotificationPermission(
  options: NotificationOption[]
): Promise<NotificationPermissionData> {
  return Geofences.requestNotificationPermission(options);
}

export function addGeofences(
  geofencesHolder: GeofenceHolder
): Promise<GeofenceHolder> {
  return Geofences.addGeofences(geofencesHolder);
}

export function isExistsGeofenceById(id: string): Promise<boolean> {
  console.log('isExistsGeofenceById', id);
  return Geofences.isExistsGeofenceById(id);
}

export function isExistsGeofenceByListId(ids: string[]): Promise<boolean> {
  console.log('isExistsGeofenceByListId', ids);
  return Geofences.isExistsGeofenceByListId(ids);
}

export function isExistsGeofenceByCoordinate(
  coordinate: Coordinate
): Promise<boolean> {
  console.log('isExistsGeofenceByCoordinate', coordinate);
  return Geofences.isExistsGeofenceByCoordinate(coordinate);
}

export function isExistsGeofenceByListCoordinate(
  coordinates: Coordinate[]
): Promise<boolean> {
  console.log('isExistsGeofenceByListCoordinate', coordinates);
  return Geofences.isExistsGeofenceByListCoordinate(coordinates);
}

export function removeGeofences(filter: string[] = []): Promise<boolean> {
  return Geofences.removeGeofences(filter);
}

export function isStartedMonitoring(): Promise<boolean> {
  return Geofences.isStartedMonitoring();
}
