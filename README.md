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

The App also needs to ask locations permission in react-native for iOS. You can fire a function like this in the App's *componentWillMount* hook:

```ts
import {requestPermissions} from "react-native-geofences";

async function requestLocationPermission() {
  try {
    const permissionsData = await requestPermissions();
    if (permissionsData.code === '4') {
      console.log("Granted Permission")
    } else {
      console.log("Denied Permission")
    }
  } catch (err) {
    console.warn(err)
  }
}
```

### Android

The App also needs to ask for permission in react-native since *Android 6.0 (API level 23)*. You can fire a function like this in the App's *componentWillMount* hook:

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

| method 	             | arguments 	                                            | notes                                                                                                                                                   | return data                               |
| -------------        |--------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------|
| ```requestPermissions``` | ```ratinale: Rationale``` (configure only for Android) | Current function call request important permissions, please grant \`*Always allow*\` #**IMPORTANT**# permission too                                     | ```Promise<PermissionData>```             |
| ```permissionsStatus```  |                                                        | Get permissions status                                                                                                                                  | ```Promise<PermissionData>```             |
| ```addGeofences```  | ```geofencesHolder: GeofenceHolder```                  | Add geofences with ```initialTrigger``` (enter or exit) to application cache                                                                            | ```Promise<GeofenceHolder>```             |
| ```isExistsGeofenceById``` | ```id: string?```                                      | Check if geofence\`s object exists by id into cache                                                                                                     | ```Promise<boolean>```                    |
| ```isExistsGeofenceByListId``` | ```ids: string[]```                                    | Check if geofence\`s object exists by ids list into cache (longitude, latitude, radius)                                                                 | ```Promise<boolean>```                    |
| ```isExistsGeofenceByCoordinate``` | ```coordinate: Coordinate?```                          | Check if geofence\`s object exists by coordinate  into cache (longitude, latitude, radius)                                                              | ```Promise<boolean>```                    |
| ```isExistsGeofenceByListCoordinate```| ```coordinates: Coordinate[]```                        | Check if geofence\`s object exists by list coordinates into cache (longitude, latitude, radius)                                                         | ```Promise<boolean>```                    |
|```removeGeofences```  | ```filter: string[] = []```                            | Remove geofences from cache with filtering; empty filter - remove all geofences from cache                                                              | ```Promise<boolean>```                    |
| ```startMonitoring``` |                                                        | Start monitong geofences, using cached geofences, #**IMPORTANT**# when user will start monitoring, application immediate stop monitoring created before | ```Promise<string[]>```                   |
| ```isStartedMonitoring```|                                                        | Check status monitoring geofences - started or no                                                                                                       | ```Promise<boolean>```|
| ```stopMonitoring``` |                                                        | Stop monitoring                                                                                                                                         | ```Promise<boolean>```                    |
| ```requestNotificationPermission``` | ```options: NotificationOption[]```                    | Request iOS Notification permissions                                                                                                                    | ```Promise<NotificationPermissionData>```
| ```notificationPermissionStatus``` |                                                        | Get notification permissions status (for Android fake data)                                                                                             | ```Promise<NotificationPermissionData>```
| ```clearIconBadgeNumber``` |                                                        | Clear badge number (iOS)                                                                                                                                | ```Promise<boolean>```

## Types

```ts
type AndroidInitialTriggersType = 1 | 2 | 4;
type AndroidTypeTransactionsType = 1 | 2 | 4;

type IOSInitialTriggersType = 1 | 2 | 4;
type IOSTypeTransactionsType = 1 | 2 | 4;

export enum InitialTriggers {
  ENTER = 1 as AndroidInitialTriggersType | IOSInitialTriggersType,
  EXIT = 2 as AndroidInitialTriggersType | IOSInitialTriggersType,
  DWELL = 4 as AndroidInitialTriggersType | IOSInitialTriggersType,
}

export enum TypeTransactions {
  ENTER = 1 as AndroidTypeTransactionsType | IOSTypeTransactionsType,
  EXIT = 2 as AndroidTypeTransactionsType | IOSTypeTransactionsType,
  DWELL = 4 as AndroidTypeTransactionsType | IOSTypeTransactionsType,
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
    type: TypeTransactions;
    notification?: NotificationData | null;
    extraData?: Object | null;
  }[];
  expiredDuration: number;
}

