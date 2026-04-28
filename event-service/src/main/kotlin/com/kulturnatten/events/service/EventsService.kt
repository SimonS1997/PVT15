package com.kulturnatten.events.service

import com.kulturnatten.events.model.EventResponse
import org.springframework.stereotype.Service
import java.sql.DriverManager

@Service
class EventService {

    private val dbUrl = "jdbc:sqlite:../data/events.db"

    fun getAllEvents(): List<EventResponse> {
        DriverManager.getConnection(dbUrl).use { connection ->
            val statement = connection.prepareStatement(
                """
                SELECT id, name, venue, address, time_start, time_end, district,
                       description, booking_required, nearest_station, latitude, longitude
                FROM events
                WHERE latitude IS NOT NULL AND longitude IS NOT NULL
                ORDER BY name
                """.trimIndent()
            )

            val resultSet = statement.executeQuery()
            val events = mutableListOf<EventResponse>()

            while (resultSet.next()) {
                events.add(
                    EventResponse(
                        id = resultSet.getInt("id"),
                        name = resultSet.getString("name"),
                        venue = resultSet.getString("venue"),
                        address = resultSet.getString("address"),
                        timeStart = resultSet.getString("time_start"),
                        timeEnd = resultSet.getString("time_end"),
                        district = resultSet.getString("district"),
                        description = resultSet.getString("description"),
                        bookingRequired = resultSet.getInt("booking_required") == 1,
                        nearestStation = resultSet.getString("nearest_station"),
                        latitude = resultSet.getDouble("latitude"),
                        longitude = resultSet.getDouble("longitude")
                    )
                )
            }

            resultSet.close()
            statement.close()

            return events
        }
    }
}