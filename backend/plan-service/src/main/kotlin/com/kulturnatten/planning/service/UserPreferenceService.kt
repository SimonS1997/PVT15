package com.kulturnatten.planning.service

import com.kulturnatten.planning.model.UserPreference
import com.kulturnatten.planning.repository.UserPreferenceRepository
import org.springframework.stereotype.Service
import java.time.Instant

@Service
class UserPreferenceService(
    private val repository: UserPreferenceRepository,
) {

    fun get(userId: String, key: String): String? {
        return repository.findByUserIdAndKey(userId, key)?.value
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
}
