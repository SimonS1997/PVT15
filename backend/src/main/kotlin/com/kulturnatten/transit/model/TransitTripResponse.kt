package com.kulturnatten.transit.model

data class TransitTripResponse(
    val duration: String,
    val legs: List<TransitLegResponse>
)