package com.kulturnatten.planning.service

import com.kulturnatten.planning.model.UserPreference
import com.kulturnatten.planning.repository.UserPreferenceRepository
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.ArgumentCaptor
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.mockito.Mockito.verifyNoMoreInteractions
import org.mockito.Mockito.`when`
import tools.jackson.databind.ObjectMapper
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class UserPreferenceServiceTest {

    private lateinit var repository: UserPreferenceRepository
    private lateinit var service: UserPreferenceService

    @BeforeEach
    fun setup() {
        repository = mock(UserPreferenceRepository::class.java)
        service = UserPreferenceService(repository, ObjectMapper())
    }

    @Test
    fun `get returns stored preference value`() {
        `when`(repository.findByUserIdAndKey("user-1", "saved_events"))
            .thenReturn(preference(value = "[1,2,3]"))

        val value = service.get("user-1", "saved_events")

        assertEquals("[1,2,3]", value)
    }

    @Test
    fun `get returns null when preference is missing`() {
        `when`(repository.findByUserIdAndKey("user-1", "missing"))
            .thenReturn(null)

        val value = service.get("user-1", "missing")

        assertEquals(null, value)
    }

    @Test
    fun `getAll returns preferences parsed as json nodes`() {
        `when`(repository.findAllByUserId("user-1"))
            .thenReturn(
                listOf(
                    preference(key = "saved_events", value = "[3,1]"),
                    preference(key = "settings", value = """{"sort":"time"}"""),
                )
            )

        val preferences = service.getAll("user-1")

        assertEquals(2, preferences.size)
        assertEquals(3, preferences.getValue("saved_events")[0].asInt())
        assertEquals(1, preferences.getValue("saved_events")[1].asInt())
        assertEquals("time", preferences.getValue("settings")["sort"].asString())
    }

    @Test
    fun `upsert creates new preference when key does not exist`() {
        `when`(repository.findByUserIdAndKey("user-1", "saved_events"))
            .thenReturn(null)
        val captor = ArgumentCaptor.forClass(UserPreference::class.java)

        service.upsert("user-1", "saved_events", "[5]")

        verify(repository).save(captor.capture())
        val saved = captor.value
        assertEquals("user-1", saved.userId)
        assertEquals("saved_events", saved.key)
        assertEquals("[5]", saved.value)
        assertNotNull(saved.updatedAt)
        assertTrue(saved.updatedAt > 0)
    }

    @Test
    fun `upsert updates existing preference when key exists`() {
        val existing = preference(value = "[1]")
        val originalUpdatedAt = existing.updatedAt
        `when`(repository.findByUserIdAndKey("user-1", "saved_events"))
            .thenReturn(existing)

        service.upsert("user-1", "saved_events", "[1,2]")

        assertEquals("[1,2]", existing.value)
        assertTrue(existing.updatedAt >= originalUpdatedAt)
        verify(repository).save(existing)
    }

    @Test
    fun `delete returns true when repository deletes a row`() {
        `when`(repository.deleteByUserIdAndKey("user-1", "saved_events"))
            .thenReturn(1)

        val deleted = service.delete("user-1", "saved_events")

        assertTrue(deleted)
    }

    @Test
    fun `delete returns false when repository deletes no rows`() {
        `when`(repository.deleteByUserIdAndKey("user-1", "missing"))
            .thenReturn(0)

        val deleted = service.delete("user-1", "missing")

        assertFalse(deleted)
    }

    @Test
    fun `deleteAll returns deleted row count as int`() {
        `when`(repository.deleteAllByUserId("user-1"))
            .thenReturn(3)

        val deleted = service.deleteAll("user-1")

        assertEquals(3, deleted)
    }

    @Test
    fun `getEvents operations only touch the requested user and key`() {
        `when`(repository.findByUserIdAndKey("user-1", "saved_events"))
            .thenReturn(preference(userId = "user-1", key = "saved_events", value = "[1]"))

        val value = service.get("user-1", "saved_events")

        assertEquals("[1]", value)
        verify(repository).findByUserIdAndKey("user-1", "saved_events")
        verifyNoMoreInteractions(repository)
    }

    private fun preference(
        userId: String = "user-1",
        key: String = "saved_events",
        value: String = "[]",
        updatedAt: Long = 1000L,
    ): UserPreference {
        return UserPreference(
            userId = userId,
            key = key,
            value = value,
            updatedAt = updatedAt,
        )
    }
}
