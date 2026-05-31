package com.kulturnatten.transit.service

import com.kulturnatten.transit.client.SlApiClient
import com.kulturnatten.transit.model.LegPlanStop
import com.kulturnatten.transit.model.TransitJourneyResponse
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import org.mockito.Mockito.verifyNoMoreInteractions
import org.mockito.Mockito.`when`
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class TransitServiceTest {

    private lateinit var slApiClient: SlApiClient
    private lateinit var service: TransitService

    @BeforeEach
    fun setup() {
        slApiClient = mock(SlApiClient::class.java)
        service = TransitService(slApiClient)
    }

    @Test
    fun `planJourney delegates to sl api client`() {
        val journey = TransitJourneyResponse(
            origin = "ABF Stockholm",
            destination = "Konserthuset",
            trips = emptyList(),
        )
        `when`(slApiClient.planJourney("ABF Stockholm", "Konserthuset"))
            .thenReturn(journey)

        val result = service.planJourney("ABF Stockholm", "Konserthuset")

        assertEquals(journey, result)
        verify(slApiClient).planJourney("ABF Stockholm", "Konserthuset")
        verifyNoMoreInteractions(slApiClient)
    }

    @Test
    fun `planLegs returns empty response when fewer than two stops are provided`() {
        val result = service.planLegs(
            listOf(
                stop(name = "ABF Stockholm"),
            )
        )

        assertTrue(result.legs.isEmpty())
        verify(slApiClient, never()).planTripByCoord(
            originLat = 59.0,
            originLon = 18.0,
            originName = "ABF Stockholm",
            destLat = 59.0,
            destLon = 18.0,
            destName = "Konserthuset",
            departTime = "18:00",
        )
    }

    @Test
    fun `planLegs creates one leg for each adjacent stop pair`() {
        val first = stop(
            name = "ABF Stockholm",
            lat = 59.335,
            lon = 18.059,
            startTime = "18:00",
        )
        val second = stop(
            name = "Konserthuset",
            lat = 59.334,
            lon = 18.063,
            startTime = "19:00",
        )
        val third = stop(
            name = "Operan",
            lat = 59.329,
            lon = 18.071,
            startTime = null,
        )

        `when`(
            slApiClient.planTripByCoord(
                originLat = first.lat,
                originLon = first.lon,
                originName = first.name,
                destLat = second.lat,
                destLon = second.lon,
                destName = second.name,
                departTime = first.startTime,
            )
        ).thenReturn(
            tripPlan(
                travelMinutes = 12,
                segment = segment(
                    type = "WALK",
                    line = null,
                    direction = null,
                    fromName = "ABF Stockholm",
                    toName = "Konserthuset",
                    durationMinutes = 12,
                )
            )
        )
        `when`(
            slApiClient.planTripByCoord(
                originLat = second.lat,
                originLon = second.lon,
                originName = second.name,
                destLat = third.lat,
                destLon = third.lon,
                destName = third.name,
                departTime = second.startTime,
            )
        ).thenReturn(
            tripPlan(
                travelMinutes = 8,
                segment = segment(
                    type = "METRO",
                    line = "11",
                    direction = "Kungstradgarden",
                    fromName = "Hotorget",
                    toName = "Kungstradgarden",
                    durationMinutes = 3,
                )
            )
        )

        val result = service.planLegs(listOf(first, second, third))

        assertEquals(2, result.legs.size)
        assertEquals("ABF Stockholm", result.legs[0].from)
        assertEquals("Konserthuset", result.legs[0].to)
        assertEquals(12, result.legs[0].travelMinutes)
        assertEquals("WALK", result.legs[0].segments.single().type)
        assertEquals("ABF Stockholm", result.legs[0].segments.single().fromName)
        assertEquals("Konserthuset", result.legs[0].segments.single().toName)

        assertEquals("Konserthuset", result.legs[1].from)
        assertEquals("Operan", result.legs[1].to)
        assertEquals(8, result.legs[1].travelMinutes)
        assertEquals("METRO", result.legs[1].segments.single().type)
        assertEquals("11", result.legs[1].segments.single().line)
        assertEquals("Kungstradgarden", result.legs[1].segments.single().direction)
    }

    @Test
    fun `planLegs preserves segment duration when client provides it`() {
        val first = stop(name = "A", startTime = "20:00")
        val second = stop(name = "B")
        `when`(
            slApiClient.planTripByCoord(
                originLat = first.lat,
                originLon = first.lon,
                originName = first.name,
                destLat = second.lat,
                destLon = second.lon,
                destName = second.name,
                departTime = first.startTime,
            )
        ).thenReturn(
            tripPlan(
                travelMinutes = 5,
                segment = segment(durationMinutes = 5),
            )
        )

        val result = service.planLegs(listOf(first, second))

        assertEquals(5, result.legs.single().segments.single().durationMinutes)
    }

    private fun stop(
        name: String,
        lat: Double = 59.0,
        lon: Double = 18.0,
        startTime: String? = "18:00",
    ): LegPlanStop {
        return LegPlanStop(
            name = name,
            lat = lat,
            lon = lon,
            startTime = startTime,
        )
    }

    private fun tripPlan(
        travelMinutes: Int,
        segment: SlApiClient.SegmentInfo,
    ): SlApiClient.TripPlan {
        return SlApiClient.TripPlan(
            travelMinutes = travelMinutes,
            segments = listOf(segment),
        )
    }

    private fun segment(
        type: String = "WALK",
        line: String? = null,
        direction: String? = null,
        fromName: String = "A",
        toName: String = "B",
        durationMinutes: Int? = null,
    ): SlApiClient.SegmentInfo {
        return SlApiClient.SegmentInfo(
            type = type,
            line = line,
            direction = direction,
            fromName = fromName,
            toName = toName,
            durationMinutes = durationMinutes,
        )
    }
}
