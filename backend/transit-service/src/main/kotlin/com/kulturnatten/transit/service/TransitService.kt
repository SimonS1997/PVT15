package com.kulturnatten.transit.service

import com.kulturnatten.transit.client.SlApiClient
import com.kulturnatten.transit.model.TransitJourneyResponse
import org.springframework.stereotype.Service

@Service
class TransitService(
    private val slApiClient: SlApiClient
) {
    fun planJourney(origin: String, destination: String): TransitJourneyResponse {
        return slApiClient.planJourney(origin, destination)
    }
}