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
  radius: number;
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

export function startMonitoring(): Promise<string[]> {
  return Geofences.startMonitoring();
}

export function stopMonitoring(): Promise<boolean> {
  return Geofences.stopMonitoring();
}

export function requestPermissions(): Promise<PermissionData> {
  return Platform.OS === 'android'
    ? Geofences.requestPermissions(
        'android.permission.ACCESS_FINE_LOCATION'
      ).then((value: PermissionData) => {
        return Promise.all([
          Promise.resolve(value),
          Geofences.requestPermissions(
            'android.permission.ACCESS_BACKGROUND_LOCATION'
          ),
        ]);
      })
    : Promise.resolve({ result: true } as PermissionData);
}

export function isAcceptedPermissions(): Promise<PermissionData> {
  return Geofences.isAcceptedPermissions();
}

export function addGeofences(
  geofencesHolder: GeofenceHolder
): Promise<boolean> {
  return Geofences.addGeofences(geofencesHolder);
}

export function isExistsGeofenceById(id: string): Promise<boolean> {
  console.log(id);
  return Geofences.isExistsGeofenceById(id);
}

export function isExistsGeofenceByCoordinate(coordinate: {
  longitude: number;
  latitude: number;
}): Promise<boolean> {
  return Geofences.isExistsGeofenceByCoordinate(coordinate);
}

export function removeGeofences(filter: string[] = []): Promise<boolean> {
  return Geofences.removeGeofences(filter);
}
