import * as React from 'react';

import { StyleSheet, View, Text, Button } from 'react-native';
import {
  stopMonitoring,
  startMonitoring,
  addGeofences,
  NotificationData,
  requestPermissions,
  isAcceptedPermissions,
  removeGeofences,
  isExistsGeofenceById,
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
              type: 1,
              notification: {
                message: 'Enter to first point',
                request: 'https://test1.com',
              } as NotificationData,
            },

            {
              type: 2,
              notification: {
                message: 'Exit from first point',
                request: 'https://test.com',
              } as NotificationData,
            },
          ],
        },

        {
          position: { latitude: 50, longitude: 50, radius: 300 },
          name: 'Second point',
          expiredDuration: 30000000,
          typeTransactions: [
            {
              type: 0,
              notification: {
                message: 'Enter to second point',
                request: 'deeplink',
              } as NotificationData,
            },

            {
              type: 1,
              notification: {
                message: 'Exit from second point',
                request: 'deeplink',
              } as NotificationData,
            },
          ],
        },
      ],
      initialTriggers: [0, 1, 2],
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
