package com.kulturnatten.planning.controller

import com.kulturnatten.planning.service.KeycloakAdminClient
import com.kulturnatten.planning.service.UserAlreadyExistsException
import com.kulturnatten.planning.service.UserPreferenceService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/account")
class AccountController(
    private val preferences: UserPreferenceService,
    private val keycloak: KeycloakAdminClient,
) {
    @DeleteMapping
    fun deleteAccount(@AuthenticationPrincipal jwt: Jwt) {
        val userId = jwt.subject
        preferences.deleteAll(userId)
        keycloak.deleteUser(userId)
    }

    @PostMapping("/register")
    fun register(@RequestBody body: RegisterRequest): ResponseEntity<Map<String, String>> {
        val email = body.email.trim()
        if (email.isEmpty() || body.password.isEmpty()) {
            return ResponseEntity.badRequest().body(
                mapOf("error" to "E-post och lösenord krävs.")
            )
        }

        return try {
            keycloak.createUser(email, body.password)
            ResponseEntity.status(HttpStatus.CREATED).build()
        } catch (e: UserAlreadyExistsException) {
            ResponseEntity.status(HttpStatus.CONFLICT).body(
                mapOf("error" to (e.message ?: "E-postadressen är redan registrerad."))
            )
        }
    }
}

data class RegisterRequest(val email: String, val password: String)
