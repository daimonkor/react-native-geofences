import CoreLocation

class GeofenceModel{
    let position: Coordinate
    let name: String
    let id: String
    let typeTransactions: [TypeTransactions : (NotificationDataModel?, [String: Any?])]
    
    init(position: Coordinate, name: String, id: String, typeTransactions: [TypeTransactions : (NotificationDataModel?, [String: Any?])]){
        self.position = position
        self.name = name
        self.id = id
        self.typeTransactions = typeTransactions
    }
    
    func convertToCLCircularRegion() -> CLRegion {
        let region =  CLCircularRegion(center: CLLocationCoordinate2D(latitude: self.position.latitude, longitude: self.position.longitude), radius: Double(self.position.radius), identifier: self.id)
        region.notifyOnExit = (self.typeTransactions[TypeTransactions.EXIT] != nil)
        region.notifyOnEntry = (self.typeTransactions[TypeTransactions.ENTER] != nil)        
        return region
    }
}
