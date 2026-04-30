package com.kulturnatten.transit.model

data class TransitLegResponse(
    val type: String,
    val line: String?,
    val direction: String?,
    val originName: String,
    val destinationName: String,
    val departureTime: String,
    val arrivalTime: String
)