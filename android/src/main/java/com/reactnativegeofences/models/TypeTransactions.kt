package com.reactnativegeofences.models

import com.google.android.gms.location.Geofence

enum class TypeTransactions(val typeTransaction: Int) {
  ENTER(Geofence.GEOFENCE_TRANSITION_ENTER),
  EXIT(Geofence.GEOFENCE_TRANSITION_EXIT),
  DWELL(Geofence.GEOFENCE_TRANSITION_DWELL),
  UNKNOWN(-1);

  companion object {
    fun toValue(typeTrigger: Int?): TypeTransactions {
      return values().firstOrNull { value -> value.typeTransaction == typeTrigger }
        ?: UNKNOWN
    }
  }
}
