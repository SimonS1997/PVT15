package com.kulturnatten.events.controller

import com.kulturnatten.events.model.EventResponse
import com.kulturnatten.events.service.EventService
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`
import org.springframework.http.HttpStatus
import kotlin.test.assertEquals
import kotlin.test.assertNull

class EventControllerTest {

    private lateinit var service: EventService
    private lateinit var controller: EventController

    @BeforeEach
    fun setup() {
        // mocka servicen så controllern kan testas utan databas
        service = mock(EventService::class.java)
        controller = EventController(service)
    }

    @Test
    fun `getEvent returnerar 200 med event när servicen hittar det`() {
        // bygg ett dummy-event som servicen ska låtsas returnera
        val event = EventResponse(
            id = 1,
            name = "Konsert",
            venue = "Konserthuset",
            address = "Hötorget 8",
            timeStart = "19:00",
            timeEnd = "21:00",
            district = "City",
            description = "Live music",
            bookingRequired = false,
            nearestStation = "Hötorget",
            latitude = 59.33,
            longitude = 18.06,
            category = "MUSIC",
        )
        `when`(service.getById(1)).thenReturn(event)

        val response = controller.getEvent(1)

        // 200 OK med eventet i body när det finns
        assertEquals(HttpStatus.OK, response.statusCode)
        assertEquals(event, response.body)
    }

    @Test
    fun `getEvent returnerar 404 när servicen returnerar null`() {
        // servicen hittar inget event för id 999
        `when`(service.getById(999)).thenReturn(null)

        val response = controller.getEvent(999)

        // 404 utan body när eventet inte finns
        assertEquals(HttpStatus.NOT_FOUND, response.statusCode)
        assertNull(response.body)
    }
}
