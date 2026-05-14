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

        DriverManager.getConnection(dbUrl).use { conn ->
            conn.createStatement().execute(
                """
                CREATE TABLE events (
                    id INTEGER PRIMARY KEY,
                    name TEXT, venue TEXT, address TEXT,
                    time_start TEXT, time_end TEXT, district TEXT,
                    description TEXT, booking_required BOOLEAN,
                    nearest_station TEXT, latitude REAL, longitude REAL,
                    category TEXT
                )
                """.trimIndent()
            )
            conn.createStatement().execute(
                """
                INSERT INTO events VALUES
                    (1, 'Museum Night', 'Nationalmuseum', 'Södra Blasieholmshamnen',
                     '18:00','22:00','City','desc',0,'T-Centralen', 59.32, 18.07,'HISTORY'),
                    (2, 'Konsert', 'Konserthuset', 'Hötorget 8',
                     '19:00','21:00','City','desc',0,'Hötorget', 59.33, 18.06,'MUSIC'),
                    (3, 'Operavisning', 'Operan', 'Gustav Adolfs torg 2',
                     '18:30','20:00','Gamla stan','desc',0,'Kungsträdgården', 59.32, 18.07,'MUSIC')
                """.trimIndent()
            )
        }

        service = EventService(dbUrl)
    }

    @AfterEach
    fun cleanup() {
        dbFile.delete()
    }

    @Test
    fun `getAllEvents utan filter ger alla event`() {
        val events = service.getAllEvents(null, null)
        assertEquals(3, events.size)
    }

    @Test
    fun `getAllEvents filtrerar pa kategori`() {
        val events = service.getAllEvents("MUSIC", null)
        assertEquals(2, events.size)
        assertTrue(events.all { it.category == "MUSIC" })
    }

    @Test
    fun `getAllEvents soker pa namn`() {
        val events = service.getAllEvents(null, "museum")
        assertEquals(1, events.size)
        assertEquals("Museum Night", events[0].name)
    }

    @Test
    fun `getById ger null nar event saknas`() {
        assertNull(service.getById(999))
    }
}
