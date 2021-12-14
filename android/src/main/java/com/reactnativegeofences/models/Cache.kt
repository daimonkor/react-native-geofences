package com.reactnativegeofences.models

data class Cache(
    val mGeofencesHolderList: List<GeofenceHolderModel>,
    val isStartedMonitoring: Boolean
)
