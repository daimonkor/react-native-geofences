package com.reactnativegeofences.models

import com.google.android.gms.location.GeofencingRequest

enum class InitialTriggers(val trigger: Int){
  ENTER(GeofencingRequest.INITIAL_TRIGGER_ENTER),
  EXIT(GeofencingRequest.INITIAL_TRIGGER_EXIT),
  DWELL(GeofencingRequest.INITIAL_TRIGGER_DWELL),
  UNKNOWN(-1);

  companion object {
    fun toValue(typeTrigger: Int?): InitialTriggers {
      return values().firstOrNull { value -> value.trigger == typeTrigger }
        ?: UNKNOWN
    }
  }
}
