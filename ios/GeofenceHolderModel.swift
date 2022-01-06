class GeofenceHolderModel{
    var geofenceModels: Array<GeofenceModel>
    var initialTriggers: Array<InitialTriggers>
    init(geofenceModels: Array<GeofenceModel>, initialTriggers: Array<InitialTriggers>){
        self.geofenceModels = geofenceModels
        self.initialTriggers = initialTriggers
    }
    
    init() {
        self.geofenceModels = []
        self.initialTriggers = []
    }
}
