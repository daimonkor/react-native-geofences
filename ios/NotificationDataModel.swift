class NotificationDataModel {
    let message: String?
    let actionUri: String?

    init(message: String?, actionUri: String? = nil){
        self.message = message
        self.actionUri = actionUri
    }
}
