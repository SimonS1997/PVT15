package com.kulturnatten.events.service

import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.io.File
import java.sql.DriverManager
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EventServiceTest {

    private lateinit var dbFile: File
    private lateinit var service: EventService

    @BeforeEach
    fun setup() {
        dbFile = File.createTempFile("events-test", ".db")
        val dbUrl = "jdbc:sqlite:${dbFile.absolutePath}"

        DriverManager.getConnection(dbUrl).use { connection ->
            connection.createStatement().use { statement ->
                statement.execute(
                    """
                    CREATE TABLE events (
                        id INTEGER PRIMARY KEY,
                        name TEXT,
                        venue TEXT,
                        address TEXT,
                        time_start TEXT,
                        time_end TEXT,
                        district TEXT,
                        description TEXT,
                        booking_required INTEGER,
                        nearest_station TEXT,
                        latitude REAL,
                        longitude REAL,
                        category TEXT
                    )
                    """.trimIndent()
                )

                statement.execute(
                    """
                    INSERT INTO events VALUES
                        (1, 'Museum Night', 'Nationalmuseum', 'Sodra Blasieholmshamnen',
                         '18:00', '22:00', 'City', 'History exhibition', 0,
                         'T-Centralen', 59.32, 18.07, 'HISTORY'),
                        (2, 'Konsert', 'Konserthuset', 'Hotorget 8',
                         '19:00', '21:00', 'City', 'Live music', 1,
                         'Hotorget', 59.33, 18.06, 'MUSIC'),
                        (3, 'Operavisning', 'Operan', 'Gustav Adolfs torg 2',
                         '18:30', '20:00', 'Gamla stan', 'Guided tour', 0,
                         'Kungstradgarden', 59.32, 18.07, 'MUSIC'),
                        (4, 'Event utan koordinater', 'Okand plats', 'Okand adress',
                         '20:00', '21:00', 'City', 'Missing map coordinates', 0,
                         'T-Centralen', NULL, NULL, 'OTHER')
                    """.trimIndent()
                )
            }
        }

        service = EventService(dbUrl)
    }

    @AfterEach
    fun cleanup() {
        dbFile.delete()
    }

    @Test
    fun `getAllEvents without filters returns events with coordinates ordered by name`() {
        val events = service.getAllEvents(category = null, search = null)

        assertEquals(listOf("Konsert", "Museum Night", "Operavisning"), events.map { it.name })
    }

    @Test
    fun `getAllEvents filters by category`() {
        val events = service.getAllEvents(category = "MUSIC", search = null)

        assertEquals(listOf("Konsert", "Operavisning"), events.map { it.name })
        assertTrue(events.all { it.category == "MUSIC" })
    }

    @Test
    fun `getAllEvents treats blank category as no category filter`() {
        val events = service.getAllEvents(category = "   ", search = null)

        assertEquals(3, events.size)
    }

    @Test
    fun `getAllEvents searches by name case insensitively`() {
        val events = service.getAllEvents(category = null, search = "museum")

        assertEquals(listOf("Museum Night"), events.map { it.name })
    }

    @Test
    fun `getAllEvents searches by venue case insensitively`() {
        val events = service.getAllEvents(category = null, search = "OPERAN")

        assertEquals(listOf("Operavisning"), events.map { it.name })
    }

    @Test
    fun `getEvents uses ids when ids are provided and preserves requested order`() {
        val events = service.getEvents(category = "HISTORY", search = "museum", ids = "3,1")

        assertEquals(listOf(3, 1), events.map { it.id })
    }

    @Test
    fun `getEvents ignores invalid and duplicate ids`() {
        val events = service.getEvents(category = null, search = null, ids = "2, bad, 2, 1")

        assertEquals(listOf(2, 1), events.map { it.id })
    }

    @Test
    fun `getEvents returns empty list when ids contain no valid numbers`() {
        val events = service.getEvents(category = null, search = null, ids = "bad, also-bad")

        assertTrue(events.isEmpty())
    }

    @Test
    fun `getById maps database row to response`() {
        val event = service.getById(2)

        requireNotNull(event)
        assertEquals(2, event.id)
        assertEquals("Konsert", event.name)
        assertEquals("Konserthuset", event.venue)
        assertEquals("Hotorget 8", event.address)
        assertEquals("19:00", event.timeStart)
        assertEquals("21:00", event.timeEnd)
        assertEquals("City", event.district)
        assertEquals("Live music", event.description)
        assertTrue(event.bookingRequired)
        assertEquals("Hotorget", event.nearestStation)
        assertEquals(59.33, event.latitude)
        assertEquals(18.06, event.longitude)
        assertEquals("MUSIC", event.category)
    }

    @Test
    fun `getById returns null when event does not exist`() {
        assertNull(service.getById(999))
    }
}
