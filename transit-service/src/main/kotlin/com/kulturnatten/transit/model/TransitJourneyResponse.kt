package com.kulturnatten.transit.model

data class TransitJourneyResponse(
    val origin: String,
    val destination: String,
    val trips: List<TransitTripResponse>
)