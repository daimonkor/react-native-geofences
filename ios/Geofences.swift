import CoreLocation
import React

@objc(Geofences)
class Geofences: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    private var locationManager: CLLocationManager = CLLocationManager()
    private var requestLocationAuthorizationCallback: ((CLAuthorizationStatus) -> Void)?
   /* @objc(multiply:withB:withResolver:withRejecter:)
    func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) {
        resolve(a*b)
    }*/
    
    private override init() {
         super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self
    }

    @objc(startMonitoring:reject:)
    func startMonitoring(_ resolve:  RCTPromiseResolveBlock, reject:  RCTPromiseRejectBlock)  -> Void   {
       resolve(true)
    }

    @objc(stopMonitoring:reject:)
    func stopMonitoring(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        resolve(true)
    }
    
    @objc(requestPermissions:reject:)
    func requestPermissions(_ resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        self.requestLocationAuthorization( callback: { (status) in
            resolve(status.rawValue)
        })
//        var locationManager = CLLocationManager()
//        locationManager.requestAlwaysAuthorization()
//        locationManager.allowsBackgroundLocationUpdates = true
      //  resolve(true)
    }
    
    @objc(permissionsStatus:reject:)
    func permissionsStatus(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        let currentStatus = CLLocationManager.authorizationStatus()
        resolve( currentStatus.rawValue)
    }
    
    @objc(addGeofences:resolve:reject:)
    func addGeofences(_ geofenceHolder: NSDictionary, resolve: RCTPromiseResolveBlock,   reject: RCTPromiseRejectBlock) -> Void {
        resolve(geofenceHolder)
    }
    
    @objc(isExistsGeofenceById:id:resolve:)
    func isExistsGeofenceById(_ id: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        resolve(true)
    }
    
    @objc(isExistsGeofenceByCoordinate:coordinate:resolve:)
    func isExistsGeofenceByCoordinate(_ coordinate: NSDictionary, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        resolve(true)
    }
    
    @objc(removeGeofences:resolve:reject:)
    func removeGeofences(filter: NSArray, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        resolve(filter)
     }
    
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        self.requestLocationAuthorizationCallback?(status)
    }
    
    public func requestLocationAuthorization(callback: ((CLAuthorizationStatus) -> Void)?) {
       
        let currentStatus = CLLocationManager.authorizationStatus()

        // Only ask authorization if it was never asked before
        guard currentStatus == .notDetermined else { return }

        // Starting on iOS 13.4.0, to get .authorizedAlways permission, you need to
        // first ask for WhenInUse permission, then ask for Always permission to
        // get to a second system alert
        if #available(iOS 13.4, *) {
            self.requestLocationAuthorizationCallback = { status in
                print("SSSS", status.rawValue)
                if status == .authorizedWhenInUse {
                    self.locationManager.requestAlwaysAuthorization()
                   
                }else{
                    callback?(status)
                }
            }
            self.locationManager.requestWhenInUseAuthorization()
        } else {
            self.locationManager.requestAlwaysAuthorization()
        }
    }
}


//
//class LocationManager: NSObject, CLLocationManagerDelegate {
//    static let shared = LocationManager()
//    private var locationManager: CLLocationManager = CLLocationManager()
//    private var requestLocationAuthorizationCallback: ((CLAuthorizationStatus) -> Void)?
//
//    private override init() {
//         super.init()
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.allowsBackgroundLocationUpdates = true
//         locationManager.delegate = self
//    }
//
//    public func requestLocationAuthorization(callback: ((CLAuthorizationStatus) -> Void)?) {
//
//        let currentStatus = CLLocationManager.authorizationStatus()
//
//        // Only ask authorization if it was never asked before
//        guard currentStatus == .notDetermined else { return }
//
//        // Starting on iOS 13.4.0, to get .authorizedAlways permission, you need to
//        // first ask for WhenInUse permission, then ask for Always permission to
//        // get to a second system alert
//        if #available(iOS 13.4, *) {
//            self.requestLocationAuthorizationCallback = { status in
//                print("SSSS", status)
//                if status == .authorizedWhenInUse {
//                    self.locationManager.requestAlwaysAuthorization()
//
//                }else{
//                    callback?(status)
//                }
//            }
//            self.locationManager.requestWhenInUseAuthorization()
//        } else {
//            self.locationManager.requestAlwaysAuthorization()
//        }
//    }
//    // MARK: - CLLocationManagerDelegate
//
//    func locationManager(_ manager: CLLocationManager,
//                         didChangeAuthorization status: CLAuthorizationStatus) {
//        self.requestLocationAuthorizationCallback?(status)
//    }
//}