export interface GeofenceHolder {
  initialTriggers?: InitialTriggers[];
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

Register your service at react native *AndroidManifest.xml*

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

### iOS


For catching geofence events at AppDelegate it needed add to *AppDelegate.h*:

```ts
#import "Geofences-Bridging-Header.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, RCTBridgeDelegate, GeofenceDelegate>
```
implement *GeofenceDelegate*

*AppDelegate.m*:

```ts

//#import "GeofencesExample-Swift.h"
.....

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
 .........
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  center.delegate = self;
  return YES;
}

- (void) geofenceEvent:(NSDictionary *) geofenceModel geofenceManager: (id<GeofenceManagment>) geofenceManager  {
  /***
   * geofenceManager contains interface to control geofence monitong
   * geofenceModel contains object with full information about geofence event (model and typeTransaction)
   */

  // GeofencesHelper* request = [ [GeofencesHelper alloc] init];
  // [request requestWithGeofenceModel:geofenceModel geofenceManager:geofenceManager];
}

- (void)onInitGeofencesModule:(id<GeofenceManagment>)geofenceManager {
  /**
   * Support dynamic register new custom event to react-native-geofences library
   */
  [geofenceManager addCustomEvent:@"onStopShiftByServer"];
}

```

Library support configure local push notification on geofence event (enter/exit)

*AppDelegate.h*
```ts
#import <UserNotifications/UserNotifications.h>
#import "Geofences-Bridging-Header.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, RCTBridgeDelegate, UNUserNotificationCenterDelegate, GeofenceDelegate>

 ```
*AppDelegate.m*
```ts
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
  /**
   If your app is in the foreground when a notification arrives, the notification center calls this method to deliver the notification directly to your app. If you implement this method, you can take whatever actions are necessary to process the notification and update your app. When you finish, execute the completionHandler block and specify how you want the system to alert the user, if at all.

   If your delegate does not implement this method, the system silences alerts as if you had passed the UNNotificationPresentationOptionNone option to the completionHandler block. If you do not provide a delegate at all for the UNUserNotificationCenter object, the system uses the notification’s original options to alert the user.
   see https://developer.apple.com/reference/usernotifications/unusernotificationcenterdelegate/1649518-usernotificationcenter?language=objc
   **/
  NSLog(@"willPresentNotification %@", notification.request.content.userInfo);
  completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
  /**
   Use this method to perform the tasks associated with your app’s custom actions. When the user responds to a notification, the system calls this method with the results. You use this method to perform the task associated with that action, if at all. At the end of your implementation, you must call the completionHandler block to let the system know that you are done processing the notification.

   You specify your app’s notification types and custom actions using UNNotificationCategory and UNNotificationAction objects. You create these objects at initialization time and register them with the user notification center. Even if you register custom actions, the action in the response parameter might indicate that the user dismissed the notification without performing any of your actions.

   If you do not implement this method, your app never responds to custom actions.

   see https://developer.apple.com/reference/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter?language=objc
   **/

  NSLog(@"didReceiveNotificationResponse: didReceiveNotificationResponse: withCompletionHandler %@", response.notification.request.content.userInfo);

  /**
   * it needed add custom function openUrl (if needed support click on local push notification), url contains into  userInfo?["actionUrl"]
   */

  //[GeofencesHelper openUrlWithNotification: response.notification];

  completionHandler();
}
```
Add to *info.plist*

```
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>GeofencesExample requires constant access to your phone’s location to notify you when you enter or leave a geofence.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>GeofencesExample requires constant access to your phone’s location to notify you when you enter or leave a geofence.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>GeofencesExample requires constant access to your phone’s location to notify you when you enter or leave a geofence.</string>
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string> <--- for background http requests --->
  <string>location</string>
  <string>processing</string> <--- support scheduler background tasks --->
  <string>remote-notification</string>  <--- add support remore notifications --->
</array>
```
Optional - add support swift classes to main project https://medium.com/ios-os-x-development/swift-and-objective-c-interoperability-2add8e6d6887 , and create *GeofencesHelper*

```ts
//
//  GeofencesHelper.swift
//  GeofencesExample
//
//  Created by Dima on 17.01.2022.
//

import Foundation

enum AppError: Error {
  case networkError(Error)
  case dataNotFound
  case jsonParsingError(Error)
  case invalidStatusCode(Int)
}

enum Result<T> {
  case success(T)
  case failure(AppError)
}

struct CodingKeys: CodingKey {
  var stringValue: String
  init(stringValue: String) {
    self.stringValue = stringValue
  }
  var intValue: Int?
  init?(intValue: Int) {
    return nil
  }
}

class ResponseModel: Decodable{
  let id: String?

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try? container.decode(String.self, forKey: CodingKeys(stringValue: "id"))
  }
}


@objc(GeofencesHelper)
class GeofencesHelper: NSObject {
  static let STOP_SHIFT_KEY = "STOP_SHIFT_KEY"

  override init(){
    super.init()
  }

  @objc static func openUrl(notification: UNNotification?){
    let userInfo = notification?.request.content.userInfo;
    let siteURL = userInfo?["actionUrl"] as? String;
    if(siteURL != nil){
      guard let url = URL(string: siteURL!) else {
        return //be safe
      }

      if #available(iOS 10.0, *) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      } else {
        UIApplication.shared.openURL(url)
      }
    }
  }

  @objc
  public func request(geofenceModel: NSDictionary, geofenceManager: GeofenceManagment ){
    DispatchQueue.main.async {
      let typeTransactions = (geofenceModel["GEOFENCES_LIST_KEY"] as? [String: Any?])?["typeTransactions"] as? [String: Any?]
      if(geofenceModel["TRANSITION_TYPE_KEY"] != nil){
        let extraData = (typeTransactions?[String(geofenceModel["TRANSITION_TYPE_KEY"] as! Int)] as? [String: Any?])?["extraData"] as? [String: Any?]
        let url = extraData?["url"] as? String
        let headers = extraData?["headers"]
        let body = extraData?["body"]
        if(url != nil){
          self.dataRequest(with: url!, headers: headers as? [String: Any?], body: body as? [String: Any?], objectType: ResponseModel.self, completion: {result in
            switch result {
              case .success(let success):
                print("Response success", success.id)
              case .failure(let error):
                print("Response error", error.localizedDescription)
            }
            //          geofenceManager.sendEvent("onStopShiftByServer", body: [GeofencesHelper.STOP_SHIFT_KEY: true])
            //          geofenceManager.stopMonitoring { data in
            //
            //          } reject: { code, message, error in
            //
            //
          })
        }
      }
    }
  }

  func dataRequest<T: Decodable>(with url: String, headers: [String: Any?]?, body: [String: Any?]?, objectType: T.Type, completion: @escaping (Result<T>) -> Void) {
    let dataURL = URL(string: url)!
    let session = URLSession.shared
    var request = URLRequest(url: dataURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
    headers?.forEach({ (key: String, value: Any?) in
      request.addValue(key, forHTTPHeaderField: value as? String ?? "")
    })
    let jsonData = try? JSONSerialization.data(withJSONObject: body)
    if(jsonData != nil){
       request.httpBody = jsonData
    }
    request.httpMethod = "POST"
    print("Request: \(request)")

    let task = session.dataTask(with: request, completionHandler: { data, response, error in
      guard error == nil else {
        completion(Result.failure(AppError.networkError(error!)))
        return
      }
      guard let data = data else {
        completion(Result.failure(AppError.dataNotFound))
        return
      }
      do {
        let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
         if let responseJSON = responseJSON as? [String: Any] {
             print("Response json", responseJSON)
         }
        let decodedObject = try JSONDecoder().decode(objectType.self, from: data)
        completion(Result.success(decodedObject))
      } catch let error {
        completion(Result.failure(AppError.jsonParsingError(error as! DecodingError)))
      }
    })
    task.resume()
  }
}

```

Add into *GeofencesExample-Bridginbg-Header.h* import geofences library protocols

```ts
#import "Geofences-Bridging-Header.h"
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
