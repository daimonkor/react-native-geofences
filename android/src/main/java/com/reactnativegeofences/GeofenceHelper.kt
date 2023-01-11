package com.reactnativegeofences

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.PromiseImpl
import com.facebook.react.bridge.WritableNativeArray
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.reactnativegeofences.models.*

class GeofenceHelper(private val context: Context) {
  var mGeofencesHolderList = ArrayList<GeofenceHolderModel>()
    private set
  private val mGeofencingClient: GeofencingClient = LocationServices.getGeofencingClient(context);
  var mIsStartedMonitoring = false
  var mBootCompleted = true

  companion object {
    const val CACHE_FILE_NAME = "GEOFENCES_CACHE"
    const val GEOFENCES_KEY = "GEOFENCES_KEY"
    const val IS_STARTED_MONITORING_KEY = "IS_STARTED_MONITORING_KEY"
    const val BOOT_COMPLETED_KEY = "BOOT_COMPLETED_KEY"
    const val GEOFENCES_LIST_KEY = "GEOFENCES_LIST_KEY"
    const val TRANSITION_TYPE_KEY = "TRANSITION_TYPE_KEY"
    const val TAG = "GeofenceHelper"
  }

  init {
    loadCache()
  }

  fun addGeofences(geofencesHolderList: List<GeofenceHolderModel>) {
    geofencesHolderList.forEachIndexed { index, it ->
      it.geofenceModels.forEachIndexed { _, geofenceModel ->
        val indexes = this.isExistsGeofence(geofenceModel.position, true)
        if (indexes.atGeofenceHolderModelListPosition >= 0 && mGeofencesHolderList.size > 0 && mGeofencesHolderList.size >= indexes.atGeofenceHolderModelListPosition - 1) {
          mGeofencesHolderList[indexes.atGeofenceHolderModelListPosition].geofenceModels.removeAt(
            indexes.atGeofenceModelListPosition
          )
        }
        if (mGeofencesHolderList.size > 0 && mGeofencesHolderList.size >= index - 1 && mGeofencesHolderList[index].geofenceModels.isEmpty()) {
          mGeofencesHolderList.removeAt(index)
        }
      }
    }
    mGeofencesHolderList.addAll(geofencesHolderList)
    this.saveCache()
  }

  private fun createGeofences(callback: (geofenceIdList: Array<String>?, exception: Exception?) -> Unit) {
    try {
      if (mGeofencesHolderList.isEmpty()) {
        Log.e(
          TAG,
          String.format("Failure create geofences and start current geofences monitoring: please add geofences")
        )
        callback(null, Exception("createGeofences error: missing geofences"))
        return
      }
      val geofenceIdList = ArrayList<String>()
      mGeofencesHolderList.forEach {
        if (ActivityCompat.checkSelfPermission(
            this.context,
            Manifest.permission.ACCESS_FINE_LOCATION
          ) != PackageManager.PERMISSION_GRANTED
        ) {
          Log.e(
            TAG,
            String.format("Failure create geofences and start current geofences monitoring: ACCESS_FINE_LOCATION denied")
          )
          callback(null, Exception("createGeofences error: ACCESS_FINE_LOCATION denied"))
          return
        }
        mGeofencingClient.addGeofences(GeofencingRequest.Builder().apply {
          addGeofences(
            it.geofenceModels.map { geofenceModel ->
              geofenceIdList.add(geofenceModel.id)
              Geofence.Builder()
                .setRequestId(geofenceModel.id)
                .setCircularRegion(
                  geofenceModel.position.latitude,
                  geofenceModel.position.longitude,
                  geofenceModel.position.radius?.toFloat() ?: 400f
                )
                .setExpirationDuration(geofenceModel.expiredDuration.toLong())
                .setTransitionTypes(geofenceModel.typeTransactions.map {typeTransaction ->
                  typeTransaction.key
                }.let {
                  var type = it.first().typeTransaction
                  it.forEachIndexed { index, i ->
                    if (index != 0) {
                      type = type or i.typeTransaction
                    }
                  }
                  type
                })
                .build()
            })
          setInitialTrigger(it.initialTriggers.let {
            var trigger = it.first().trigger
            it.forEachIndexed { index, i ->
              if (index != 0) {
                trigger = trigger or i.trigger
              }
            }
            trigger
          })
        }.build(), Intent(this.context, GeofenceBroadcastReceiver::class.java).let {
          // Use FLAG_UPDATE_CURRENT so that you get the same pending intent back when calling
          // addGeofences() and removeGeofences().
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.getBroadcast(
              this.context,
              0,
              it,
              PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
          } else {
            PendingIntent.getBroadcast(this.context, 0, it, PendingIntent.FLAG_UPDATE_CURRENT)
          }
        }).addOnSuccessListener {
          Log.i(
            TAG, "Start create geofences and start current geofences monitoring successfully"
          )
          callback(geofenceIdList.toTypedArray(), null)
        }.addOnFailureListener {
          Log.e(
            TAG,
            String.format("Failure create geofences and start current geofences monitoring: %s", it)
          )
          callback(null, Exception("createGeofences error", it))
        }
      }
    } catch (exception: Exception) {
      Log.e(
        TAG,
        String.format(
          "Failure create geofences and start current geofences monitoring: %s",
          exception
        )
      )
      callback(null, Exception("createGeofences error", exception))
    }
  }

