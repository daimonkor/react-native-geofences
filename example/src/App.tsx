import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import { multiply, stopMonitoring, startMonitoring } from 'react-native-geofences';

export default function App() {
  const [result, setResult] = React.useState<number | undefined>();

  React.useEffect(() => {
    multiply(3, 7).then(setResult);
    startMonitoring().then(count => {
      console.log(count)
    });
    stopMonitoring().then(count => {
      console.log(count)
    });
  }, []);

  return (
    <View style={styles.container}>
      <Text>Result: {result}</Text>
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
