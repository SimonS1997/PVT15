package com.kulturnatten.events.service

import com.kulturnatten.events.model.EventResponse
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.sql.DriverManager
import java.sql.ResultSet

@Service
class EventService(

    @Value("\${spring.datasource.url}")
    private val dbUrl: String

) {

    fun getEvents(category: String?, search: String?, ids: String?): List<EventResponse> {
        if (!ids.isNullOrBlank()) {
            val eventIds = ids
                .split(",")
                .mapNotNull { it.trim().toIntOrNull() }
                .distinct()

            return getByIds(eventIds)
        }

        return getAllEvents(category, search)
    }

    fun getAllEvents(category: String?, search: String?): List<EventResponse> {
        val sql = StringBuilder(
            """
            SELECT id, name, venue, address, time_start, time_end, district,
                   description, booking_required, nearest_station, latitude, longitude, category
            FROM events
            WHERE latitude IS NOT NULL AND longitude IS NOT NULL
            """.trimIndent()
        )

        val params = mutableListOf<String>()

        if (!category.isNullOrBlank()) {
            sql.append(" AND category = ?")
            params.add(category)
        }

        if (!search.isNullOrBlank()) {
            sql.append(" AND (LOWER(name) LIKE ? OR LOWER(venue) LIKE ?)")
            val term = "%${search.lowercase()}%"
            params.add(term)
            params.add(term)
        }

        sql.append(" ORDER BY name")

        DriverManager.getConnection(dbUrl).use { connection ->
            val statement = connection.prepareStatement(sql.toString())
            params.forEachIndexed { i, value ->
                statement.setString(i + 1, value)
            }

            val resultSet = statement.executeQuery()
            val events = mutableListOf<EventResponse>()

            while (resultSet.next()) {
                events.add(mapRow(resultSet))
            }

            resultSet.close()
            statement.close()

            return events
        }
    }

    fun getByIds(ids: List<Int>): List<EventResponse> {
        if (ids.isEmpty()) return emptyList()

        val placeholders = ids.joinToString(",") { "?" }
        DriverManager.getConnection(dbUrl).use { connection ->
            val statement = connection.prepareStatement(
                """
                SELECT id, name, venue, address, time_start, time_end, district,
                       description, booking_required, nearest_station, latitude, longitude, category
                FROM events
                WHERE id IN ($placeholders)
                """.trimIndent()
            )
            ids.forEachIndexed { index, id ->
                statement.setInt(index + 1, id)
            }

            val resultSet = statement.executeQuery()
            val eventsById = mutableMapOf<Int, EventResponse>()

            while (resultSet.next()) {
                val event = mapRow(resultSet)
                eventsById[event.id] = event
            }

            resultSet.close()
            statement.close()

            return ids.mapNotNull { eventsById[it] }
        }
    }

    fun getById(id: Int): EventResponse? {
        DriverManager.getConnection(dbUrl).use { connection ->
            val statement = connection.prepareStatement(
                """
                SELECT id, name, venue, address, time_start, time_end, district,
                       description, booking_required, nearest_station, latitude, longitude, category
                FROM events
                WHERE id = ?
                """.trimIndent()
            )
            statement.setInt(1, id)

            val resultSet = statement.executeQuery()
            val event = if (resultSet.next()) mapRow(resultSet) else null

            resultSet.close()
            statement.close()

            return event
        }
    }

    private fun mapRow(rs: ResultSet): EventResponse {
        return EventResponse(
            id = rs.getInt("id"),
            name = rs.getString("name"),
            venue = rs.getString("venue"),
            address = rs.getString("address"),
            timeStart = rs.getString("time_start"),
            timeEnd = rs.getString("time_end"),
            district = rs.getString("district"),
            description = rs.getString("description"),
            bookingRequired = rs.getInt("booking_required") == 1,
            nearestStation = rs.getString("nearest_station"),
            latitude = rs.getDouble("latitude"),
            longitude = rs.getDouble("longitude"),
            category = rs.getString("category")
        )
    }
}
