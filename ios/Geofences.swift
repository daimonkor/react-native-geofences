import CoreLocation
import React
import Accelerate
import UserNotifications
import UIKit

enum ErrorImpl: Error {
    case error(code: Int, message: String, error: NSError? = nil)
}

class GeofenceMonitoringStatus{
    private var neededStartGeofencesCount: Int = 0
    private var startedGeofencesCount: Int = 0
    private (set) var isStartedMonitoring: Bool = false
    var callback : ((_ error: Error?) -> Void)?
    
    func isAllStartedGeofencesMonitoring () -> Bool{
        return startedGeofencesCount >= neededStartGeofencesCount
    }
    
    func reset(){
        self.neededStartGeofencesCount = 0
        self.startedGeofencesCount = 0
        self.isStartedMonitoring = false
        self.callback = nil
    }
    
    func start(neededStartGeofencesCount: Int){
        self.neededStartGeofencesCount = neededStartGeofencesCount
    }
    
    func addStartGeofenceCounter(){
        self.startedGeofencesCount += 1
        self.isStartedMonitoring = true
    }
    
    func stop(){
        self.callback?(nil)
        self.reset()
    }
    
    func error(error: Error){
        self.callback?(error)
        self.reset()
    }
    
    init(){}
}

@objc(Geofences)
class Geofences: RCTEventEmitter, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    private var locationManager: CLLocationManager = CLLocationManager()
    private var requestLocationAuthorizationCallback: ((CLAuthorizationStatus) -> Void)?
    private var hasListeners = false;
    private var mGeofencesHolderList = Array<GeofenceHolderModel>()
    private var geofenceMonitoringStatus = GeofenceMonitoringStatus()
    
    private override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self
    }
    
    override func startObserving() {
        hasListeners = true;
        // Set up any upstream listeners or background tasks as necessary
    }
    
    // Will be called when this module's last listener is removed, or on dealloc.
    override func stopObserving() {
        hasListeners = false;
        // Remove upstream listeners, stop unnecessary background tasks
    }
    
    @objc open override func supportedEvents() -> [String] {
        return ["onGeofenceEvent"]
    }
    
    @objc(startMonitoring:reject:)
    func startMonitoring( _ resolve :  @escaping RCTPromiseResolveBlock, reject:  @escaping RCTPromiseRejectBlock)  -> Void   {
        do{
            try {
                let countGeofences = self.mGeofencesHolderList.map{ holder in
                    holder.geofenceModels
                }.joined().count
                print("Count geofences \(countGeofences)")
                self.geofenceMonitoringStatus.start(neededStartGeofencesCount: countGeofences)
                self.geofenceMonitoringStatus.callback = { error in
                    if(error != nil){
                        reject("1", "Error while starting geofence monitoring", error)
                    }else{
                        resolve(true)
                    }
                    self.geofenceMonitoringStatus.callback = nil
                }
                if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
                    print(
                        "Geofencing is not supported on this device!")
                    throw ErrorImpl.error(code: 0, message: "Geofencing is not supported on this device!")
                }
                
                for geofencesHolder in self.mGeofencesHolderList {
                    for geofenceModel in geofencesHolder.geofenceModels{
                        self.locationManager.startMonitoring(for: geofenceModel.convertToCLCircularRegion())
                    }
                }
                self.locationManager.requestLocation()
            }()
        }catch {
            self.geofenceMonitoringStatus.error(error: error)
        }
    }
    
    @objc(stopMonitoring:reject:)
    func stopMonitoring(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock)  -> Void  {
        self.geofenceMonitoringStatus.callback = { error in
            if(error != nil){
                reject("1", "Error while stop geofence monitoring", error)
            }else{
                resolve(true)
            }
        }
        for region in locationManager.monitoredRegions {
            for geofencesHolder in self.mGeofencesHolderList {
                for geofenceModel in geofencesHolder.geofenceModels{
                    if(geofenceModel.id == region.identifier){
                        locationManager.stopMonitoring(for: region)
                    }
                }
            }
        }
        self.geofenceMonitoringStatus.callback?(nil)
    }
    
    private func stopAllMonitoredRegions(){
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    @objc(requestPermissions:reject:)
    func requestPermissions(_ resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        self.requestLocationAuthorization( callback: { (status) in
            resolve(status.rawValue)
            return
        })
        //TODO: sample send event
        //        if(self.hasListeners){
        //            self.sendEvent(withName: "onGeofenceEvent", body: ["test": 1])
        //        }
    }
    
    @objc(permissionsStatus:reject:)
    func permissionsStatus(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        let currentStatus = CLLocationManager.authorizationStatus()
        resolve( currentStatus.rawValue)
    }
    
    @objc(clearIconBadgeNumber:reject:)
    func clearIconBadgeNumber(_ resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        resolve(true)
    }
    
    @objc(notificationPermissionStatus:reject:)
    func notificationPermissionStatus(_ resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let result = NSMutableDictionary ();
            if (settings.alertSetting != UNNotificationSetting.notSupported) {
                let value = settings.alertSetting == UNNotificationSetting.enabled;
                result["alert"] = value
            }
            if (settings.badgeSetting != UNNotificationSetting.notSupported) {
                let value = settings.badgeSetting == UNNotificationSetting.enabled;
                result["badge"] = value
            }
            if (settings.soundSetting != UNNotificationSetting.notSupported) {
                let value = settings.soundSetting == UNNotificationSetting.enabled;
                result["sound"] = value
            }
            if (settings.lockScreenSetting != UNNotificationSetting.notSupported) {
                let value = settings.lockScreenSetting == UNNotificationSetting.enabled;
                result["lockScreen"] = value
            }
            if (settings.carPlaySetting != UNNotificationSetting.notSupported) {
                let value = settings.carPlaySetting == UNNotificationSetting.enabled;
                result["carPlay"] = value
            }
            if (settings.notificationCenterSetting !=  UNNotificationSetting.notSupported) {
                let value = settings.notificationCenterSetting == UNNotificationSetting.enabled
                result["notificationCenter"] = value
            }
            if #available(iOS 12.0, *) {
                let provisionalValue = settings.authorizationStatus == UNAuthorizationStatus.provisional;
                result["provisional"] = provisionalValue
                if (settings.criticalAlertSetting != UNNotificationSetting.notSupported) {
                    let value = settings.criticalAlertSetting == UNNotificationSetting.enabled;
                    result["criticalAlert"] = value
                }
            }
            let finalResult = NSMutableDictionary()
            finalResult["settings"] = result
            finalResult["authorizationStatus"] = settings.authorizationStatus.rawValue
            resolve(finalResult)
        }
    }
    
    @objc(requestNotificationPermission:resolve:reject:)
    func requestNotificationPermission(options: NSArray, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock)  -> Void  {
        let alert = options.contains("alert");
        let badge = options.contains("badge");
        let sound = options.contains("sound");
        let criticalAlert = options.contains("criticalAlert");
        let carPlay = options.contains("carPlay");
        let provisional = options.contains("provisional");
        var types: UNAuthorizationOptions = []
        if (alert) {
            types.insert(UNAuthorizationOptions.alert)
        }
        if (badge) {
            types.insert(UNAuthorizationOptions.badge)
        }
        if (sound) {
            types.insert(UNAuthorizationOptions.sound)
        }
        if (carPlay) {
            types.insert(UNAuthorizationOptions.carPlay)
        }
        if #available(iOS 12.0, *) {
            if (criticalAlert) {
                types.insert(UNAuthorizationOptions.criticalAlert)
            }
            if (provisional) {
                types.insert(UNAuthorizationOptions.provisional)
            }
        }
        if (!alert &&
            !badge &&
            !sound &&
            !criticalAlert &&
            !carPlay &&
            !provisional) {
            types.insert(UNAuthorizationOptions.alert);
            types.insert(UNAuthorizationOptions.badge);
            types.insert(UNAuthorizationOptions.sound);
        }
        UNUserNotificationCenter.current().requestAuthorization(options: types) { granted, error in
            if (error != nil) {
                return reject("22", error?.localizedDescription ?? "Error while requesting permission", error);
            }
            if (granted) {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications();
                }
            }
            self.notificationPermissionStatus(_: resolve, reject: reject)
        }
    }
    
    @objc(addGeofences:resolve:reject:)
    func addGeofences(_ geofenceHolder: NSDictionary, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        print(geofenceHolder)
        let geofencesList = geofenceHolder["geofences"] as? Array<Any>
        let initialTriggers: Array<InitialTriggers>? = (geofenceHolder["initialTriggers"] as? Array<Int>)?.map{ element in
            InitialTriggers(rawValue: element as Int)!
        }
        let geofenceHolderModel = GeofenceHolderModel()
        if(initialTriggers != nil){
            geofenceHolderModel.initialTriggers = initialTriggers!
        }
        geofencesList?.forEach { item in
            let castItem = item as! NSDictionary
            let position = castItem["position"] as! NSDictionary
            var transactionTypes: [TypeTransactions : (NotificationDataModel?, [String: Any?])] = [:]
            (castItem["typeTransactions"] as! Array<Any>).forEach{ element in
                let notificationDataModel = ((element as? NSDictionary )?["notification"]).map {
                    NotificationDataModel(message: ( ($0 as? NSDictionary)?["message"] as? String) ?? nil, actionUri: ( ($0 as? NSDictionary)?["actionUri"] as? String) ?? nil)
                } ?? NotificationDataModel(message: nil, actionUri: nil)
                let key = TypeTransactions(rawValue: ((element as? NSDictionary)?["type"] as? Int) ?? TypeTransactions.UNKNOWN.rawValue)!
                let value = (notificationDataModel, (element as? NSDictionary )?["extraData"]  as? [String: Any?] ?? [:])
                transactionTypes[key] = value
            }
            geofenceHolderModel.geofenceModels.append(GeofenceModel(position: Coordinate(longitude: position["longitude"] as! Double, latitude: position["latitude"] as! Double, radius:position["radius"] as! Int), name: castItem.object(forKey: "name") as? String ?? "noname", id: self.generateId(), typeTransactions: transactionTypes))
        }
        self.mGeofencesHolderList.append(geofenceHolderModel)
        resolve(geofenceHolder)
    }
    
    @objc(isExistsGeofenceById:resolve:reject:)
    func isExistsGeofenceById(id: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        resolve(self.mGeofencesHolderList.map { holder in
            holder.geofenceModels
        }.joined().first(where: {item in item.id == id}) != nil)
    }
    
    @objc(isExistsGeofenceByListId:resolve:reject:)
    func isExistsGeofenceByListId(ids: NSArray, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        resolve(true)
    }
    
    @objc(isExistsGeofenceByCoordinate:resolve:reject:)
    func isExistsGeofenceByCoordinate(coordinate: NSDictionary, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        resolve(true)
    }
    
    @objc(isExistsGeofenceByListCoordinate:resolve:reject:)
    func isExistsGeofenceByListCoordinate(coordinates: NSArray, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        resolve(true)
    }
    
    @objc(removeGeofences:resolve:reject:)
    func removeGeofences(filter: NSArray, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock)  -> Void  {
        self.geofenceMonitoringStatus.callback = { error in
            if(error != nil){
                reject("1", "Error while remove geofences and stop monitoring", error)
            }else{
                resolve(filter)
            }
        }
        self.stopAllMonitoredRegions()
        self.mGeofencesHolderList.removeAll()
        self.geofenceMonitoringStatus.callback?(nil)
    }
    
    @objc(isStartedMonitoring:reject:)
    func isStartedMonitoring(_ resolve:  RCTPromiseResolveBlock, reject:  RCTPromiseRejectBlock)  -> Void   {
        resolve(self.geofenceMonitoringStatus.isStartedMonitoring)
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        self.requestLocationAuthorizationCallback?(status)
    }
    
    public func requestLocationAuthorization(callback: ((CLAuthorizationStatus) -> Void)?) {
        /*
         // User has not yet made a choice with regards to this application
         case notDetermined = 0
         
         
         // This application is not authorized to use location services.  Due
         // to active restrictions on location services, the user cannot change
         // this status, and may not have personally denied authorization
         case restricted = 1
         
         
         // User has explicitly denied authorization for this application, or
         // location services are disabled in Settings.
         case denied = 2
         
         
         // User has granted authorization to use their location at any
         // time.  Your app may be launched into the background by
         // monitoring APIs such as visit monitoring, region monitoring,
         // and significant location change monitoring.
         //
         // This value should be used on iOS, tvOS and watchOS.  It is available on
         // MacOS, but kCLAuthorizationStatusAuthorized is synonymous and preferred.
         @available(iOS 8.0, *)
         case authorizedAlways = 3
         
         
         // User has granted authorization to use their location only while
         // they are using your app.  Note: You can reflect the user's
         // continued engagement with your app using
         // -allowsBackgroundLocationUpdates.
         //
         // This value is not available on MacOS.  It should be used on iOS, tvOS and
         // watchOS.
         @available(iOS 8.0, *)
         case authorizedWhenInUse = 4
         */
        
        let currentStatus = CLLocationManager.authorizationStatus()
        if(currentStatus == .authorizedAlways){
            callback?(currentStatus)
            self.requestLocationAuthorizationCallback = nil
            return
        }  else {
            self.requestLocationAuthorizationCallback = { status in
                callback?(status)
                self.requestLocationAuthorizationCallback = nil
            }
        }
        self.locationManager.requestAlwaysAuthorization()
    }
    
    private func generateId() -> String {
        return UUID().uuidString
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {
        if region is CLCircularRegion {
            checkGeofenceEvent(coordinate: (region as! CLCircularRegion).center, typeTransaction: TypeTransactions.ENTER)
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didExitRegion region: CLRegion
    ) {
        if region is CLCircularRegion {
            checkGeofenceEvent(coordinate: (region as! CLCircularRegion).center, typeTransaction: TypeTransactions.EXIT)
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        monitoringDidFailFor region: CLRegion?,
        withError error: Error
    ) {
        self.geofenceMonitoringStatus.callback?(error)
        guard let region = region else {
            print("Monitoring failed for unknown region")
            return
        }
        print("Monitoring failed for region with identifier: \(region.identifier), \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion){
        print("Monitoring started for region with identifier: \(region.identifier)")
        self.geofenceMonitoringStatus.addStartGeofenceCounter()
        if(self.geofenceMonitoringStatus.isAllStartedGeofencesMonitoring()){
            self.geofenceMonitoringStatus.callback?(nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
    }
    
    private func checkGeofenceEvent(coordinate: CLLocationCoordinate2D, typeTransaction: TypeTransactions = TypeTransactions.UNKNOWN, isInitial: Bool = false){
        DispatchQueue.global(qos: .default).async {
            for geofencesHolder in self.mGeofencesHolderList {
                if(geofencesHolder.initialTriggers.count > 0 && isInitial || !isInitial){
                    print("Contains initial triggers")
                    for geofenceModel in geofencesHolder.geofenceModels{
                        let region = geofenceModel.convertToCLCircularRegion() as! CLCircularRegion
                        if(isInitial){
                            DispatchQueue.main.async {
                                self.handleEvent(for: geofenceModel, typeTransaction: region.contains(coordinate) ? TypeTransactions.ENTER : TypeTransactions.EXIT)
                            }
                            sleep(2)
                        } else if(region.contains(coordinate)){
                            DispatchQueue.main.async {
                                self.handleEvent(for: geofenceModel, typeTransaction: typeTransaction)
                            }
                            sleep(2)
                        }
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Success \(locations.first)")
        if(locations.first?.coordinate != nil){
            print("NOT null")
            self.checkGeofenceEvent(coordinate: locations.first!.coordinate, isInitial: true)
        }
    }
    
    private func handleEvent(for geofenceModel: GeofenceModel, typeTransaction transaction: TypeTransactions) {
        let notification = geofenceModel.typeTransactions[transaction]?.0 as NotificationDataModel?
        print("Event \(geofenceModel.convertToCLCircularRegion())")
        if(notification != nil && notification?.message != nil && !(notification?.message?.isEmpty)!){
            let body = "\(transaction.rawValue) " + (notification?.message)!
            let notificationContent = UNMutableNotificationContent()
            notificationContent.body = body
            notificationContent.sound = .default
            notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false )
            let request = UNNotificationRequest(
                identifier: geofenceModel.id,
                content: notificationContent,
                trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error: \(error)")
                }
            }
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
