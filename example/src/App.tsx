import * as React from 'react';

import { StyleSheet, View, Text, Button, Platform } from 'react-native';
import {
  stopMonitoring,
  startMonitoring,
  addGeofences,
  NotificationData,
  requestPermissions,
  isAcceptedPermissions,
  removeGeofences,
  isExistsGeofenceById,
  TypeTransactions,
  InitialTriggers,
} from 'react-native-geofences';

export default function App() {
  const [result, setResult] = React.useState<number | undefined>();

  React.useEffect(() => {
    //multiply(3, 7).then(setResult);
    addGeofences({
      geofences: [
        {
          position: { latitude: 40.7415, longitude: -74.0034, radius: 200 },
          name: 'First point',
          expiredDuration: 30000000,
          typeTransactions: [
            {
              type: TypeTransactions.ENTER,
              notification: {
                message: 'Enter to first point',
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
                actionUri: 'https://test.com',
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
          name: 'Second point',
          expiredDuration: 30000000,
          typeTransactions: [
            {
              type: TypeTransactions.EXIT,
              notification: {
                message: 'Exit from second point',
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
                message: 'Enter to second point',
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
    });
    // .then((value) => {
    //   return startMonitoring();
    // })
    // .then((count) => {
    //   console.log('start monitoring', count);
    //   return isExistsGeofenceById('3d3d6602-2852-44ce-9bd6-bc294ef849c');
    // })
    // .then((count) => {
    //   console.log('is exists', count);
    // })
    // .catch((error) => {
    //   console.log('ERROR', error);
    // });
    // stopMonitoring().then((count) => {
    //   console.log('start monitoring', count);
    // });
  }, []);

  return (
    <View style={styles.container}>
      <Text>Result: {result}</Text>
      <Button
        title={'Location permission'}
        onPress={() =>
          requestPermissions()
            .then((result) => {
              console.log(result);
            })
            .catch((error) => {
              console.log('ERROR REQUEST', error);
            })
            .then((result2) => {
              console.log('check permission');
              console.log(result2);
              return isAcceptedPermissions();
            })
            .catch((error) => {
              console.log('ERROR', error);
            })
        }
      />
      <Button
        title={'Stop monitoring'}
        onPress={() =>
          stopMonitoring()
            .then((value) => {
              console.log('STOPPED', value);
            })
            .catch((error) => {
              console.log('ERROR', error);
            })
        }
      />
      <Button
        title={'Start monitoring'}
        onPress={() =>
          startMonitoring()
            .then((value) => {
              console.log('STARTED', value);
            })
            .catch((error) => {
              console.log('ERROR', error);
            })
        }
      />
      <Button
        title={'Remove geofences'}
        onPress={() =>
          removeGeofences()
            .then((value) => {
              console.log('REMOVED GEOFENCES', value);
            })
            .catch((error) => {
              console.log('ERROR', error);
            })
        }
      />
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
