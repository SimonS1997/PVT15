package com.kulturnatten.transit.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import java.net.http.HttpClient

@Configuration
class TransitConfig {

    @Bean
    fun httpClient(): HttpClient = HttpClient.newHttpClient()
}