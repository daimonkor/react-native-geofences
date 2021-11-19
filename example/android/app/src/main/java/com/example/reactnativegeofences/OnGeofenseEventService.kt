package com.example.reactnativegeofences

import android.app.job.JobParameters
import android.app.job.JobService
import android.os.Build
import android.widget.Toast
import androidx.annotation.RequiresApi
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.reactnativegeofences.GeofenceHelper.Companion.GEOFENCES_LIST_KEY
import com.reactnativegeofences.GeofenceHelper.Companion.TRANSITION_TYPE_KEY
import com.reactnativegeofences.GeofenceModel
import com.reactnativegeofences.NotificationDataModel


@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class OnGeofenseEventService : JobService() {

  override fun onStartJob(params: JobParameters?): Boolean {
    val geofencesList = params?.extras?.getString(GEOFENCES_LIST_KEY)?.let {
      Gson().fromJson<Array<GeofenceModel>>(it, object: TypeToken<Array<GeofenceModel>>(){}.type)
    }
    val transitionType = params?.extras?.getInt(TRANSITION_TYPE_KEY)
    val action = geofencesList?.get(0)?.typeTransactions?.get(transitionType) as NotificationDataModel

    val toast = Toast.makeText(
      this.applicationContext,
     action.message + " " + action.request, Toast.LENGTH_LONG
    )
    toast.show()
    return true
  }

  override fun onStopJob(params: JobParameters?): Boolean {
   return true
  }
}
