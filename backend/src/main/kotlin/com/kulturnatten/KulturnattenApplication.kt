package com.kulturnatten

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class KulturnattenApplication

fun main(args: Array<String>) {
    runApplication<KulturnattenApplication>(*args)
}