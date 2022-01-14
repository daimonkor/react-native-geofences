import CoreLocation

class GeofenceModel: Codable{
    let position: Coordinate
    let name: String
    let id: String
    var typeTransactions: [TypeTransactions : (NotificationDataModel?, [String: Any?])]
    
    init(position: Coordinate, name: String, id: String, typeTransactions: [TypeTransactions : (NotificationDataModel?, [String: Any?])]){
        self.position = position
        self.name = name
        self.id = id
        self.typeTransactions = typeTransactions
    }
    
    static func decodeMap<T: CodingKey>(parentContainer: inout KeyedDecodingContainer<T>, keyedBy: KeyedDecodingContainer<T>.Key.Type,  forKey: KeyedDecodingContainer<T>.Key) throws -> [String: Any?] {
        var mapContainer = try parentContainer.nestedContainer(keyedBy: keyedBy, forKey: forKey)
        var extraData: [String: Any?] = [:]
        try mapContainer.allKeys.forEach { extraCodingKey in
            if let value = try? mapContainer.decode(String.self, forKey: extraCodingKey) {
                extraData[extraCodingKey.stringValue] = value
            } else if let value = try? mapContainer.decode(Bool.self, forKey: extraCodingKey)     {
                extraData[extraCodingKey.stringValue] = value
            }   else if let value = try? mapContainer.decode(Int.self, forKey: extraCodingKey)      {
                extraData[extraCodingKey.stringValue] = value
            }   else if let value = try? mapContainer.decode(Double.self, forKey: extraCodingKey)     {
                extraData[extraCodingKey.stringValue] = value
            }  else if let value = try? mapContainer.decode(Float.self, forKey: extraCodingKey)      {
                extraData[extraCodingKey.stringValue] = value
            } else {
                extraData[extraCodingKey.stringValue] = try self.decodeMap(parentContainer: &mapContainer, keyedBy: keyedBy, forKey: extraCodingKey)
            }
        }
        return extraData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeysImpl.self)
        self.position = try container.decode(Coordinate.self, forKey: CodingKeysImpl(stringValue: "position"))
        self.name = try container.decode(String.self, forKey: CodingKeysImpl(stringValue: "name"))
        self.id = try container.decode(String.self, forKey: CodingKeysImpl(stringValue: "id"))
        self.typeTransactions = [:]
        let typeTransactionsContainer = try container.nestedContainer(keyedBy:  CodingKeysImpl.self, forKey:  CodingKeysImpl(stringValue: "typeTransactions"))
        try typeTransactionsContainer.allKeys.forEach { codingKey in
            let typeTransactionContainer = try typeTransactionsContainer.nestedContainer(keyedBy: CodingKeysImpl.self, forKey: codingKey)
            let notification = try typeTransactionContainer.decode(NotificationDataModel.self, forKey: CodingKeysImpl(stringValue: "notification"))
            var extraDataContainer = try? typeTransactionContainer.nestedContainer(keyedBy: CodingKeysImpl.self, forKey: CodingKeysImpl(stringValue: "extraData"))
            var extraData: [String: Any?] = [:]
            extraDataContainer?.allKeys.forEach { extraCodingKey in
                if let value = try? extraDataContainer?.decode(String.self, forKey: extraCodingKey) {
                    extraData[extraCodingKey.stringValue] = value
                } else if let value = try? extraDataContainer?.decode(Bool.self, forKey: extraCodingKey)     {
                    extraData[extraCodingKey.stringValue] = value
                }   else if let value = try? extraDataContainer?.decode(Int.self, forKey: extraCodingKey)      {
                    extraData[extraCodingKey.stringValue] = value
                }   else if let value = try? extraDataContainer?.decode(Double.self, forKey: extraCodingKey)     {
                    extraData[extraCodingKey.stringValue] = value
                }  else if let value = try? extraDataContainer?.decode(Float.self, forKey: extraCodingKey)      {
                    extraData[extraCodingKey.stringValue] = value
                } else {
                    let data = try? GeofenceModel.decodeMap(parentContainer: &extraDataContainer!, keyedBy: CodingKeysImpl.self, forKey: extraCodingKey)
                    if(data != nil){
                        extraData[extraCodingKey.stringValue] = data
                    }
                }
            }
            self.typeTransactions[TypeTransactions(rawValue: Int(codingKey.stringValue)!)!] = (notification, extraData)
        }
    }
    
    static func encodeMap<T: CodingKey>(parentContainer: inout KeyedEncodingContainer<T>, keyedBy: KeyedEncodingContainer<T>.Key.Type,  forKey: KeyedEncodingContainer<T>.Key, value: [String: Any?]) throws{
        var mapContainer = parentContainer.nestedContainer(keyedBy: keyedBy, forKey: forKey)
        if(value.count > 0){
            try value.forEach { (key: String, value: Any?) in
                if(value as? String != nil){
                    try mapContainer.encode(value as! String, forKey:  CodingKeysImpl(stringValue: key) as! KeyedEncodingContainer<T>.Key)
                }else if(value as? Int != nil){
                    try mapContainer.encode(value as! Int, forKey:  CodingKeysImpl(stringValue: key) as! KeyedEncodingContainer<T>.Key)
                }else if(value as? Double != nil){
                    try mapContainer.encode(value as! Double, forKey:  CodingKeysImpl(stringValue: key) as! KeyedEncodingContainer<T>.Key)
                }else if(value as? Bool != nil){
                    try mapContainer.encode(value as! Bool, forKey:  CodingKeysImpl(stringValue: key) as! KeyedEncodingContainer<T>.Key)
                }else if(value as? [String:Any?] != nil){
                    try self.encodeMap(parentContainer: &mapContainer, keyedBy: keyedBy, forKey:  CodingKeysImpl(stringValue: key) as! KeyedEncodingContainer<T>.Key, value: value as! [String : Any?])
                }
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy:  CodingKeysImpl.self)
        try container.encode(position, forKey:  CodingKeysImpl(stringValue: "position"))
        try container.encode(id, forKey:  CodingKeysImpl(stringValue: "id"))
        try container.encode(name, forKey:  CodingKeysImpl(stringValue: "name"))
        var typeTransactionsContainer = container.nestedContainer(keyedBy:  CodingKeysImpl.self, forKey:  CodingKeysImpl(stringValue: "typeTransactions"))
        try typeTransactions.forEach { (key: TypeTransactions, value: (NotificationDataModel?, [String : Any?])) in
            var typeTransactionContainer = typeTransactionsContainer.nestedContainer(keyedBy:  CodingKeysImpl.self, forKey:   CodingKeysImpl(stringValue: String(key.rawValue)))
            try typeTransactionContainer.encode(value.0, forKey:  CodingKeysImpl(stringValue: "notification"))
            if(value.1.count > 0){
                var extraDataContainer = typeTransactionContainer.nestedContainer(keyedBy:  CodingKeysImpl.self, forKey:   CodingKeysImpl(stringValue: "extraData"))
                try value.1.forEach { (key: String, value: Any?) in
                    if(value as? String != nil){
                        try extraDataContainer.encode(value as! String, forKey:  CodingKeysImpl(stringValue: key))
                    }else if(value as? Int != nil){
                        try extraDataContainer.encode(value as! Int, forKey:  CodingKeysImpl(stringValue: key))
                    }else if(value as? Double != nil){
                        try extraDataContainer.encode(value as! Double, forKey:  CodingKeysImpl(stringValue: key))
                    }else if(value as? Bool != nil){
                        try extraDataContainer.encode(value as! Bool, forKey:  CodingKeysImpl(stringValue: key))
                    }else if(value as? [String:Any?] != nil){
                        try GeofenceModel.encodeMap(parentContainer: &extraDataContainer, keyedBy:  CodingKeysImpl.self, forKey:  CodingKeysImpl(stringValue: key), value: value as! [String : Any?])
                    }
                }
            }
        }
    }
    
    func convertToCLCircularRegion() -> CLRegion {
        let region =  CLCircularRegion(center: CLLocationCoordinate2D(latitude: self.position.latitude, longitude: self.position.longitude), radius: Double(self.position.radius), identifier: self.id)
        region.notifyOnExit = (self.typeTransactions[TypeTransactions.EXIT] != nil)
        region.notifyOnEntry = (self.typeTransactions[TypeTransactions.ENTER] != nil)        
        return region
    }
    
    func convertToDictonary() -> [String: Any?]{
        var typeTransactions: [String: Any?] = [:]
        self.typeTransactions.forEach { (key: TypeTransactions, value: (NotificationDataModel?, [String : Any?])) in
            typeTransactions[String(key.rawValue)] = ["notification":value.0?.convertToDictionary(), "extraData": value.1]
        }
        return ["position": position.convertToDictionary(), "name": self.name, "id": self.id, "typeTransactions": typeTransactions]
    }
}
