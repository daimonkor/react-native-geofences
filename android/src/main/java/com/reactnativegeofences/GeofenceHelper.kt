package com.reactnativegeofences

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
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
import com.icebergteam.timberjava.Timber
import com.reactnativegeofences.models.*
import java.lang.Exception

class GeofenceHelper(private val context: Context) {
  var mGeofencesHolderList = ArrayList<GeofenceHolderModel>()
    private set
  private val mGeofencingClient: GeofencingClient = LocationServices.getGeofencingClient(context);
  var isStartedMonitoring = false

  companion object {
    const val CACHE_FILE_NAME = "GEOFENCES_CACHE"
    const val CACHE_KEY = "GEOFENCES_KEY"
    const val IS_STARTED_MONITORING_KEY = "IS_STARTED_MONITORING_KEY"
    const val GEOFENCES_LIST_KEY = "GEOFENCES_LIST_KEY"
    const val TRANSITION_TYPE_KEY = "TRANSITION_TYPE_KEY"
  }

  init {
    this.getGeofencesDataFromCache().let {
      this.mGeofencesHolderList = it.mGeofencesHolderList as ArrayList<GeofenceHolderModel>
      this.isStartedMonitoring = it.isStartedMonitoring
    }
  }

  fun addGeofences(geofencesHolderList: List<GeofenceHolderModel>) {
    geofencesHolderList.forEach {
      it.geofenceModels.forEach {
        val indexes = this.isExistsGeofence(it.position)
        if (indexes.atGeofenceHolderModelListPosition >= 0) {
          mGeofencesHolderList[indexes.atGeofenceHolderModelListPosition].geofenceModels.removeAt(
            indexes.atGeofenceModelListPosition
          )
          if (mGeofencesHolderList[indexes.atGeofenceHolderModelListPosition].geofenceModels.isEmpty()) {
            mGeofencesHolderList.removeAt(indexes.atGeofenceHolderModelListPosition)
          }
        }
      }
    }
    mGeofencesHolderList.addAll(geofencesHolderList)
    this.saveGeofencesDataToCache(this.mGeofencesHolderList, this.isStartedMonitoring)
  }

