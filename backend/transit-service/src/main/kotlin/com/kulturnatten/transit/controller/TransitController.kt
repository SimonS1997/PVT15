package com.kulturnatten.transit.controller

import com.kulturnatten.transit.model.TransitJourneyResponse
import com.kulturnatten.transit.model.TransitRequest
import com.kulturnatten.transit.service.TransitService
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/transit")
@CrossOrigin
class TransitController(
    private val transitService: TransitService
) {

    @PostMapping("/journey")
    fun planJourney(@RequestBody request: TransitRequest): TransitJourneyResponse {
        return transitService.planJourney(
            origin = request.origin,
            destination = request.destination
        )
    }
}