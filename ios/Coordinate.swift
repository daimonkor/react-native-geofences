import CoreLocation

class Coordinate {
    let longitude: Double
    let latitude: Double
    let radius: Int
    
    init(  longitude: Double, latitude: Double, radius: Int){
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
}
