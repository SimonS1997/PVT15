package com.kulturnatten.events.controller

import com.kulturnatten.events.model.EventResponse
import com.kulturnatten.events.service.EventService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/events")
class EventController(
    private val eventService: EventService
) {
    @GetMapping
    fun getEvents(
        @RequestParam(required = false) category: String?,
        @RequestParam(required = false) search: String?
    ): List<EventResponse> {
        return eventService.getAllEvents(category, search)
    }

    @GetMapping("/{id}")
    fun getEvent(@PathVariable id: Int): ResponseEntity<EventResponse> {
        val event = eventService.getById(id)
        return if (event != null) {
            ResponseEntity.ok(event)
        } else {
            ResponseEntity.notFound().build()
        }
    }
}
