package com.kulturnatten.planning.controller

import com.kulturnatten.planning.service.UserPreferenceService
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import tools.jackson.databind.JsonNode

@RestController
@RequestMapping("/api/preferences")
class UserPreferenceController(
    private val service: UserPreferenceService,
) {

    @GetMapping("/{key}", produces = [MediaType.APPLICATION_JSON_VALUE])
    fun get(
        @PathVariable key: String,
        @AuthenticationPrincipal jwt: Jwt,
    ): ResponseEntity<String> {
        val value = service.get(jwt.subject, key)
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(value)
    }

    @PutMapping("/{key}")
    fun put(
        @PathVariable key: String,
        @RequestBody value: JsonNode,
        @AuthenticationPrincipal jwt: Jwt,
    ) {
        service.upsert(jwt.subject, key, value.toString())
    }

    @DeleteMapping("/{key}")
    fun delete(
        @PathVariable key: String,
        @AuthenticationPrincipal jwt: Jwt,
    ): ResponseEntity<Void> {
        return if (service.delete(jwt.subject, key)) {
            ResponseEntity.noContent().build()
        } else {
            ResponseEntity.notFound().build()
        }
    }
}
