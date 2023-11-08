package com.reactnativegeofences

import android.Manifest
import android.Manifest.permission
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.PermissionListener
import com.facebook.react.modules.core.PermissionAwareActivity
import com.facebook.react.bridge.WritableNativeMap
import android.content.pm.PackageManager
import androidx.appcompat.app.AlertDialog
import com.facebook.react.bridge.UiThreadUtil.runOnUiThread
import com.google.gson.Gson
import com.reactnativegeofences.models.*
import com.reactnativegeofences.utils.MapUtil
import java.util.HashMap

class GeofencesModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext), PermissionListener {
  private val mGeofenceHelper: GeofenceHelper = GeofenceHelper(reactContext)
  private var mPermissionsPromise: Promise? = null

  companion object {
    const val REQUEST_LOCATION_PERMISSION_CODE = 10123
    const val TAG = "GeofencesModule"
  }

  override fun getName(): String {
    return "Geofences"
  }

  @Suppress("UNCHECKED_CAST")
  @ReactMethod
  fun addGeofences(geofences: ReadableMap, promise: Promise) {
    Log.i(
      TAG, String.format("Add geofences: %s", geofences.toString())
    )
    val initialTriggers = ArrayList<Int>()
    geofences.getArray("initialTriggers")?.toArrayList()?.forEach {
      initialTriggers.add((it as Double).toInt())
    }
    val geofencesHolder = GeofenceHolderModel()
    geofencesHolder.initialTriggers = initialTriggers.map { value ->
      InitialTriggers.values().firstOrNull { it.trigger == value } ?: InitialTriggers.UNKNOWN
    }.toTypedArray()
    geofences.getArray("geofences")?.toArrayList()?.forEach { geofence ->
      geofence as HashMap<*, *>
      val transactionTypes =
        HashMap<TypeTransactions, Pair<NotificationDataModel?, HashMap<String, *>?>>()
      (geofence["typeTransactions"] as ArrayList<*>).toArray().forEach {
        it as HashMap<*, *>
        transactionTypes[TypeTransactions.values()
          .firstOrNull { value -> value.typeTransaction == (it.get("type") as Double).toInt() }
          ?: TypeTransactions.UNKNOWN] =
          (it["notification"] as? HashMap<String, String>)?.let { notification ->
            NotificationDataModel(
              message = notification["message"] ?: "",
              actionUri = notification["actionUri"]
            )
          } to (it["extraData"] as? HashMap<String, *>)
      }
      geofencesHolder.geofenceModels.add(
        GeofenceModel(
          typeTransactions = transactionTypes,
          expiredDuration = (geofence["expiredDuration"] as Double).toInt(),
          name = geofence["name"] as String,
          position = (geofence["position"] as HashMap<*, *>).let {
            Coordinate(
              longitude = it["longitude"] as Double,
              latitude = it["latitude"] as Double,
              radius = (it["radius"] as Double).toInt()
            )
          },
          id = mGeofenceHelper.generateId()
        )
      )
    }
    mGeofenceHelper.addGeofences(listOf(geofencesHolder))
    promise.resolve(Gson().toJson(geofencesHolder))
  }

