import CoreLocation

class Coordinate: Codable {
    let longitude: Double
    let latitude: Double
    let radius: Int
    
    init( longitude: Double, latitude: Double, radius: Int){
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
    
    static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.latitude == rhs.latitude && lhs.radius == rhs.radius
    }
    
    func convertToDictionary() -> [String: Any?]{
        return [ "longitude": self.longitude, "latitude": self.latitude, "radius": self.radius]
    }
}
