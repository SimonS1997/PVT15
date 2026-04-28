package com.kulturnatten.transit.client

import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import com.kulturnatten.transit.model.TransitJourneyResponse
import com.kulturnatten.transit.model.TransitLegResponse
import com.kulturnatten.transit.model.TransitTripResponse
import org.springframework.stereotype.Component
import java.net.URI
import java.net.URLEncoder
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.nio.charset.StandardCharsets

@Component
class SlApiClient(
    private val httpClient: HttpClient,
    private val objectMapper: ObjectMapper
) {
    private val apiKey: String?
        get() = System.getenv("RESROBOT_API_KEY")?.takeIf { it.isNotBlank() }

    fun planJourney(originName: String, destinationName: String): TransitJourneyResponse {
        val requiredApiKey = requireApiKey()
        val originId = findStopExtId(originName)
        val destinationId = findStopExtId(destinationName)

        val url = "https://api.resrobot.se/v2.1/trip" +
                "?format=json" +
                "&originId=$originId" +
                "&destId=$destinationId" +
                "&numF=3" +
                "&accessId=$requiredApiKey"

        val request = HttpRequest.newBuilder()
            .uri(URI.create(url))
            .GET()
            .build()

        val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())

        if (response.statusCode() != 200) {
            error("ResRobot trip-anrop misslyckades. Statuskod: ${response.statusCode()}, body: ${response.body()}")
        }

        val root = objectMapper.readTree(response.body())
        val tripsNode = root.get("Trip")

        if (tripsNode == null || !tripsNode.isArray || tripsNode.isEmpty) {
            return TransitJourneyResponse(
                origin = originName,
                destination = destinationName,
                trips = emptyList()
            )
        }

        val trips = tripsNode.map { tripNode ->
            val duration = tripNode.get("duration")?.asText() ?: "okänd restid"
            val legNode = tripNode.get("LegList")?.get("Leg")

            val legs = when {
                legNode == null -> emptyList()
                legNode.isArray -> legNode.map { mapLeg(it) }
                else -> listOf(mapLeg(legNode))
            }

            TransitTripResponse(
                duration = duration,
                legs = legs
            )
        }

        return TransitJourneyResponse(
            origin = originName,
            destination = destinationName,
            trips = trips
        )
    }

    private fun findStopExtId(stopName: String): String {
        val requiredApiKey = requireApiKey()
        val encodedStopName = URLEncoder.encode(stopName, StandardCharsets.UTF_8)

        val url = "https://api.resrobot.se/v2.1/location.name" +
                "?input=$encodedStopName" +
                "&format=json" +
                "&type=S" +
                "&accessId=$requiredApiKey"

        val request = HttpRequest.newBuilder()
            .uri(URI.create(url))
            .GET()
            .build()

        val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())

        if (response.statusCode() != 200) {
            error("Stop lookup misslyckades för $stopName. Statuskod: ${response.statusCode()}")
        }

        val root = objectMapper.readTree(response.body())
        val results = root.get("stopLocationOrCoordLocation")
            ?: error("Svaret saknar stopLocationOrCoordLocation för $stopName")

        for (item in results) {
            val stop = item.get("StopLocation")
            if (stop != null) {
                val extId = stop.get("extId")?.asText()
                if (!extId.isNullOrBlank()) {
                    return extId
                }
            }
        }

        error("Kunde inte hitta extId för $stopName")
    }

    private fun mapLeg(leg: JsonNode): TransitLegResponse {
        val origin = leg.get("Origin")
        val destination = leg.get("Destination")

        val originName = origin?.get("name")?.asText() ?: "okänd origin"
        val destinationName = destination?.get("name")?.asText() ?: "okänd destination"

        val departureDate = origin?.get("date")?.asText() ?: ""
        val departureTime = origin?.get("time")?.asText() ?: ""
        val arrivalDate = destination?.get("date")?.asText() ?: ""
        val arrivalTime = destination?.get("time")?.asText() ?: ""

        val type = leg.get("type")?.asText() ?: "okänd typ"
        val direction = leg.get("direction")?.asText()
        val line = leg.get("Product")?.get("num")?.asText()
            ?: leg.get("name")?.asText()

        return TransitLegResponse(
            type = type,
            line = line,
            direction = direction,
            originName = originName,
            destinationName = destinationName,
            departureTime = "$departureDate $departureTime".trim(),
            arrivalTime = "$arrivalDate $arrivalTime".trim()
        )
    }

    private fun requireApiKey(): String =
        apiKey ?: error("RESROBOT_API_KEY saknas som environment variable")
}