  @RequiresApi(Build.VERSION_CODES.Q)
  @ReactMethod
  fun requestPermissions(permission: String, rationaleDialog: ReadableMap, promise: Promise) {
    Log.i(TAG, String.format("Request permission %s, %s", permission, rationaleDialog))
    if (this.currentActivity as PermissionAwareActivity? == null) {
      promise.reject(Throwable("Activity is null"))
      return
    }
    val requestPermission = {
      (this.currentActivity as PermissionAwareActivity?)?.let {
        this.mPermissionsPromise = promise
        it.requestPermissions(
          arrayOf(
            permission
          ), REQUEST_LOCATION_PERMISSION_CODE, this
        )
      }
    }
    val status = if(Build.VERSION.SDK_INT < Build.VERSION_CODES.Q && permission == Manifest.permission.ACCESS_BACKGROUND_LOCATION) true else (this.currentActivity as PermissionAwareActivity?)?.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && permission == Manifest.permission.ACCESS_BACKGROUND_LOCATION) {
      if ((this.currentActivity as PermissionAwareActivity?)?.shouldShowRequestPermissionRationale(
          Manifest.permission.ACCESS_BACKGROUND_LOCATION
        ) == true
      ) {
        runOnUiThread{
            AlertDialog.Builder(this.currentActivity!!)
              .setTitle(
                rationaleDialog.getString("title")
                  ?: this.currentActivity!!.resources.getString(R.string.app_name)
              )
              .setMessage(
                rationaleDialog.getString("message") ?: this.currentActivity!!.resources.getString(
                  R.string.rationale_message,
                  this.currentActivity!!.resources.getString(R.string.app_name)
                )
              )
              .setPositiveButton(
                rationaleDialog.getString("confirmLabel")
                  ?: this.currentActivity!!.resources.getString(
                    R.string.confirm
                  )
              ) { dialog, _ ->
                dialog.dismiss()
                requestPermission()
              }
              .setNegativeButton(
                rationaleDialog.getString("cancelLabel")
                  ?: this.currentActivity!!.resources.getString(R.string.deny)
              ) { dialog, _ ->
                dialog.dismiss()
                promise.resolve(MapUtil.toWritableMap(mutableMapOf(permission to false) as Map<String, Any>?))
              }
              .create()
              .show()
          }
      } else {
        requestPermission()
      }
    } else if (permission != Manifest.permission.ACCESS_BACKGROUND_LOCATION && status || status) {
      val permissionsResult = WritableNativeMap()
      permissionsResult.putBoolean(
        permission,
        true
      )
      val result = WritableNativeMap()
      result.putMap("result", permissionsResult)
      promise.resolve(result)
    } else {
      requestPermission()
    }
  }

  @RequiresApi(Build.VERSION_CODES.Q)
  @ReactMethod
  fun permissionsStatus(promise: Promise) {
    (this.currentActivity as PermissionAwareActivity?)?.let {
      val permissions = arrayOf(
        permission.ACCESS_FINE_LOCATION,
        permission.ACCESS_BACKGROUND_LOCATION
      ).toList()
      val result = WritableNativeMap()
      val permissionsResult = WritableNativeMap()
      var countGrantedPermissions = 0
      permissions.forEach { permission ->
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q && permission == Manifest.permission.ACCESS_BACKGROUND_LOCATION) {
          countGrantedPermissions += 1
          permissionsResult.putBoolean(
            permission,
            true
          )
          return@forEach
        }
        val check = it.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        countGrantedPermissions += if (check) 1 else 0
        permissionsResult.putBoolean(
          permission,
          check
        )
      }
      result.putString(
        "code",
        if (countGrantedPermissions == permissions.size) "ALL_GRANTED" else "SOME_GRANTED"
      )
      result.putMap("result", permissionsResult)
      if (countGrantedPermissions == 0) {
        promise.reject(Throwable("All permissions denied"))
      } else {
        promise.resolve(result)
      }
    } ?: promise.reject(Throwable("Activity is null"))
  }

  @ReactMethod
  fun clearIconBadgeNumber(promise: Promise) {
    promise.resolve(true)
  }

  @ReactMethod
  fun notificationPermissionStatus(promise: Promise) {
    promise.resolve(
      MapUtil.toWritableMap(
        mapOf<String, Any?>(
          "settings" to null,
          "authorizationStatus" to 2
        )
      )
    )
  }

  @ReactMethod
  fun requestNotificationPermission(options: ReadableArray, promise: Promise) {
    this.notificationPermissionStatus(promise)
  }

  @ReactMethod
  fun startMonitoring(promise: Promise) {
    Log.i(TAG, String.format("Start monitoring: %s", this.mGeofenceHelper.mGeofencesHolderList))
    mGeofenceHelper.startMonitoring(promise)
  }

  @ReactMethod
  fun stopMonitoring(promise: Promise) {
    Log.i(TAG, String.format("Stop monitoring: %s", this.mGeofenceHelper.mGeofencesHolderList))
    mGeofenceHelper.stopMonitoring(promise)
  }

  @Suppress("UNCHECKED_CAST")
  @ReactMethod
  fun removeGeofences(filter: ReadableArray, promise: Promise) {
    Log.i(TAG, String.format("Remove geofences, filter: %s", filter))
    mGeofenceHelper.removeGeofences(filter as? Array<String> ?: arrayOf(), promise)
  }

  @ReactMethod
  fun isExistsGeofenceById(id: String, promise: Promise) {
    Log.i(TAG, String.format("Is exists Geofence by id: %s", id))
    promise.resolve(mGeofenceHelper.isExistsGeofence(id))
  }

  @Suppress("UNCHECKED_CAST")
  @ReactMethod
  fun isExistsGeofenceByListId(ids: ReadableArray, promise: Promise) {
    Log.i(TAG, String.format("Is exists Geofence by list ids: %s", ids))
    promise.resolve(mGeofenceHelper.isExistsGeofence(ids as? Array<String> ?: arrayOf()))
  }

  @Suppress("UNCHECKED_CAST")
  @ReactMethod
  fun isExistsGeofenceByListCoordinate(coordinates: ReadableArray, promise: Promise) {
    val coordinatesRefactor = coordinates.toArrayList().map {
      it as HashMap<String, *>
      Coordinate(
        longitude = it["longitude"] as Double,
        latitude = it["latitude"] as Double,
        radius = (it["radius"] as? Double)?.toInt()
      )
    }
    val result = mGeofenceHelper.isExistsGeofence(coordinatesRefactor.toTypedArray()).let {
      it.isNotEmpty() && !it.contains(GeofenceAtCache(-1, -1))
    }
    Log.i(
      TAG, String.format(
        "Is exists Geofence by list coordinates: %s, %s, %s",
        coordinates,
        result,
        mGeofenceHelper.mGeofencesHolderList
      )
    )
    promise.resolve(result)
  }

  @ReactMethod
  fun isExistsGeofenceByCoordinate(coordinate: ReadableMap, promise: Promise) {
    val coordinateModel = Coordinate(
      longitude = coordinate.getDouble("longitude"),
      latitude = coordinate.getDouble("latitude"),
      radius = coordinate.getDouble("radius").toInt()
    )
    val result =
      mGeofenceHelper.isExistsGeofence(coordinateModel).atGeofenceHolderModelListPosition >= 0
    Log.i(TAG, String.format("Is exists Geofence by coordinate: %s, %s", coordinate, result))
    promise.resolve(result)
  }

  @ReactMethod
  fun isStartedMonitoring(promise: Promise) {
    Log.i(
      TAG,
      String.format("Is started monitoring: %s", this.mGeofenceHelper.mIsStartedMonitoring)
    )
    promise.resolve(this.mGeofenceHelper.mIsStartedMonitoring && this.mGeofenceHelper.mBootCompleted)
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>?,
    grantResults: IntArray
  ): Boolean {
    if (requestCode == REQUEST_LOCATION_PERMISSION_CODE) {
      val permissionsResult = WritableNativeMap()
      permissions?.forEachIndexed { index, permission ->
        permissionsResult.putBoolean(
          permission,
          grantResults[index] == PackageManager.PERMISSION_GRANTED
        )
      }
      val result = WritableNativeMap()
      result.putMap("result", permissionsResult)
      this.mPermissionsPromise?.resolve(result)
    }
    return true
  }
}
