package com.kulturnatten.events.controller

import com.kulturnatten.events.model.EventResponse
import com.kulturnatten.events.service.EventService
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/events")
class EventController(
    private val eventService: EventService
) {
    @GetMapping
    fun getEvents(): List<EventResponse> {
        return eventService.getAllEvents()
    }
}