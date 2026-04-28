package com.kulturnatten

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.mock.mockito.MockBean
import org.springframework.security.oauth2.jwt.JwtDecoder
import org.springframework.test.context.TestPropertySource
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(
    properties = [
        "AUTH_ISSUER_URI=https://issuer.example.com/realms/kulturnatten-dev",
    ],
)
class ApiSecurityTests {
    @Autowired
    lateinit var mockMvc: MockMvc

    @MockBean
    lateinit var jwtDecoder: JwtDecoder

    @Test
    fun `health is public`() {
        mockMvc.get("/health")
            .andExpect {
                status { isOk() }
                jsonPath("$.status") { value("ok") }
            }
    }

    @Test
    fun `me returns 401 without token`() {
        mockMvc.get("/me")
            .andExpect {
                status { isUnauthorized() }
            }
    }

    @Test
    fun `me returns 200 with token`() {
        mockMvc.get("/me") {
            with(
                jwt().jwt {
                    it.subject("user-123")
                    it.claim("name", "Kulturnatten User")
                    it.claim("preferred_username", "user@example.com")
                    it.issuer("https://issuer.example.com/realms/kulturnatten-dev")
                },
            )
        }.andExpect {
            status { isOk() }
            jsonPath("$.sub") { value("user-123") }
            jsonPath("$.name") { value("Kulturnatten User") }
        }
    }
}
