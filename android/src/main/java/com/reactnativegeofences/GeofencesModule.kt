package com.reactnativegeofences

import android.Manifest.permission
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.PermissionListener
import com.facebook.react.modules.core.PermissionAwareActivity
import com.facebook.react.bridge.WritableNativeMap
import android.content.pm.PackageManager

data class PermissionsStatus(
  var code: String = "",
  var result: MutableMap<String, Boolean> = mutableMapOf()
)

class GeofencesModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext), PermissionListener {

  private val mGeofenceHelper: GeofenceHelper = GeofenceHelper(reactContext)
  var mPermissionsPromise: Promise? = null
  var permissionsMap = PermissionsStatus()

  companion object {
    const val TAG = "GeofencesModule"
    const val REQUEST_LOCATION_PERMISSION_CODE = 10123
  }

  override fun getName(): String {
    return "Geofences"
  }

  @ReactMethod
  fun addGeofences(geofences: ReadableMap, promise: Promise) {
    Log.e(TAG, geofences.toString())
    val initialTriggers = ArrayList<Int>()
    geofences.getArray("initialTriggers")?.toArrayList()?.forEach {
      initialTriggers.add((it as Double).toInt())
    }
    val geofencesHolder = GeofenceHolderModel()
    geofencesHolder.initialTriggers = initialTriggers.toIntArray()
    geofences.getArray("geofences")?.toArrayList()?.forEach {
      it as HashMap<*, *>
      val transactionTypes = HashMap<Int, NotificationDataModel>()
      (it.get("typeTransactions") as ArrayList<*>).toArray().forEach {
        it as HashMap<*, *>
        transactionTypes[(it.get("type") as Double).toInt()] =
          (it.get("notification") as HashMap<String, String>).let {
            NotificationDataModel(
              message = it.get("message") ?: "",
              request = it.get("request")
            )
          }
      }
      geofencesHolder.geofenceModels.add(
        GeofenceModel(
          typeTransactions = transactionTypes,
          expiredDuration = (it.get("expiredDuration") as Double).toInt(),
          name = it.get("name") as String,
          position = (it.get("position") as HashMap<*, *>).let {
            Coordinate(
              longitude = it.get("longitude") as Double,
              latitude = it.get("latitude") as Double,
              radius = (it.get("radius") as Double).toInt()
            )
          },
          id = mGeofenceHelper.generateId()
        )
      )
    }
    mGeofenceHelper.addGeofences(listOf(geofencesHolder))
    promise.resolve(true)
  }

  @RequiresApi(Build.VERSION_CODES.Q)
  @ReactMethod
  fun requestPermissions(permission: String, promise: Promise) {
    (this.currentActivity as PermissionAwareActivity?)?.let {
      this.mPermissionsPromise = promise
      it.requestPermissions(
        arrayOf(
          permission
           ), REQUEST_LOCATION_PERMISSION_CODE, this
      )
    } ?: promise.reject(Throwable("Activity is null"))
  }

  @RequiresApi(Build.VERSION_CODES.Q)
  @ReactMethod
  fun isAcceptedPermissions(promise: Promise) {
    (this.currentActivity as PermissionAwareActivity?)?.let {
      val permissions = arrayOf(
        permission.ACCESS_FINE_LOCATION,
        permission.ACCESS_BACKGROUND_LOCATION
      ).toList()

      val result = WritableNativeMap()
      val permissionsResult = WritableNativeMap()
      var countGrantedPermissions = 0
      permissions.forEach { permission ->
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
  fun startMonitoring(promise: Promise) {
    mGeofenceHelper.startMonitoring(promise)
  }

  @ReactMethod
  fun stopMonitoring(promise: Promise) {
    mGeofenceHelper.stopMonitoring(promise)
  }

  @ReactMethod
  fun removeGeofences(filter: ReadableArray, promise: Promise) {
    mGeofenceHelper.removeGeofences(filter as? Array<String> ?: arrayOf(), promise)
  }

  @ReactMethod
  fun isExistsGeofenceById(id: String, promise: Promise) {
    promise.resolve(mGeofenceHelper.isExistsGeofence(id).atGeofenceHolderModelListPosition >= 0)
  }

  @ReactMethod
  fun isExistsGeofenceByCoordinate(coordinate: ReadableMap, promise: Promise) {
    val coordinate = Coordinate(
      longitude = coordinate.getDouble("longitude"),
      latitude = coordinate.getDouble("latitude")
    )
    promise.resolve(mGeofenceHelper.isExistsGeofence(coordinate).atGeofenceHolderModelListPosition >= 0)
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