  fun startMonitoring(promise: Promise?) {
    stopMonitoring(PromiseImpl({
      this.createGeofences { idsList, exception ->
        if (exception != null) {
          Log.e(
            TAG, String.format("Failure start geofences monitoring: %s", exception)
          )
          promise?.reject(Exception("startMonitoring error", exception))
        } else {
          mIsStartedMonitoring = true
          mBootCompleted = true
          this.saveCache()
          val promiseList = WritableNativeArray()
          idsList?.forEach {
            promiseList.pushString(it)
          }
          promise?.resolve(promiseList)
        }
      }
    }, {
      this.createGeofences { idsList, exception ->
        if (exception != null) {
          Log.e(
            TAG, String.format("Failure start geofences monitoring: %s", exception)
          )
          promise?.reject(Exception("startMonitoring error", exception))
        } else {
          mIsStartedMonitoring = true
          mBootCompleted = true
          this.saveCache()
          val promiseList = WritableNativeArray()
          idsList?.forEach {
            promiseList.pushString(it)
          }
          promise?.resolve(promiseList)
        }
      }
    }))
  }

  fun stopMonitoring(promise: Promise?) {
    try {
      mGeofencingClient.removeGeofences(
        Intent(
          this.context,
          GeofenceBroadcastReceiver::class.java
        ).let {
          // Use FLAG_UPDATE_CURRENT so that you get the same pending intent back when calling
          // addGeofences() and removeGeofences().
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.getBroadcast(
              this.context,
              0,
              it,
              PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
          } else {
            PendingIntent.getBroadcast(this.context, 0, it, PendingIntent.FLAG_UPDATE_CURRENT)
          }
        }).addOnFailureListener {
        Log.e(TAG, String.format("Failure stop geofences monitoring: %s", it))
        promise?.reject(it)
      }.addOnSuccessListener {
        Log.i(TAG, "Stop geofences monitoring successfully")
        mIsStartedMonitoring = mIsStartedMonitoring.let {
          this.saveGeofencesDataToCache(mGeofencesHolderList, false, mBootCompleted)
          promise?.resolve(it)
          false
        }
      }
    } catch (exception: Exception) {
      Log.e(
        TAG, String.format("Failure stop geofences monitoring: %s", exception)
      )
      promise?.reject(Exception("stopMonitoring error", exception))
    }
  }

  fun isExistsGeofence(id: String) = this.getGeofencesByIds(arrayOf(id)).firstOrNull() != null

  fun isExistsGeofence(ids: Array<String>) = this.getGeofencesByIds(ids).firstOrNull() != null

  fun getGeofencesByIds(ids: Array<String>): List<GeofenceModel> {
    val list = ArrayList<GeofenceModel>()
    this.mGeofencesHolderList.forEachIndexed { _, geofencesHolder ->
      geofencesHolder.geofenceModels.forEachIndexed { _, geofenceModel ->
        if (ids.contains(geofenceModel.id)) {
          list.add(geofenceModel)
        }
      }
    }
    return list
  }

  fun isExistsGeofence(
    coordinates: Array<Coordinate>,
    ignoreRadius: Boolean = false
  ): List<GeofenceAtCache> {
    val list = ArrayList<GeofenceAtCache>()
    coordinates.forEach {
      list.add(isExistsGeofence(it, ignoreRadius))
    }
    return list
  }

