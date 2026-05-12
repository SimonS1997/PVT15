package com.kulturnatten.planning.service

import com.kulturnatten.planning.model.UserPreference
import com.kulturnatten.planning.repository.UserPreferenceRepository
import org.springframework.stereotype.Service
import tools.jackson.databind.JsonNode
import tools.jackson.databind.ObjectMapper
import java.time.Instant

@Service
class UserPreferenceService(
    private val repository: UserPreferenceRepository,
    private val objectMapper: ObjectMapper,
) {

    fun get(userId: String, key: String): String? {
        return repository.findByUserIdAndKey(userId, key)?.value
    }

    fun getAll(userId: String): Map<String, JsonNode> {
        return repository.findAllByUserId(userId)
            .associate { it.key to objectMapper.readTree(it.value) }
    }

    fun upsert(userId: String, key: String, value: String) {
        val now = Instant.now().toEpochMilli()
        val existing = repository.findByUserIdAndKey(userId, key)
        if (existing != null) {
            existing.value = value
            existing.updatedAt = now
            repository.save(existing)
        } else {
            repository.save(UserPreference(userId, key, value, now))
        }
    }

    fun delete(userId: String, key: String): Boolean {
        return repository.deleteByUserIdAndKey(userId, key) > 0
    }

    fun deleteAll(userId: String): Int {
        return repository.deleteAllByUserId(userId).toInt()
    }
}
