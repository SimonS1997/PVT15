package com.kulturnatten.planning.model

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint

@Entity
@Table(
    name = "user_preferences",
    uniqueConstraints = [UniqueConstraint(columnNames = ["user_id", "pref_key"])]
)
class UserPreference(

    @Column(name = "user_id", nullable = false)
    val userId: String,

    @Column(name = "pref_key", nullable = false)
    val key: String,

    @Column(name = "pref_value", nullable = false)
    var value: String,

    @Column(name = "updated_at", nullable = false)
    var updatedAt: Long,

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,
)
