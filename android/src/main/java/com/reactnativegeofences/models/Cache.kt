package com.reactnativegeofences.models

data class Cache(
  val geofencesHolderList: List<GeofenceHolderModel>,
  val isStartedMonitoring: Boolean,
  val bootCompleted: Boolean
)
