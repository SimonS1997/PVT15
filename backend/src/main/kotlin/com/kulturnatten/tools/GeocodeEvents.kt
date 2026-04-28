package com.kulturnatten.tools

import com.fasterxml.jackson.databind.ObjectMapper
import java.net.URI
import java.net.URLEncoder
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.nio.charset.StandardCharsets
import java.sql.DriverManager

fun main() {
    val apiKey = System.getenv("GOOGLE_GEOCODING_API_KEY")
        ?: error("GOOGLE_GEOCODING_API_KEY saknas")

    val dbUrl = "jdbc:sqlite:backend/src/main/resources/database/events.db"

    val client = HttpClient.newHttpClient()
    val mapper = ObjectMapper()

    DriverManager.getConnection(dbUrl).use { connection ->
        val selectStatement = connection.prepareStatement(
            """
            SELECT id, venue, address, nearest_station
            FROM events
            WHERE latitude IS NULL OR longitude IS NULL
            """.trimIndent()
        )

        val updateStatement = connection.prepareStatement(
            """
            UPDATE events
            SET latitude = ?, longitude = ?
            WHERE id = ?
            """.trimIndent()
        )

        val resultSet = selectStatement.executeQuery()

        while (resultSet.next()) {
            val id = resultSet.getInt("id")
            val venue = resultSet.getString("venue")
            val address = resultSet.getString("address")
            val nearestStation = resultSet.getString("nearest_station")

            val searchQuery = when {
                !venue.isNullOrBlank() && !address.isNullOrBlank() ->
                    "$venue, $address, Stockholm, Sweden"

                !address.isNullOrBlank() ->
                    "$address, Stockholm, Sweden"

                !nearestStation.isNullOrBlank() ->
                    "$nearestStation, Stockholm, Sweden"

                else -> {
                    println("Skipping id=$id: saknar venue, address och nearest_station")
                    continue
                }
            }

            println("Geocoding id=$id -> $searchQuery")

            val coordinates = geocode(searchQuery, apiKey, client, mapper)

            if (coordinates != null) {
                updateStatement.setDouble(1, coordinates.latitude)
                updateStatement.setDouble(2, coordinates.longitude)
                updateStatement.setInt(3, id)
                updateStatement.executeUpdate()

                println("Saved id=$id: ${coordinates.latitude}, ${coordinates.longitude}")
            } else {
                println("No result for id=$id")
            }

            Thread.sleep(120)
        }

        resultSet.close()
        selectStatement.close()
        updateStatement.close()
    }

    println("DONE")
}

data class Coordinates(
    val latitude: Double,
    val longitude: Double
)

fun geocode(
    query: String,
    apiKey: String,
    client: HttpClient,
    mapper: ObjectMapper
): Coordinates? {
    val encodedQuery = URLEncoder.encode(query, StandardCharsets.UTF_8)

    val url = "https://maps.googleapis.com/maps/api/geocode/json" +
            "?address=$encodedQuery" +
            "&key=$apiKey"

    val request = HttpRequest.newBuilder()
        .uri(URI.create(url))
        .GET()
        .build()

    val response = client.send(request, HttpResponse.BodyHandlers.ofString())

    if (response.statusCode() != 200) {
        println("HTTP error: ${response.statusCode()}")
        return null
    }

    val json = mapper.readTree(response.body())
    val status = json["status"]?.asText()

    if (status != "OK") {
        println("Google status: $status")
        return null
    }

    val location = json["results"]
        ?.get(0)
        ?.get("geometry")
        ?.get("location")
        ?: return null

    return Coordinates(
        latitude = location["lat"].asDouble(),
        longitude = location["lng"].asDouble()
    )
}