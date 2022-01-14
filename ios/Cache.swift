class Cache: Codable{
  var geofencesHolderList: Array<GeofenceHolderModel>
  var isStartedMonitoring: Bool

  init(geofencesHolderList: Array<GeofenceHolderModel>, isStartedMonitoring: Bool){
      self.geofencesHolderList = geofencesHolderList
      self.isStartedMonitoring = isStartedMonitoring
  }
}
