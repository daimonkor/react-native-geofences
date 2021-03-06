package com.reactnativegeofences

import android.app.NotificationChannel
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent
import android.text.TextUtils
import java.text.SimpleDateFormat
import java.util.*
import kotlin.collections.ArrayList
import android.app.NotificationManager
import androidx.core.app.NotificationCompat
import android.app.PendingIntent
import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.content.ComponentName
import android.content.Context.NOTIFICATION_SERVICE
import android.content.pm.PackageManager
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import android.os.PersistableBundle
import android.util.Log
import androidx.annotation.RequiresApi
import com.google.android.gms.location.Geofence.*
import com.google.gson.Gson
import com.reactnativegeofences.GeofenceHelper.Companion.GEOFENCES_LIST_KEY
import com.reactnativegeofences.GeofenceHelper.Companion.TRANSITION_TYPE_KEY
import com.reactnativegeofences.models.TypeTransactions


class GeofenceBroadcastReceiver : BroadcastReceiver() {
  companion object {
    const val TAG = "GeofenceBDReceiver"
  }

  private fun getGeofenceTransitionDetails(event: GeofencingEvent): String {
    val transitionString: String
    val c: Calendar = Calendar.getInstance()
    val df = SimpleDateFormat("HH:mm:ss")
    val formattedDate: String = df.format(c.time)
    val geofenceTransition = event.geofenceTransition
    transitionString = when (geofenceTransition) {
      GEOFENCE_TRANSITION_ENTER -> {
        "IN-$formattedDate"
      }
      GEOFENCE_TRANSITION_EXIT -> {
        "OUT-$formattedDate"
      }
      else -> {
        "OTHER-$formattedDate"
      }
    }
    val triggeringIDs: MutableList<String?>
    triggeringIDs = ArrayList()
    for (geofence in event.triggeringGeofences) {
      triggeringIDs.add(geofence.requestId)
    }
    return String.format("%s: %s", transitionString, TextUtils.join(", ", triggeringIDs))
  }

  @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
  override fun onReceive(context: Context, intent: Intent) {
    try {
      val geofencingEvent = GeofencingEvent.fromIntent(intent)
      if (geofencingEvent.hasError()) {
        val errorMessage = GeofenceStatusCodes
          .getStatusCodeString(geofencingEvent.errorCode)
        Log.e("%s", errorMessage)
        return
      }
      val geofenceTransition = geofencingEvent.geofenceTransition
      if (geofenceTransition == GEOFENCE_TRANSITION_ENTER ||
        geofenceTransition == GEOFENCE_TRANSITION_EXIT || geofenceTransition == GEOFENCE_TRANSITION_DWELL
      ) {
        Log.i(TAG, getGeofenceTransitionDetails(geofencingEvent))
        val data =
          GeofenceHelper(context).getGeofencesByIds(geofencingEvent.triggeringGeofences.map {
            it.requestId
          }.toTypedArray()).toTypedArray()
        data.forEach {
          it.typeTransactions[TypeTransactions.toValue(geofenceTransition)]?.first?.let { notificationDataModel ->
            if (notificationDataModel.message?.isNotEmpty() == true) {
              sendNotification(context, notificationDataModel.message, notificationDataModel.actionUri)
            }
          }
        }
        val ai: ApplicationInfo =
          context.packageManager.getApplicationInfo(
            context.packageName,
            PackageManager.GET_META_DATA
          )
        val bundle = ai.metaData
        val scheduler: JobScheduler =
          (context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler)
        val serviceComponent = ComponentName(
          bundle.getString("GEOFENCE_SERVICE_PACKAGE_NAME", ""),
          bundle.getString("GEOFENCE_SERVICE_CLASS_NAME", "")
        )
        val jobInfo = JobInfo.Builder(126, serviceComponent)
          .setExtras(PersistableBundle().apply {
            putString(GEOFENCES_LIST_KEY, Gson().toJson(data))
            putInt(TRANSITION_TYPE_KEY, geofencingEvent.geofenceTransition)
          })
          .setMinimumLatency(10)
          .setOverrideDeadline(5000)
          .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
          .setPersisted(true)
          .build()
        scheduler.schedule(jobInfo)
      } else {
        Log.e(TAG, String.format(
          "%s", "Error: " +
            geofenceTransition
        ))
      }
    } catch (exception: Exception) {
      Log.e(TAG, String.format("Can not find geofence service: %s", exception))
    }
  }

  private fun sendNotification(context: Context, notificationDetails: String, actionUri: String?) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val name = "Geofences Alarm"
      val descriptionText = "You will get important notifications about enter or exist geofences"
      val mChannel =
        NotificationChannel("geofences_alarm", name, NotificationManager.IMPORTANCE_HIGH)
      mChannel.description = descriptionText
      val notificationManager =
        context.getSystemService(NOTIFICATION_SERVICE) as NotificationManager
      notificationManager.createNotificationChannel(mChannel)
    }
    val ai: ApplicationInfo =
      context.packageManager.getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
    val bundle = ai.metaData
    val notificationIntent = Intent().apply {
      actionUri?.let {
        action = Intent.ACTION_VIEW
        data = Uri.parse(actionUri)
      }
    }
    val pendingIntent =
      PendingIntent.getActivity(context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT)
    val builder = NotificationCompat.Builder(context, "geofences_alarm")
      .setContentTitle(notificationDetails)
      .setContentIntent(pendingIntent)
      .setAutoCancel(true)
      .setSmallIcon(bundle.getInt("notification_small_icon"))
    val notificationManager =
      context.getSystemService(NOTIFICATION_SERVICE) as NotificationManager?
    Log.i(TAG, String.format("Show notification: %s, %s", notificationDetails, actionUri))
    notificationManager?.notify(Random().nextInt(), builder.build())
  }
}
