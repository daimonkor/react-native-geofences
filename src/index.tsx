import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-geofences' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

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
  typeTransactions: { type: number; notification: NotificationData }[];
  expiredDuration: number;
}

export interface GeofenceHolder {
  initialTriggers?: number[];
  geofences: Geofence[];
}

export interface NotificationData {
  message: string;
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
  return Geofences.requestPermissions(
    'android.permission.ACCESS_FINE_LOCATION'
  ).then((value: PermissionData) => {
    return Promise.all([
      Promise.resolve(value),
      Geofences.requestPermissions(
        'android.permission.ACCESS_BACKGROUND_LOCATION'
      ),
    ]);
  });
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