  private fun createGeofences(callback: (geofenceIdList: Array<String>?, exception: Exception?) -> Unit) {
    try {
      if (mGeofencesHolderList.isEmpty()) {
        callback(null, Exception("Missing geofences"))
        Timber.e("Please add geofences")
        return
      }
      val geofenceIdList = ArrayList<String>()
      mGeofencesHolderList.forEach {
        if (ActivityCompat.checkSelfPermission(
            this.context,
            Manifest.permission.ACCESS_FINE_LOCATION
          ) != PackageManager.PERMISSION_GRANTED
        ) {
          callback(null, Exception("ACCESS_FINE_LOCATION denied"))
          return
        }
        mGeofencingClient.addGeofences(GeofencingRequest.Builder().apply {
          addGeofences(
            it.geofenceModels.map {
              geofenceIdList.add(it.id)
              Geofence.Builder()
                .setRequestId(it.id)
                .setCircularRegion(
                  it.position.latitude,
                  it.position.longitude,
                  it.position.radius?.toFloat() ?: 400f
                )
                .setExpirationDuration(it.expiredDuration.toLong())
                .setTransitionTypes(it.typeTransactions.map {
                  it.key
                }.let {
                  var type = it.first().typeTransaction
                  it.forEachIndexed { index, i ->
                    if (index != 0) {
                      type = type or i.typeTransaction;
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
          PendingIntent.getBroadcast(
            this.context,
            0,
            it,
            PendingIntent.FLAG_UPDATE_CURRENT
          )
        }).addOnSuccessListener {
          callback(geofenceIdList.toTypedArray(), null)
        }.addOnFailureListener {
          callback(null, it)
        }
      }
    } catch (exception: Exception) {
      callback(null, exception)
    }
  }

  fun startMonitoring(promise: Promise?) {
    stopMonitoring(PromiseImpl({
      Timber.e("Stop geofences monitoring successfully")
      this.createGeofences { idsList, exception ->
        if (exception != null) {
          promise?.reject(exception)
        } else {
          isStartedMonitoring = true
          this.saveGeofencesDataToCache(mGeofencesHolderList, isStartedMonitoring)
          val promiseList = WritableNativeArray()
          idsList?.forEach {
            promiseList.pushString(it)
          }
          promise?.resolve(promiseList)
        }
      }
    }, {
      Timber.e("Stop geofences monitoring failed: $it")
      this.createGeofences { idsList, exception ->
        if (exception != null) {
          promise?.reject(exception)
        } else {
          isStartedMonitoring = true
          this.saveGeofencesDataToCache(mGeofencesHolderList, isStartedMonitoring)
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
      Timber.e("Stop monitoring")
      mGeofencingClient.removeGeofences(
        Intent(
          this.context,
          GeofenceBroadcastReceiver::class.java
        ).let {
          PendingIntent.getBroadcast(
            this.context,
            0,
            it,
            PendingIntent.FLAG_UPDATE_CURRENT
          )
        }).addOnFailureListener {
        promise?.reject(it)
      }.addOnSuccessListener {
        isStartedMonitoring = false
        this.saveGeofencesDataToCache(mGeofencesHolderList, isStartedMonitoring)
        promise?.resolve(true)
      }
    } catch (exception: Exception) {
      promise?.reject(exception)
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

  fun isExistsGeofence(coordinates: Array<Coordinate>): List<GeofenceAtCache> {
    val list = ArrayList<GeofenceAtCache>()
    coordinates.forEach {
      list.add(isExistsGeofence(it))
    }
    return list
  }

  fun isExistsGeofence(coordinate: Coordinate): GeofenceAtCache {
    this.mGeofencesHolderList.forEachIndexed { indexGeofenceHolderModelListPosition, geofencesHolder ->
      geofencesHolder.geofenceModels.forEachIndexed { indexGeofenceModelListPosition, geofenceModel ->
        if (geofenceModel.position.latitude == coordinate.latitude && geofenceModel.position.longitude == coordinate.longitude && (geofenceModel.position.radius == coordinate.radius || (coordinate.radius == null || coordinate.radius < 0))) return GeofenceAtCache (indexGeofenceHolderModelListPosition, indexGeofenceModelListPosition)
      }
    }
    return  GeofenceAtCache (-1, -1)
  }

  fun removeGeofences(filter: Array<String>, promise: Promise) {
    try {
      if (filter as? Array<String> != null && filter.isNotEmpty()) {
        mGeofencingClient.removeGeofences(filter.asList()).addOnFailureListener {
          promise.reject(it)
        }.addOnSuccessListener {
          mGeofencesHolderList.forEach {
            it.geofenceModels.removeAll(it.geofenceModels.filter {
              filter.contains(it.id)
            }.toSet())
          }
          mGeofencesHolderList = mGeofencesHolderList.filter {
            it.geofenceModels.size > 0
          } as ArrayList<GeofenceHolderModel>
          this.isStartedMonitoring = false
          this.saveGeofencesDataToCache(mGeofencesHolderList, this.isStartedMonitoring)
          promise.resolve(true)
        }
      } else {
        this.mGeofencesHolderList.clear()
        mGeofencingClient.removeGeofences(
          Intent(
            this.context,
            GeofenceBroadcastReceiver::class.java
          ).let {
            PendingIntent.getBroadcast(
              this.context,
              0,
              it,
              PendingIntent.FLAG_UPDATE_CURRENT
            )
          }).addOnFailureListener {
          promise.reject(it)
        }.addOnSuccessListener {
          this.isStartedMonitoring = false
          this.saveGeofencesDataToCache(this.mGeofencesHolderList, this.isStartedMonitoring)
          promise.resolve(true)
        }
      }
    } catch (exception: Exception) {
      promise.reject(exception)
    }
  }

  private fun saveGeofencesDataToCache(
    geofencesHolderList: ArrayList<GeofenceHolderModel>,
    isStartedMonitoring: Boolean
  ) {
    val sharedPreferences: SharedPreferences =
      context.getSharedPreferences(CACHE_FILE_NAME, Context.MODE_PRIVATE)
    sharedPreferences.edit().putString(CACHE_KEY, Gson().toJson(geofencesHolderList))
      .putBoolean(IS_STARTED_MONITORING_KEY, isStartedMonitoring)?.apply()
  }

  private fun getGeofencesDataFromCache(): Cache {
    val sharedPreferences: SharedPreferences =
      context.getSharedPreferences(CACHE_FILE_NAME, Context.MODE_PRIVATE)
    return Cache(
      Gson().fromJson(
        sharedPreferences.getString(CACHE_KEY, "[]"),
        object : TypeToken<ArrayList<GeofenceHolderModel>>() {

        }.type
      ), sharedPreferences.getBoolean(IS_STARTED_MONITORING_KEY, false)
    )
  }

  fun generateId(): String {
    return java.util.UUID.randomUUID().toString()
  }

}
