package com.kulturnatten.planning.service

import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Component
import tools.jackson.databind.ObjectMapper
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse

@Component
class KeycloakAdminClient(
    @Value("\${KEYCLOAK_BASE_URL}")
    private val baseUrl: String,
    @Value("\${KEYCLOAK_REALM}")
    private val realm: String,
    @Value("\${KEYCLOAK_ADMIN_CLIENT_ID}")
    private val clientId: String,
    @Value("\${KEYCLOAK_ADMIN_CLIENT_SECRET}")
    private val clientSecret: String,
    private val objectMapper: ObjectMapper,
) {
    private val http = HttpClient.newHttpClient()

    fun createUser(email: String, password: String) {
        val token = fetchAdminToken()

        val payload = objectMapper.writeValueAsString(
            mapOf(
                "username" to email,
                "email" to email,
                "enabled" to true,
                "emailVerified" to true,
                "firstName" to email,
                "lastName" to "-",
                "requiredActions" to emptyList<String>(),
                "credentials" to listOf(
                    mapOf(
                        "type" to "password",
                        "value" to password,
                        "temporary" to false,
                    )
                ),
            )
        )

        val request = HttpRequest.newBuilder()
            .uri(URI.create("$baseUrl/admin/realms/$realm/users"))
            .header("Authorization", "Bearer $token")
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(payload))
            .build()
        val response = http.send(request, HttpResponse.BodyHandlers.ofString())

        when (response.statusCode()) {
            201 -> return
            409 -> throw UserAlreadyExistsException("E-postadressen är redan registrerad.")
            else -> throw RuntimeException(
                "Kunde inte skapa Keycloak-användare: ${response.statusCode()} ${response.body()}"
            )
        }
    }

    fun deleteUser(userId: String) {
        val token = fetchAdminToken()
        val request = HttpRequest.newBuilder()
            .uri(URI.create("$baseUrl/admin/realms/$realm/users/$userId"))
            .header("Authorization", "Bearer $token")
            .DELETE()
            .build()
        val response = http.send(request, HttpResponse.BodyHandlers.ofString())

        // 204 = raderad, 404 = redan borta (idempotent)
        if (response.statusCode() != 204 && response.statusCode() != 404) {
            throw RuntimeException(
                "Kunde inte radera Keycloak-användare: ${response.statusCode()} ${response.body()}"
            )
        }
    }

    private fun fetchAdminToken(): String {
        val body = "grant_type=client_credentials" +
            "&client_id=$clientId" +
            "&client_secret=$clientSecret"

        val request = HttpRequest.newBuilder()
            .uri(URI.create("$baseUrl/realms/$realm/protocol/openid-connect/token"))
            .header("Content-Type", "application/x-www-form-urlencoded")
            .POST(HttpRequest.BodyPublishers.ofString(body))
            .build()
        val response = http.send(request, HttpResponse.BodyHandlers.ofString())

        if (response.statusCode() != 200) {
            throw RuntimeException(
                "Kunde inte hämta admin-token: ${response.statusCode()} ${response.body()}"
            )
        }
        return objectMapper.readTree(response.body()).get("access_token").asString()
    }
}

class UserAlreadyExistsException(message: String) : RuntimeException(message)
