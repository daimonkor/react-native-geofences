# react-native-geofences

The library helps to create and manage geofences.

## Restrictions

**iOS**

Needs iOS 10 or higher with support Swift 5

**Android**

Needs a minSdkVersion 21 and Kotlin react native project

## Installation

```sh
npm install https://github.com/daimonkor/react-native-geofences.git
```
or

```sh
yarn add https://github.com/daimonkor/react-native-geofences.git
```

## Usage

```ts
import { requestPermissions, startMonitoring, addGeofences } from "react-native-geofences";

// ...

const permissionsData = await requestPermissions();
const geofences = {
  geofences: [
    {
      position: { latitude: 40.7415, longitude: -74.0034, radius: 200 },
      name: 'First point',
      expiredDuration: 30000000,
      typeTransactions: [
        {
          type: TypeTransactions.ENTER,
          notification: {
            message: null, 
            actionUri: 'https://test.com',
          } as NotificationData,
          extraData: {
            headers: {
              token: 'TOKEN',
              appId: 'APP_ID',
            },
            body: { id: 10, state: 'enter' },
            url: 'https://test.com',
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
              token: 'TOKEN',
              appId: 'APP_ID',
            },
            body: { id: 10, state: 'exit' },
            url: 'https://test.com',
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
            actionUri: 'app://com.test',
          } as NotificationData,
        },

        {
          type: TypeTransactions.EXIT,
          notification: {
            message: 'Exit from second point',
            actionUri:  null,
          } as NotificationData,
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

  addGeofences(geofences)
      .then((value) => {
        console.log('Added geofences', value);
        return startMonitoring()
      })
      .catch((error) => {
        console.log('Error', error);
      })
```

## Permissions

### iOS
***In develop***

### Android

The App also needs to ask for permission in react-native since *Android 6.0 (API level 23)*. You can fire a function like this in the App's componentWillMount hook:

```ts
import {requestPermissions} from "react-native-geofences";

async function requestLocationPermission() {
  try {
    const permissionsData = await requestPermissions();
    if (permissionsData.code === 'ALL_GRANTED') {
      console.log("Granted Permission")
    } else {
      console.log("Denied Permission")
    }
  } catch (err) {
    console.warn(err)
  }
}
```

## Methods

| method 	             |   arguments 	| notes  | return data |
| -------------        | ------------- | --------|------ |
| ```requestPermissions``` | | Current function call request important permissions, please grant \`*Always allow*\` #**IMPORTANT**# permission too | ```Promise<PermissionData>``` |
| ```permissionsStatus```  | | Get permissions status | ```Promise<PermissionData>``` |
| ```addGeofences```  | ```geofencesHolder: GeofenceHolder``` | Add geofences with ```initialTrigger``` (enter or exit) to application cache| ```Promise<GeofenceHolder>``` |
| ```isExistsGeofenceById``` |  ```id: string?``` | Check if geofence\`s object exists by id into cache |```Promise<boolean>``` |
| ```isExistsGeofenceByCoordinate``` | ```coordinate: Coordinate?``` | Check if geofence\`s object exists by coordinate  into cache (longitude, latitude, radius) | ```Promise<boolean>``` |
|```removeGeofences```  | ```filter: string[] = []``` | Remove geofences from cache with filtering; empty filter - remove all geofences from cache | ```Promise<boolean>``` |
| ```startMonitoring``` |  | Start monitong geofences, using cached geofences, #**IMPORTANT**# when user will start monitoring, application immediate stop monitoring created before  | ```Promise<string[]>``` |
| ```stopMonitoring``` |  | Stop monitoring | ```Promise<boolean>``` |

## Types

```ts
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

```

## Use cases

### Android

Create *JobService* to catch geofence\`s event at react native main module (app)

```kotlin
class OnGeofenseEventService : JobService() {
 
  override fun onStartJob(params: JobParameters?): Boolean {
    try {
      val transitionType = params?.extras?.getInt(TRANSITION_TYPE_KEY) //Transition event type ON_ENTER/ON_EXIT/DWELL
      val geofencesList = params?.extras?.getString(GEOFENCES_LIST_KEY)?.let { //Full geofences list at cache
        Gson().fromJson<Array<GeofenceModel>>(
          it,
          object : TypeToken<Array<GeofenceModel>>() {}.type
        )
      }
      geofencesList?.map {
        it.typeTransactions.entries
      }?.forEach {
        it.filter {
          it.key.typeTransaction == transitionType
        }.forEach {     
          Timber.e("Geofence: $it $transitionType")
        }
      }
      /*val action =
        geofencesList?.get(0)?.typeTransactions?.get(TypeTransactions.toValue(transitionType))
      val toast = Toast.makeText(
        this.applicationContext,
        action?.first?.message + " " + action?.first?.actionUri, Toast.LENGTH_LONG
      )
      toast.show()*/
    }catch (exception: Exception){
      Timber.e("Error at service: %s", exception)
    }
    return true
  }

  override fun onStopJob(params: JobParameters?): Boolean {
    return true
  }
}
```

Add to react native android *AndroidManifest.xml* current strings

```xml
<service
    android:name=".OnGeofenseEventService"
    android:enabled="true"
    android:exported="false"
  android:permission="android.permission.BIND_JOB_SERVICE"/>

<meta-data
    android:name="GEOFENCE_SERVICE_PACKAGE_NAME"
    android:value="com.example.reactnativegeofences" /> <!--Your package name jobservice -->
<meta-data
    android:name="GEOFENCE_SERVICE_CLASS_NAME"
    android:value="com.example.reactnativegeofences.OnGeofenseEventService" /> <!--Your class name jobservice -->

<!-- <meta-data --> <!--Additional option override notification small icon library at main react native module (app) -->
<!-- tools:replace="android:resource" -->
<!-- android:name="notification_small_icon" -->
<!-- android:resource="@mipmap/ic_launcher" /> --> <!--Your or Android OS drawable or mipmap 
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
