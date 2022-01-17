import Foundation

class GeofenceMonitoringStatus{
    var neededStartGeofencesCount: Int = 0
    var startedGeofencesCount: Int = 0
    var isStartedMonitoring: Bool = false
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
        let callback = self.callback
        self.reset()
        callback?(nil)
    }
    
    func error(error: Error){
        let callback = self.callback
        self.reset()
        callback?(error)
    }
    
    init(){}
}
