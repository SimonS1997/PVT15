package com.kulturnatten.events.model

data class EventResponse(
    val id: Int,
    val name: String,
    val venue: String,
    val address: String,
    val timeStart: String?,
    val timeEnd: String?,
    val district: String?,
    val description: String?,
    val bookingRequired: Boolean,
    val nearestStation: String?,
    val latitude: Double,
    val longitude: Double,
    val category: String?
)