package com.reactnativegeofences.models

import android.os.Parcelable
import kotlinx.parcelize.Parcelize


@Parcelize
data class NotificationDataModel(val message: String, val actionUri: String?) : Parcelable
