package com.reactnativegeofences.models


data class GeofenceHolderModel(
    var geofenceModels: ArrayList<GeofenceModel> = ArrayList(),
    var initialTriggers: Array<InitialTriggers> = arrayOf()
)
