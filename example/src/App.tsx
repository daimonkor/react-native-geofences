import * as React from 'react';

import {
  StyleSheet,
  View,
  Text,
  Button,
  ScrollView,
  SafeAreaView,
} from 'react-native';
import { NativeEventEmitter, NativeModules } from 'react-native';
import {
  stopMonitoring,
  startMonitoring,
  addGeofences,
  NotificationData,
  requestPermissions,
  permissionsStatus,
  removeGeofences,
  TypeTransactions,
  InitialTriggers,
  PermissionData,
  isStartedMonitoring,
  isExistsGeofenceByListCoordinate,
} from 'react-native-geofences';
import { useState } from 'react';

const mockGeofences = {
  geofences: [
    {
      position: { latitude: 40.7415, longitude: -74.0034, radius: 200 },
      name: 'First point',
      expiredDuration: 30000000,
      typeTransactions: [
        {
          type: TypeTransactions.ENTER,
          notification: {
            message: null, //'Enter to first point',
            actionUri: 'https://test1.com',
          } as NotificationData,
          extraData: {
            headers: {
              token: 'fsfssfsdfsdfsdfsdf',
              appId: 'dsgfsdgdfgfdg',
            },
            body: { border_id: 10, state: 'enter' },
            url: 'https://basjeapi.com',
          },
        },

        {
          type: TypeTransactions.EXIT,
          notification: {
            message: 'Exit from first point',
            actionUri: 'https://youtube.com',
          } as NotificationData,
          extraData: {
            headers: {
              token: 'fsfssfsdfsdfsdfsdf',
              appId: 'dsgfsdgdfgfdg',
            },
            body: { border_id: 10, state: 'exit' },
            url: 'https://basjeapi.com',
          },
        },
      ],
    },

    {
      position: { latitude: 50, longitude: 50, radius: 300 },
      name: 'Second point',
      expiredDuration: 30000000,
      typeTransactions: [
        {
          type: TypeTransactions.ENTER,
          notification: {
            message: 'Enter to second point',
            actionUri: 'deeplink',
          } as NotificationData,
        },

        {
          type: TypeTransactions.EXIT,
          notification: {
            message: 'Exit from second point',
            actionUri: 'deeplink',
          } as NotificationData,
        },
      ],
    },

    {
      position: { latitude: 40.7415, longitude: -74.0034, radius: 100 },
      name: 'Third point',
      expiredDuration: 30000000,
      typeTransactions: [
        {
          type: TypeTransactions.EXIT,
          notification: {
            message: 'Exit from third point',
            actionUri: 'deeplink',
          } as NotificationData,
          extraData: {
            headers: {
              token: 'fsfssfsdfsdfsdfsdf',
              appId: 'dsgfsdgdfgfdg',
            },
            body: { border_id: 20, state: 'exit' },
            url: 'https://bajseapi.com',
          },
        },

        {
          type: TypeTransactions.ENTER,
          notification: {
            message: 'Enter to third point',
            actionUri: 'deeplink',
          } as NotificationData,
          extraData: {
            headers: {
              token: 'fsfssfsdfsdfsdfsdf',
              appId: 'dsgfsdgdfgfdg',
            },
            body: { border_id: 20, state: 'enter' },
            url: 'https://basejapi.com',
          },
        },
      ],
    },
  ],
  initialTriggers: [
    InitialTriggers.DWELL,
    InitialTriggers.ENTER,
    InitialTriggers.EXIT,
  ],
};

export default function App() {
  const [permissionData, setPermissionData] = useState<
    PermissionData | string | null
  >(null);

  const [isMonitongStartedState, setMonitoringStarted] = useState<
    boolean | string | null
  >(null);

  React.useEffect(() => {
    permissionsStatus()
      .then(setPermissionData)
      .catch((error) => setPermissionData(error.message));

    isStartedMonitoring()
      .then((value) => setMonitoringStarted(value))
      .catch((error) => setMonitoringStarted(error.message));

    const eventEmitter = new NativeEventEmitter(NativeModules.GeofencesModule);
    const eventListener = eventEmitter.addListener(
      'onGeofenceEvent',
      (event) => {
        console.log('onGeofenceEvent', event);
      }
    );
    return () => {
      eventListener.remove();
    };
  }, []);

  return (
    <View style={styles.container}>
      <SafeAreaView>
        <ScrollView
          contentContainerStyle={{ flexGrow: 1, justifyContent: 'center' }}
        >
          <Text>
            is granted permissions:{' '}
            {`${
              permissionData != null ? JSON.stringify(permissionData) : 'none'
            }`}
          </Text>
          <Text>
            is monitoring started:{' '}
            {`${
              isMonitongStartedState != null
                ? JSON.stringify(isMonitongStartedState)
                : 'none'
            }`}
          </Text>
          <View
            style={{
              flex: 1,
              justifyContent: 'center',
              alignItems: 'center',
            }}
          >
            <Button
              title={'Location permission'}
              onPress={() =>
                requestPermissions()
                  .then((result) => {
                    console.log('Request permissions', result);
                  })
                  .catch((error) => {
                    console.log('Error when permissions requested', error);
                  })
                  .then((_) => {
                    return permissionsStatus();
                  })
                  .then((data) => {
                    setPermissionData(data);
                  })
                  .catch((error) => {
                    console.log('Error when check permissions', error);
                  })
              }
            />
            <Button
              title={'Stop monitoring'}
              onPress={() => {
                stopMonitoring()
                  .then((value) => {
                    console.log('Stopped monitoring', value);
                  })
                  .catch((error) => {
                    console.log('Error when stopped monitoring', error);
                  })
                  .then((_) => {
                    return isStartedMonitoring();
                  })
                  .then((value) => setMonitoringStarted(value))
                  .catch((error) => setMonitoringStarted(error.message));
              }}
            />
            <Button
              title={'Start monitoring'}
              onPress={() => {
                startMonitoring()
                  .then((value) => {
                    console.log('Started monitoring', value);
                  })
                  .catch((error) => {
                    console.log('Error when started monitoring', error);
                  })
                  .then((_) => {
                    return isStartedMonitoring();
                  })
                  .then((value) => setMonitoringStarted(value))
                  .catch((error) => setMonitoringStarted(error.message));
              }}
            />
            <Button
              title={'Add geofences'}
              onPress={() =>
                addGeofences(mockGeofences)
                  .then((value) => {
                    console.log('Added geofences', value);
                  })
                  .catch((error) => {
                    console.log('Error while adding geofences', error);
                  })
                  .then((_) => {
                    return isExistsGeofenceByListCoordinate([
                      { latitude: 40.7415, longitude: -74.0034, radius: 200 },
                      { latitude: 50, longitude: 50, radius: 300 },
                    ]);
                  })
                  .then((value) => {
                    console.log('Is exists coordinates', value);
                  })
                  .catch((error) => {
                    console.log('Error while check exists coordinates', error);
                  })
              }
            />
            <Button
              title={'Remove geofences'}
              onPress={() =>
                removeGeofences()
                  .then((value) => {
                    console.log('Remove geofences', value);
                  })
                  .catch((error) => {
                    console.log('Error while removing geofences', error);
                  })
                  .then((_) => {
                    return isStartedMonitoring();
                  })
                  .then((value) => setMonitoringStarted(value))
                  .catch((error) => setMonitoringStarted(error.message))
              }
            />
          </View>
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
