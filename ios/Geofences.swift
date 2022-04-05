import CoreLocation
import React
import Accelerate
import UserNotifications
import UIKit

@objc(Geofences)
class Geofences: RCTEventEmitter, CLLocationManagerDelegate, UNUserNotificationCenterDelegate, GeofenceManagment {
    private var locationManager: CLLocationManager = CLLocationManager()
    private var requestLocationAuthorizationCallback: ((CLAuthorizationStatus) -> Void)?
    private var hasListeners = false;
    private var mGeofencesHolderList = Array<GeofenceHolderModel>()
    private var geofenceMonitoringStatus = GeofenceMonitoringStatus()
    private var customEvents: Array<String> = []
    
    static let GEOFENCES_MISSING_ERROR_CODE = 10
    static let DEVICE_IS_NOT_SUPPORTED_GEOFENCES_ERROR_CODE = 11
    static let UNKNOWN_ERROR_CODE = -1
    
    private override init() {
        super.init()
        DispatchQueue.main.sync {
            (UIApplication.shared.delegate as? GeofenceDelegate)?.onInitGeofencesModule(self)
        }
        self.loadCache()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self
        
    }
    
    func addCustomEvent(_ eventName: String!) {
        self.customEvents.append(eventName)
    }
    
    @objc override static func requiresMainQueueSetup() -> Bool {
        return false
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
        if(self.customEvents.count > 0){
            var list: Array<String> = ["onGeofenceEvent"]
            list.append (contentsOf: self.customEvents)
            return list
        }
        return ["onGeofenceEvent"]
    }
    
    func sendEvent(_ withName: String, body: [AnyHashable : Any]) {
        self.sendEvent(withName: withName, body: body)
    }
    
