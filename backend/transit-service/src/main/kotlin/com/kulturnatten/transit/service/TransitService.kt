package com.kulturnatten.transit.service

import com.kulturnatten.transit.client.SlApiClient
import com.kulturnatten.transit.model.LegPlanLeg
import com.kulturnatten.transit.model.LegPlanResponse
import com.kulturnatten.transit.model.LegPlanStop
import com.kulturnatten.transit.model.LegSegment
import com.kulturnatten.transit.model.TransitJourneyResponse
import org.springframework.stereotype.Service

@Service
class TransitService(
    private val slApiClient: SlApiClient
) {
    fun planJourney(origin: String, destination: String): TransitJourneyResponse {
        return slApiClient.planJourney(origin, destination)
    }

    fun planLegs(stops: List<LegPlanStop>): LegPlanResponse {
        if (stops.size < 2) return LegPlanResponse(emptyList())

        val legs = stops.zipWithNext().map { (from, to) ->
            val plan = slApiClient.planTripByCoord(
                originLat = from.lat,
                originLon = from.lon,
                originName = from.name,
                destLat = to.lat,
                destLon = to.lon,
                destName = to.name,
                departTime = from.startTime,
            )
            LegPlanLeg(
                from = from.name,
                to = to.name,
                travelMinutes = plan.travelMinutes,
                segments = plan.segments.map {
                    LegSegment(it.type, it.line, it.direction, it.fromName, it.toName, it.durationMinutes)
                },
            )
        }
        return LegPlanResponse(legs)
    }
}