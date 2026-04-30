package com.kulturnatten.transit.config

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import java.net.http.HttpClient

@Configuration
class TransitConfig {

    @Bean
    fun httpClient(): HttpClient = HttpClient.newHttpClient()

    @Bean
    fun objectMapper(): ObjectMapper = jacksonObjectMapper()
}