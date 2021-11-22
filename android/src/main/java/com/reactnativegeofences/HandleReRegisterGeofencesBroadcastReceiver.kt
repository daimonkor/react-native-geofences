package com.reactnativegeofences

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.icebergteam.timberjava.Timber

class HandleReRegisterGeofencesBroadcastReceiver : BroadcastReceiver() {

  override fun onReceive(context: Context, intent: Intent) {
    val geofenceHelper = GeofenceHelper(context)

    Timber.e("Restart geofences: %s", geofenceHelper.mGeofencesHolderList)
    geofenceHelper.startMonitoring(null)
  }
}
