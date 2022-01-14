class GeofenceHolderModel: Codable{
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
    
    required init(from decoder: Decoder) throws {
        self.initialTriggers = []
        self.geofenceModels = []
        let container = try decoder.container(keyedBy: CodingKeysImpl.self)
        var geofenceModelsContainer = try container.nestedUnkeyedContainer(forKey: CodingKeysImpl(stringValue: "geofenceModels"))
        while !geofenceModelsContainer.isAtEnd {
            self.geofenceModels.append(try geofenceModelsContainer.decode(GeofenceModel.self))
        }
        var initialTriggersContainer = try container.nestedUnkeyedContainer(forKey: CodingKeysImpl(stringValue: "initialTriggers"))
        while !initialTriggersContainer.isAtEnd {
            self.initialTriggers.append(InitialTriggers(rawValue: try initialTriggersContainer.decode(Int.self))!)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeysImpl.self)
        try container.encode(self.geofenceModels, forKey: CodingKeysImpl(stringValue: "geofenceModels"))
        var initialTriggersContainer = container.nestedUnkeyedContainer(forKey: CodingKeysImpl(stringValue: "initialTriggers"))
        try self.initialTriggers.forEach { initialTriggers in
            try initialTriggersContainer.encode(initialTriggers.rawValue)
        }
    }
}
