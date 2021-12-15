package com.example.reactnativegeofences

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.reactnativegeofences.GeofenceHelper

class ShutDownReceiver : BroadcastReceiver() {
  companion object {
    const val TAG = "ShutDownReceiver"
  }

  @Override
  override fun onReceive(context: Context, intent: Intent) {
    if (Intent.ACTION_SHUTDOWN == intent.action) {
      Log.e(TAG, "System shutting down");
      val geofenceHelper = GeofenceHelper(context)
      geofenceHelper.mBootCompleted = false
      geofenceHelper.saveCache()
    }
  }
}
