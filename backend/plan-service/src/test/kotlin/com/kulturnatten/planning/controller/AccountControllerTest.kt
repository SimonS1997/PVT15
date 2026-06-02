package com.kulturnatten.planning.controller

import com.kulturnatten.planning.service.KeycloakAdminClient
import com.kulturnatten.planning.service.UserAlreadyExistsException
import com.kulturnatten.planning.service.UserPreferenceService
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.springframework.http.HttpStatus
import org.springframework.security.oauth2.jwt.Jwt
import kotlin.test.assertEquals

class AccountControllerTest {

    private lateinit var preferences: UserPreferenceService
    private lateinit var keycloak: KeycloakAdminClient
    private lateinit var controller: AccountController

    @BeforeEach
    fun setup() {
        // mocka beroenden så controllern kan testas isolerat
        preferences = mock(UserPreferenceService::class.java)
        keycloak = mock(KeycloakAdminClient::class.java)
        controller = AccountController(preferences, keycloak)
    }

    @Test
    fun `register returnerar 201 när keycloak skapar användaren`() {
        // utan exception från keycloak räknas registreringen som lyckad
        val response = controller.register(RegisterRequest("ny@example.com", "hemligt"))

        assertEquals(HttpStatus.CREATED, response.statusCode)
        // verifiera att keycloak faktiskt anropades med rätt argument
        verify(keycloak).createUser("ny@example.com", "hemligt")
    }

    @Test
    fun `register returnerar 400 när e-post är tom`() {
        // bara mellanslag i email ska stoppas innan vi kontaktar keycloak
        val response = controller.register(RegisterRequest("   ", "hemligt"))

        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
    }

    @Test
    fun `register returnerar 400 när lösenord är tomt`() {
        val response = controller.register(RegisterRequest("ok@example.com", ""))

        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
    }

    @Test
    fun `register returnerar 409 när e-post redan finns`() {
        // simulera att keycloak kastar konflikt eftersom användaren redan finns
        `when`(keycloak.createUser("dubbel@example.com", "lösen"))
            .thenThrow(UserAlreadyExistsException("E-postadressen är redan registrerad."))

        val response = controller.register(RegisterRequest("dubbel@example.com", "lösen"))

        assertEquals(HttpStatus.CONFLICT, response.statusCode)
    }

    @Test
    fun `deleteAccount tar bort både preferenser och keycloak-användare`() {
        // mocka en JWT som returnerar user-id via subject-fältet
        val jwt = mock(Jwt::class.java)
        `when`(jwt.subject).thenReturn("user-123")

        controller.deleteAccount(jwt)

        // båda beroendena ska kallas med samma id från jwt
        verify(preferences).deleteAll("user-123")
        verify(keycloak).deleteUser("user-123")
    }
}
