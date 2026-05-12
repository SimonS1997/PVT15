package com.kulturnatten.planning.repository

import com.kulturnatten.planning.model.UserPreference
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.transaction.annotation.Transactional

interface UserPreferenceRepository : JpaRepository<UserPreference, Long> {
    fun findAllByUserId(userId: String): List<UserPreference>
    fun findByUserIdAndKey(userId: String, key: String): UserPreference?

    @Transactional
    fun deleteByUserIdAndKey(userId: String, key: String): Long

    @Transactional
    fun deleteAllByUserId(userId: String): Long
}
