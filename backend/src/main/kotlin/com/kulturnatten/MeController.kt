package com.kulturnatten

import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

@RestController
class MeController {
    @GetMapping("/me")
    fun me(@AuthenticationPrincipal jwt: Jwt): Map<String, Any?> =
        mapOf(
            "sub" to jwt.subject,
            "name" to jwt.getClaimAsString("name"),
            "preferred_username" to jwt.getClaimAsString("preferred_username"),
        )
}
