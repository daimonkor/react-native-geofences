package com.reactnativegeofences.models

import android.os.Parcelable
import kotlinx.parcelize.Parcelize


@Parcelize
data class Coordinate(val longitude: Double, val latitude: Double, val radius: Int? = null) :
    Parcelable