  fun isExistsGeofence(coordinate: Coordinate, ignoreRadius: Boolean = false): GeofenceAtCache {
    this.mGeofencesHolderList.forEachIndexed { indexGeofenceHolderModelListPosition, geofencesHolder ->
      geofencesHolder.geofenceModels.forEachIndexed { indexGeofenceModelListPosition, geofenceModel ->
        if (geofenceModel.position.latitude == coordinate.latitude && geofenceModel.position.longitude == coordinate.longitude && if (!ignoreRadius) (geofenceModel.position.radius == coordinate.radius || (coordinate.radius == null || coordinate.radius < 0)) else true) return GeofenceAtCache(
          indexGeofenceHolderModelListPosition,
          indexGeofenceModelListPosition
        )
      }
    }
    return GeofenceAtCache(-1, -1)
  }

  fun removeGeofences(filter: Array<String>, promise: Promise) {
    try {
      if (filter as? Array<String> != null && filter.isNotEmpty()) {
        mGeofencingClient.removeGeofences(filter.asList()).addOnFailureListener {
          Log.e(
            TAG,
            String.format("Failure remove geofences and stop current geofences monitoring: %s", it)
          )
          promise.reject(it)
        }.addOnSuccessListener {
          mGeofencesHolderList.forEach {
            it.geofenceModels.removeAll(it.geofenceModels.filter { geofenceModel ->
              filter.contains(geofenceModel.id)
            }.toSet())
          }
          mGeofencesHolderList = mGeofencesHolderList.filter {
            it.geofenceModels.size > 0
          } as ArrayList<GeofenceHolderModel>
          this.mIsStartedMonitoring = false
          this.saveCache()
          Log.i(
            TAG,
            String.format("Remove geofences and stop current geofences monitoring successfully")
          )
          promise.resolve(true)
        }
      } else {
        this.mGeofencesHolderList.clear()
        mGeofencingClient.removeGeofences(
          Intent(
            this.context,
            GeofenceBroadcastReceiver::class.java
          ).let {
            // Use FLAG_UPDATE_CURRENT so that you get the same pending intent back when calling
            // addGeofences() and removeGeofences().
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
              PendingIntent.getBroadcast(
                this.context,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
              )
            } else {
              PendingIntent.getBroadcast(this.context, 0, it, PendingIntent.FLAG_UPDATE_CURRENT)
            }
          }).addOnFailureListener {
          Log.e(
            TAG,
            String.format("Failure remove geofences and stop current geofences monitoring: %s", it)
          )
          promise.reject(it)
        }.addOnSuccessListener {
          Log.i(
            TAG, "Remove geofences and stop current geofences monitoring successfully"
          )
          this.mIsStartedMonitoring = false
          this.saveCache()
          promise.resolve(true)
        }
      }
    } catch (exception: Exception) {
      Log.e(
        TAG,
        String.format(
          "Failure remove geofences and stop current geofences monitoring: %s",
          exception
        )
      )
      promise.reject(Exception("removeGeofences error", exception))
    }
  }

  private fun saveGeofencesDataToCache(
    geofencesHolderList: ArrayList<GeofenceHolderModel>,
    isStartedMonitoring: Boolean, bootCompleted: Boolean
  ) {
    val sharedPreferences: SharedPreferences =
      context.getSharedPreferences(CACHE_FILE_NAME, Context.MODE_PRIVATE)
    sharedPreferences.edit().putString(GEOFENCES_KEY, Gson().toJson(geofencesHolderList))
      .putBoolean(IS_STARTED_MONITORING_KEY, isStartedMonitoring)
      .putBoolean(BOOT_COMPLETED_KEY, bootCompleted)?.apply()
  }

  fun saveCache() {
    saveGeofencesDataToCache(mGeofencesHolderList, mIsStartedMonitoring, mBootCompleted)
  }

  private fun loadCache() {
    this.getGeofencesDataFromCache().let {
      this.mGeofencesHolderList = it.geofencesHolderList as ArrayList<GeofenceHolderModel>
      this.mIsStartedMonitoring = it.isStartedMonitoring
      this.mBootCompleted = it.bootCompleted
    }
  }

  private fun getGeofencesDataFromCache(): Cache {
    val sharedPreferences: SharedPreferences =
      context.getSharedPreferences(CACHE_FILE_NAME, Context.MODE_PRIVATE)
    return Cache(
      Gson().fromJson(
        sharedPreferences.getString(GEOFENCES_KEY, "[]"),
        object : TypeToken<ArrayList<GeofenceHolderModel>>() {

        }.type
      ), sharedPreferences.getBoolean(IS_STARTED_MONITORING_KEY, false),
      sharedPreferences.getBoolean(BOOT_COMPLETED_KEY, true)
    )
  }

  fun generateId(): String {
    return java.util.UUID.randomUUID().toString()
  }

}