    @objc(startMonitoring:reject:)
    func startMonitoring( _ resolve :  @escaping RCTPromiseResolveBlock, reject:  @escaping RCTPromiseRejectBlock)  -> Void   {
        let action = {
            do{
                try {
                    self.geofenceMonitoringStatus.callback = { error in
                        if(error != nil){
                            NSLog("Failure start geofences monitoring: \(String(describing: error))")
                            let (code, message, error) = (error as? ErrorImpl)?.convertToTuple() ?? (Geofences.UNKNOWN_ERROR_CODE, "Unknown error", nil)
                            reject(String(code ?? 0), message, error)
                        }else{
                            NSLog("Start current geofences monitoring successfully")
                            self.saveCache()
                            resolve(true)
                        }
                        self.geofenceMonitoringStatus.callback = nil
                    }
                    if (self.mGeofencesHolderList.isEmpty) {
                        NSLog("Failure create geofences and start current geofences monitoring: please add geofences")
                        throw ErrorImpl.error(code: Geofences.GEOFENCES_MISSING_ERROR_CODE, message: "Start monitoring error: missing geofences")
                    }
                    let countGeofences = self.mGeofencesHolderList.map{ holder in
                        holder.geofenceModels
                    }.joined().count
                    NSLog("Count geofences \(countGeofences)")
                    self.geofenceMonitoringStatus.start(neededStartGeofencesCount: countGeofences)
                    if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
                        NSLog(
                            "Geofencing is not supported on this device!")
                        throw ErrorImpl.error(code: Geofences.DEVICE_IS_NOT_SUPPORTED_GEOFENCES_ERROR_CODE, message: "Geofencing is not supported on this device!")
                    }
                    for geofencesHolder in self.mGeofencesHolderList {
                        for geofenceModel in geofencesHolder.geofenceModels{
                            self.locationManager.startMonitoring(for: geofenceModel.convertToCLCircularRegion())
                        }
                    }
                    self.locationManager.requestLocation()
                }()
            }catch let error as ErrorImpl{
                self.geofenceMonitoringStatus.error(error: error)
            }catch {
                self.geofenceMonitoringStatus.error(error: ErrorImpl.error(code: Geofences.UNKNOWN_ERROR_CODE, message: error.localizedDescription, error: error as NSError))
            }
        }
        self.stopMonitoring {result in
            action()
        } reject: { code, message, error in
            action()
        }
    }
    
    @objc(stopMonitoring:reject:)
    func stopMonitoring(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock)  -> Void  {
        let isStartedMonitoring = self.geofenceMonitoringStatus.isStartedMonitoring
        self.geofenceMonitoringStatus.callback = { error in
            if(error != nil){
                NSLog("Failure stop geofences monitoring: \(String(describing: error))")
                let (code, message, error) = (error as? ErrorImpl)?.convertToTuple() ?? (Geofences.UNKNOWN_ERROR_CODE, "Unknown error", nil)
                reject(String(code ?? 0), message, error)
            }else{
                NSLog("Stop geofences monitoring successfully")
                self.saveGeofencesDataToCache(geofencesHolderList: self.mGeofencesHolderList, isStartedMonitoring: false)
                resolve(isStartedMonitoring)
                self.geofenceMonitoringStatus.isStartedMonitoring = false
            }
        }
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        self.geofenceMonitoringStatus.stop()
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
        NSLog("Add geofences: \(geofenceHolder)")
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
        self.addGeofences(geofencesHolderList: [geofenceHolderModel])
        resolve(geofenceHolder)
    }
    
    private func addGeofences(geofencesHolderList: Array<GeofenceHolderModel>) {
        for (index, geofenceHolder) in geofencesHolderList.enumerated() {
            for geofenceModel in geofenceHolder.geofenceModels {
                let indexes = self.isExistsGeofence(coordinate: geofenceModel.position, ignoreRadius: true)
                if (indexes.atGeofenceHolderModelListPosition >= 0 && mGeofencesHolderList.count > 0 && mGeofencesHolderList.count >= indexes.atGeofenceHolderModelListPosition - 1) {
                    mGeofencesHolderList[indexes.atGeofenceHolderModelListPosition].geofenceModels.remove(at: indexes.atGeofenceModelListPosition
                    )
                }
                if (mGeofencesHolderList.count > 0 && mGeofencesHolderList.count >= index - 1 && mGeofencesHolderList[index].geofenceModels.isEmpty) {
                    mGeofencesHolderList.remove(at: index)
                }
            }
        }
        self.mGeofencesHolderList.append(contentsOf: geofencesHolderList)
        self.saveCache()
    }
    
    private func isExistsGeofence(coordinate: Coordinate, ignoreRadius: Bool = false) -> GeofenceAtCache {
        for (indexGeofenceHolderModelListPosition, geofenceHolder) in self.mGeofencesHolderList.enumerated() {
            for (indexGeofenceModelListPosition, geofenceModel) in geofenceHolder.geofenceModels.enumerated() {
                if (geofenceModel.position.latitude == coordinate.latitude && geofenceModel.position.longitude == coordinate.longitude && (!ignoreRadius) ? (geofenceModel.position.radius == coordinate.radius || (coordinate.radius == nil || coordinate.radius < 0)) : true) {return GeofenceAtCache(
                    atGeofenceHolderModelListPosition: indexGeofenceHolderModelListPosition,
                    atGeofenceModelListPosition: indexGeofenceModelListPosition)
                }
            }
        }
        return GeofenceAtCache(atGeofenceHolderModelListPosition: -1, atGeofenceModelListPosition: -1)
    }
    
    @objc(isExistsGeofenceById:resolve:reject:)
    func isExistsGeofenceById(id: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        let result = self.mGeofencesHolderList.map { holder in
            holder.geofenceModels
        }.joined().first(where: {item in item.id == id}) != nil
        NSLog("Is exists Geofence by id: \(id), \(result)")
        resolve(result)
    }
    
    @objc(isExistsGeofenceByListId:resolve:reject:)
    func isExistsGeofenceByListId(ids: NSArray, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        let result = ids.map { id  in
            try! self.mGeofencesHolderList.map { holder in
                holder.geofenceModels
            }.joined().first(where: {item in item.id == (id as! String) })
        }.filter { geofenceModel in
            geofenceModel != nil
        }.count > 0
        NSLog("Is exists Geofence by list ids: \(ids), \(result), \(self.mGeofencesHolderList)")
        resolve(result)
    }
    
    @objc(isExistsGeofenceByCoordinate:resolve:reject:)
    func isExistsGeofenceByCoordinate(coordinate: NSDictionary, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        let result = self.mGeofencesHolderList.map { holder in
            holder.geofenceModels
        }.joined().first(where: {item in item.position == Coordinate(longitude: coordinate["longitude"] as! Double, latitude: coordinate["latitude"] as! Double, radius: coordinate["radius"] as! Int)}) != nil
        NSLog("Is exists Geofence by coordinate: \(coordinate), \(result)")
        resolve(result)
    }
    
    @objc(isExistsGeofenceByListCoordinate:resolve:reject:)
    func isExistsGeofenceByListCoordinate(coordinates: NSArray, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)  -> Void  {
        let result = coordinates.map { coordinate  in
            try! self.mGeofencesHolderList.map { holder in
                holder.geofenceModels
            }.joined().first(where: {item in item.position == Coordinate(longitude: (coordinate as! NSDictionary)["longitude"] as! Double, latitude: (coordinate as! NSDictionary)["latitude"] as! Double, radius: (coordinate as! NSDictionary)["radius"] as! Int)})
        }.filter { geofenceModel in
            geofenceModel != nil
        }.count > 0
        NSLog("Is exists Geofence by list coordinates: \(coordinates), \(result), \(self.mGeofencesHolderList)")
        resolve(result)
    }
    
    @objc(removeGeofences:resolve:reject:)
    func removeGeofences(filter: NSArray, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock)  -> Void  {
        self.geofenceMonitoringStatus.callback = { error in
            if(error != nil){
                NSLog("Failure remove geofences and stop current geofences monitoring: \(String(describing: error))")
                let (code, message, error) = (error as? ErrorImpl)?.convertToTuple() ?? (Geofences.UNKNOWN_ERROR_CODE, "Unknown error", nil)
                reject(String(code ?? 0), message, error)
            }else{
                NSLog("Remove geofences and stop current geofences monitoring successfully")
                self.saveCache()
                resolve(filter)
            }
        }
        if(filter.count > 0){
            self.mGeofencesHolderList.forEach { GeofenceHolderModel in
                try! GeofenceHolderModel.geofenceModels.removeAll { GeofenceModel in
                    filter.contains(GeofenceModel.id)
                }
            }
            self.mGeofencesHolderList = self.mGeofencesHolderList.filter({ GeofenceHolderModel in
                !GeofenceHolderModel.geofenceModels.isEmpty
            })
            self.locationManager.monitoredRegions.forEach { CLRegion in
                if(filter.contains(CLRegion.identifier)){
                    self.locationManager.stopMonitoring(for: CLRegion)
                }
            }
        }else{
            self.stopAllMonitoredRegions()
            self.mGeofencesHolderList.removeAll()
        }
        self.geofenceMonitoringStatus.stop()
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
        let requestedBefore = self.isFlaggedAsRequested(handlerUniqueId: self.handlerUniqueId());
        if (currentStatus != .notDetermined && (currentStatus == .authorizedWhenInUse && requestedBefore)) {
            callback?(currentStatus)
            return
        }else if(!requestedBefore){
            self.locationManager.requestAlwaysAuthorization()
        } else{
            callback?(currentStatus)
        }
        self.flagAsRequested (handlerUniqueId: self.handlerUniqueId());
    }
    
    private func generateId() -> String {
        return UUID().uuidString
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {
        if region is CLCircularRegion {
            self.checkGeofenceEvent(coordinate: region as! CLCircularRegion , typeTransaction: TypeTransactions.ENTER)
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didExitRegion region: CLRegion
    ) {
        if region is CLCircularRegion {
            self.checkGeofenceEvent(coordinate: (region as! CLCircularRegion), typeTransaction: TypeTransactions.EXIT)
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        monitoringDidFailFor region: CLRegion?,
        withError error: Error
    ) {
        self.geofenceMonitoringStatus.callback?(error)
        guard let region = region else {
            NSLog("Monitoring failed for unknown region")
            return
        }
        NSLog("Monitoring failed for region with identifier: \(region.identifier), \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion){
        NSLog("Monitoring started for region with identifier: \(region.identifier)")
        let wasStartedMonitoring = self.geofenceMonitoringStatus.isStartedMonitoring
        self.geofenceMonitoringStatus.addStartGeofenceCounter()
        NSLog("Counters \(self.geofenceMonitoringStatus.neededStartGeofencesCount), \(self.geofenceMonitoringStatus.startedGeofencesCount)")
        if(self.geofenceMonitoringStatus.isAllStartedGeofencesMonitoring() && !wasStartedMonitoring){
            self.geofenceMonitoringStatus.callback?(nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(locations.first?.coordinate != nil && !self.locationManager.monitoredRegions.isEmpty){
            self.locationManager.stopUpdatingLocation()
            locationManager.delegate = nil;
            NSLog("Request location for geofence monitoring success: \(String(describing: locations.first))")
            self.checkGeofenceEvent(coordinate: CLCircularRegion(center: locations.first!.coordinate, radius: 1, identifier: "unknown") , isInitial: true)
            self.locationManager.delegate = self;
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("Location Manager failed with the following error: \(error)")
    }
    
    private func checkGeofenceEvent(coordinate: CLCircularRegion, typeTransaction: TypeTransactions = TypeTransactions.UNKNOWN, isInitial: Bool = false){
        DispatchQueue.main.sync {
            for geofencesHolder in self.mGeofencesHolderList {
                if(geofencesHolder.initialTriggers.count > 0 && isInitial || !isInitial){
                    for geofenceModel in geofencesHolder.geofenceModels{
                        let region = geofenceModel.convertToCLCircularRegion() as! CLCircularRegion
                        if(isInitial){
                            NSLog("Contains initial triggers: \(geofencesHolder.initialTriggers.count)")
                            NSLog("Check init: \(coordinate.center) \(region.center) \(region.contains(coordinate.center)) \(region.contains(region.center))")
                            let inRegion = region.contains(coordinate.center)
                            if(geofencesHolder.initialTriggers.contains(InitialTriggers.ENTER) == true && inRegion){
                                self.handleEvent(for: geofenceModel, typeTransaction: TypeTransactions.ENTER, true)
                            }else if(geofencesHolder.initialTriggers.contains(InitialTriggers.EXIT) == true && !inRegion){
                                self.handleEvent(for: geofenceModel, typeTransaction: TypeTransactions.EXIT, true)
                            }
                        } else if(region == coordinate){
                            self.handleEvent(for: geofenceModel, typeTransaction: typeTransaction)
                        }
                    }
                }
            }
        }
    }
    
    private func handleEvent(for geofenceModel: GeofenceModel, typeTransaction transaction: TypeTransactions, _ isInit: Bool = false) {
        let notification = geofenceModel.typeTransactions[transaction]?.0 as NotificationDataModel?
        NSLog("Geofence event: \(geofenceModel.convertToCLCircularRegion()) \(self.index)")
        if(self.hasListeners){
            self.sendEvent(withName: "onGeofenceEvent", body: ["GEOFENCES_LIST_KEY": geofenceModel.convertToDictonary(), "TRANSITION_TYPE_KEY": transaction.rawValue, "INIT": isInit])
        }
        (UIApplication.shared.delegate as? GeofenceDelegate)?.geofenceEvent(["GEOFENCES_LIST_KEY": geofenceModel.convertToDictonary(), "TRANSITION_TYPE_KEY": transaction.rawValue], geofenceManager: self)
        if(notification != nil && notification?.message != nil && !(notification?.message?.isEmpty)!){
            let body = (notification?.message)!
            let notificationContent = UNMutableNotificationContent()
            notificationContent.body = body
            notificationContent.sound = .default
            notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
            notificationContent.userInfo = ["actionUrl" : notification?.actionUri]
            let request = UNNotificationRequest(
                identifier: geofenceModel.id + generateId(),
                content: notificationContent,
                trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    NSLog("Geofence handle event error: \(error)")
                }
            }
            sleep(1)
        }
    }
}

extension Geofences {
    static let CACHE_FILE_NAME = "GEOFENCES_CACHE"
    static let PERMISSION_SETTINGS = "PERMISSION_SETTINGS"
    static let SETTING_KEY = "Permissions:Requested";
    
    func saveCache() {
        saveGeofencesDataToCache(geofencesHolderList: self.mGeofencesHolderList, isStartedMonitoring: self.geofenceMonitoringStatus.isStartedMonitoring)
    }
    
    func loadCache() {
        let cache = self.getGeofencesDataFromCache()
        self.mGeofencesHolderList = cache.geofencesHolderList
        self.geofenceMonitoringStatus.isStartedMonitoring = cache.isStartedMonitoring
    }
    
    private func saveGeofencesDataToCache(
        geofencesHolderList: Array<GeofenceHolderModel>,
        isStartedMonitoring: Bool
    ) {
        do {
            let data = try JSONEncoder().encode(Cache(geofencesHolderList: self.mGeofencesHolderList, isStartedMonitoring: self.geofenceMonitoringStatus.isStartedMonitoring))
            NSLog("Save cache: \(String(data: data, encoding: .utf8)!)")
            UserDefaults.standard.set(data, forKey: Geofences.CACHE_FILE_NAME)
        } catch {
            NSLog("Error encoding cache")
        }
    }
    
    private func getGeofencesDataFromCache() -> Cache {
        guard let savedData = UserDefaults.standard.data(forKey: Geofences.CACHE_FILE_NAME) else { return Cache(geofencesHolderList: [], isStartedMonitoring: false) }
        if let savedGeotifications = try? JSONDecoder().decode(Cache.self, from: savedData) as Cache {
            return savedGeotifications
        }
        return Cache(geofencesHolderList: [], isStartedMonitoring: false)
    }
    
    func handlerUniqueId() -> String {
      return "ios.permission.LOCATION_ALWAYS";
    }
    
    func isFlaggedAsRequested(handlerUniqueId: String) -> Bool{
        return  UserDefaults.standard.string(forKey: Geofences.PERMISSION_SETTINGS) != nil
    }
    
    func flagAsRequested(handlerUniqueId: String){
        UserDefaults.standard.set(handlerUniqueId, forKey: Geofences.PERMISSION_SETTINGS)
    }
}
