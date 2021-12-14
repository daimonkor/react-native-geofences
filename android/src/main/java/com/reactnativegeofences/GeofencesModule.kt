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
import com.google.gson.Gson
import com.icebergteam.timberjava.LineNumberDebugTree
import com.icebergteam.timberjava.Timber
import com.reactnativegeofences.models.*
import java.util.HashMap

class GeofencesModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext), PermissionListener {
  private val mGeofenceHelper: GeofenceHelper = GeofenceHelper(reactContext)
  private var mPermissionsPromise: Promise? = null

  companion object {
    const val REQUEST_LOCATION_PERMISSION_CODE = 10123
    private fun initLogger() {
      Timber.plant(object : LineNumberDebugTree() {
        override fun createStackElementTag(element: StackTraceElement): String {
          var tag = element.className
          val m = ANONYMOUS_CLASS.matcher(tag)
          if (m.find()) {
            tag = m.replaceAll("")
          }
          tag = tag.substring(tag.lastIndexOf('.') + 1)
          // Tag length limit was removed in API 24.
          if (tag.length <= MAX_TAG_LENGTH || Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            return String.format("%s (%s)", tag, element.lineNumber)
          }
          val className =
            tag.substring(0, MAX_TAG_LENGTH).split("$".toRegex()).toTypedArray()[0]
          return String.format(
            "(%s.kt:%s#%s",
            className,
            element.lineNumber,
            element.methodName
          )
        }

        override fun wtf(tag: String, message: String) {
          Log.wtf(tag, message)
        }

        override fun println(priority: Int, tag: String, message: String) {
          Log.println(priority, tag, message)
        }
      })
    }
  }

  init {
    initLogger()
  }

  override fun getName(): String {
    return "Geofences"
  }

  @ReactMethod
  fun addGeofences(geofences: ReadableMap, promise: Promise) {
    Timber.e("Add geofences: %s", geofences.toString())
    val initialTriggers = ArrayList<Int>()
    geofences.getArray("initialTriggers")?.toArrayList()?.forEach {
      initialTriggers.add((it as Double).toInt())
    }
    val geofencesHolder = GeofenceHolderModel()
    geofencesHolder.initialTriggers =  initialTriggers.map { value ->
      InitialTriggers.values().firstOrNull { it.trigger == value }?: InitialTriggers.UNKNOWN
    }.toTypedArray()
    geofences.getArray("geofences")?.toArrayList()?.forEach {
      it as HashMap<*, *>
      val transactionTypes = HashMap<TypeTransactions, Pair<NotificationDataModel?, HashMap<String, *>?>>()
      (it.get("typeTransactions") as ArrayList<*>).toArray().forEach {
        it as HashMap<*, *>
        transactionTypes[TypeTransactions.values().firstOrNull { value ->  value.typeTransaction ==  (it.get("type") as Double).toInt()}?: TypeTransactions.UNKNOWN ] =
          (it.get("notification") as? HashMap<String, String>)?.let {
            NotificationDataModel(
              message = it.get("message") ?: "",
              actionUri = it.get("actionUri")
            )
          } to (it.get("extraData") as? HashMap<String, *>)
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
    promise.resolve(Gson().toJson(geofencesHolder))
  }

  @RequiresApi(Build.VERSION_CODES.Q)
  @ReactMethod
  fun requestPermissions(permission: String, promise: Promise) {
    Timber.e("Request permission %s", permission)
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
    Timber.e("Start monitoring: %s", this.mGeofenceHelper.mGeofencesHolderList)
    mGeofenceHelper.startMonitoring(promise)
  }

  @ReactMethod
  fun stopMonitoring(promise: Promise) {
    Timber.e("Stop monitoring: %s", this.mGeofenceHelper.mGeofencesHolderList)
    mGeofenceHelper.stopMonitoring(promise)
  }

  @ReactMethod
  fun removeGeofences(filter: ReadableArray, promise: Promise) {
    Timber.e("Remove geofences, filter: %s", filter)
    mGeofenceHelper.removeGeofences(filter as? Array<String> ?: arrayOf(), promise)
  }

  @ReactMethod
  fun isExistsGeofenceById(id: String, promise: Promise) {
    Timber.e("Is exists Geofence by id: %s", id)
    promise.resolve(mGeofenceHelper.isExistsGeofence(id))
  }

  @ReactMethod
  fun isExistsGeofenceByCoordinate(coordinate: ReadableMap, promise: Promise) {
    Timber.e("Is exists Geofence by coordinate: %s", coordinate)
    val coordinateModel = Coordinate(
      longitude = coordinate.getDouble("longitude"),
      latitude = coordinate.getDouble("latitude")
    )
    promise.resolve(mGeofenceHelper.isExistsGeofence(coordinateModel).atGeofenceHolderModelListPosition >= 0)
  }

  @ReactMethod
  fun isStartedMonitoring(promise: Promise) {
    Timber.e("Is started monitoring: %s", this.mGeofenceHelper.isStartedMonitoring)
    promise.resolve(this.mGeofenceHelper.isStartedMonitoring)
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
