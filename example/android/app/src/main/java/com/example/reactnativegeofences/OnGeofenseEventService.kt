package com.example.reactnativegeofences

import android.app.job.JobParameters
import android.app.job.JobService
import android.os.Build
import android.widget.Toast
import androidx.annotation.RequiresApi
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.icebergteam.timberjava.Timber
import com.reactnativegeofences.GeofenceHelper
import com.reactnativegeofences.GeofenceHelper.Companion.GEOFENCES_LIST_KEY
import com.reactnativegeofences.GeofenceHelper.Companion.TRANSITION_TYPE_KEY
import com.reactnativegeofences.models.GeofenceModel
import com.reactnativegeofences.models.TypeTransactions
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException
import okhttp3.logging.HttpLoggingInterceptor

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
    logging.redactHeader("Authorization");
    logging.redactHeader("Cookie");
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
    val transitionType = params?.extras?.getInt(TRANSITION_TYPE_KEY)
    val geofencesList = params?.extras?.getString(GEOFENCES_LIST_KEY)?.let {
      Gson().fromJson<Array<GeofenceModel>>(it, object : TypeToken<Array<GeofenceModel>>() {}.type)
    }
    geofencesList?.map {
      it.typeTransactions.entries
    }?.forEach {
      it.filter {
        it.key.typeTransaction == transitionType
      }.forEach {
        Gson().fromJson<RequestModel>(
          Gson().toJson(it.value.second),
          object : TypeToken<RequestModel>() {}.type
        )?.let {
          this.post(it, object : Callback {
            override fun onFailure(call: Call, e: IOException) {
              Timber.e("Error: %s", e)
            //  GeofenceHelper(applicationContext).stopMonitoring(null)
            }

            override fun onResponse(call: Call, response: Response) {
              Timber.e("Response: %s", response.body?.toString() ?: "no response")
            }

          })
        }
        Timber.e("Request model: %s", (it.toString() ?: "none") + " " + transitionType)
      }
    }
    val action =
      geofencesList?.get(0)?.typeTransactions?.get(TypeTransactions.toValue(transitionType))
    val toast = Toast.makeText(
      this.applicationContext,
      action?.first?.message + " " + action?.first?.actionUri, Toast.LENGTH_LONG
    )
    toast.show()
    return true
  }

  override fun onStopJob(params: JobParameters?): Boolean {
    return true
  }
}