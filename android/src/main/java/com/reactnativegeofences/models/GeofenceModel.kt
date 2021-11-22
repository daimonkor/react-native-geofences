package com.reactnativegeofences.models

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

@Parcelize
data class GeofenceModel(
  val position: Coordinate,
  val name: String,
  val typeTransactions: Map<TypeTransactions, Pair<NotificationDataModel?, HashMap<String,*>?>>,
  val expiredDuration: Int,
  val id: String
) : Parcelable
