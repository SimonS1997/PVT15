package com.kulturnatten.transit.model

data class LegPlanRequest(
    val stops: List<LegPlanStop>
)

data class LegPlanStop(
    val name: String,
    val lat: Double,
    val lon: Double,
    val startTime: String?
)

data class LegPlanResponse(
    val legs: List<LegPlanLeg>
)

data class LegPlanLeg(
    val from: String,
    val to: String,
    val travelMinutes: Int
)
