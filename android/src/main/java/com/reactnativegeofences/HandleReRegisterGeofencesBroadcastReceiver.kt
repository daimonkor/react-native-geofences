package com.reactnativegeofences

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class HandleReRegisterGeofencesBroadcastReceiver : BroadcastReceiver() {

  companion object {
    const val TAG = "HandleReRegister"
  }

  override fun onReceive(context: Context, intent: Intent) {
    val mGeofenceHelper = GeofenceHelper(context)
    mGeofenceHelper.startMonitoring(null)
  }
}
