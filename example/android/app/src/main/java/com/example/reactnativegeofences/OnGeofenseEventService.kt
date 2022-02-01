package com.example.reactnativegeofences

import android.app.job.JobParameters
import android.app.job.JobService
import android.os.Build
import android.widget.Toast
import androidx.annotation.RequiresApi
import com.facebook.react.bridge.Arguments
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.icebergteam.timberjava.Timber
import com.reactnativegeofences.GeofenceHelper.Companion.GEOFENCES_LIST_KEY
import com.reactnativegeofences.GeofenceHelper.Companion.TRANSITION_TYPE_KEY
import com.reactnativegeofences.models.GeofenceModel
import com.reactnativegeofences.models.TypeTransactions
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException
import okhttp3.logging.HttpLoggingInterceptor
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter
import com.reactnativegeofences.utils.ArrayUtil

data class RequestModel(
  val headers: Map<String, Any?>?,
  val body: Map<String, Any?>?,
  val url: String?
)

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class OnGeofenseEventService : JobService() {
  private val client: OkHttpClient

  init {
    val logging = HttpLoggingInterceptor()
    logging.setLevel(HttpLoggingInterceptor.Level.BODY)
    logging.redactHeader("Authorization")
    logging.redactHeader("Cookie")
    client = OkHttpClient.Builder()
      .addInterceptor(logging)
      .build()
  }

  companion object {
    val JSON: MediaType = "application/json; charset=utf-8".toMediaType()
  }

  @Throws(IOException::class)
  fun post(requestModel: RequestModel?, callback: Callback) {
    val body: RequestBody = Gson().toJson(requestModel?.body).toRequestBody(JSON)
    val request: Request = Request.Builder().apply {
      requestModel?.headers?.forEach {
        this.addHeader(it.key, it.value?.toString() ?: "")
      }
    }
      .url(requestModel?.url ?: "")
      .post(body)
      .build()
    client.newCall(request)
      .enqueue(callback)
  }

  override fun onStartJob(params: JobParameters?): Boolean {
    try {
      val transitionType = params?.extras?.getInt(TRANSITION_TYPE_KEY)
      val geofencesList = params?.extras?.getString(GEOFENCES_LIST_KEY)?.let {
        Gson().fromJson<Array<GeofenceModel>>(
          it,
          object : TypeToken<Array<GeofenceModel>>() {}.type
        )
      }

      try {
        (application as MainApplication).reactNativeHost.reactInstanceManager.currentReactContext
          ?.getJSModule(RCTDeviceEventEmitter::class.java)?.apply {
            val internalParams: WritableMap = Arguments.createMap()
            internalParams.putInt(
              TRANSITION_TYPE_KEY,
              transitionType ?: TypeTransactions.UNKNOWN.typeTransaction
            )
            internalParams.putArray(
              GEOFENCES_LIST_KEY,
              ArrayUtil.toWritableArray(params?.extras?.getString(GEOFENCES_LIST_KEY)?.let {
                val fromJson = Gson().fromJson<Array<*>>(it, object : TypeToken<Array<*>>() {}.type)
                fromJson
              })
            )
            emit("onGeofenceEvent", internalParams)
          }
      }catch (exception: Exception){
        Timber.e("Can not send event to React Native: %s", exception)
      }

      geofencesList?.map {
        it.typeTransactions.entries
      }?.forEach {
        it.filter {  typeTransaction ->
          typeTransaction.key.typeTransaction == transitionType
        }.forEach { typeTransaction ->
          Gson().fromJson<RequestModel>(
            Gson().toJson(typeTransaction.value.second),
            object : TypeToken<RequestModel>() {}.type
          )?.let { requestModel ->
            this.post(requestModel, object : Callback {
              override fun onFailure(call: Call, e: IOException) {
                Timber.e("Error: %s", e)
                //  GeofenceHelper(applicationContext).stopMonitoring(null)
              }

              override fun onResponse(call: Call, response: Response) {
                Timber.i("Response: %s", response.body?.toString() ?: "no response")
              }
            })
          }
          Timber.i("Request model: $typeTransaction $transitionType")
        }
      }
      val action =
        geofencesList?.get(0)?.typeTransactions?.get(TypeTransactions.toValue(transitionType))
      val toast = Toast.makeText(
        this.applicationContext,
        action?.first?.message + " " + action?.first?.actionUri, Toast.LENGTH_LONG
      )
      toast.show()
    } catch (exception: Exception) {
      Timber.e("Error at service: %s", exception)
    }
    return true
  }

  override fun onStopJob(params: JobParameters?): Boolean {
    return true
  }
}
