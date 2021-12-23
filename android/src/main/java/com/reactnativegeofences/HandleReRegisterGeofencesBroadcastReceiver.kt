package com.reactnativegeofences

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class HandleReRegisterGeofencesBroadcastReceiver : BroadcastReceiver() {
  companion object {
    const val TAG = "ReRegisterGFBDReceiver"
  }

  override fun onReceive(context: Context, intent: Intent) {
    val geofenceHelper = GeofenceHelper(context)
    Log.i(TAG, String.format("Restart geofences: %s", geofenceHelper.mGeofencesHolderList))
    geofenceHelper.mBootCompleted = true
    if(geofenceHelper.mIsStartedMonitoring) {
      geofenceHelper.startMonitoring(null)
    }
  }
}
