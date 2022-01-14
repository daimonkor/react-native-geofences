class NotificationDataModel: Codable {
    let message: String?
    let actionUri: String?

    init(message: String?, actionUri: String? = nil){
        self.message = message
        self.actionUri = actionUri
    }
    
    func convertToDictionary() -> [String: Any?]{
        return ["message": message, "actionUri": actionUri]
    }
}
