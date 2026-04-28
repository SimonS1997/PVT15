package com.kulturnatten.transitservice

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class TransitServiceApplication

fun main(args: Array<String>) {
    runApplication<TransitServiceApplication>(*args)
}
