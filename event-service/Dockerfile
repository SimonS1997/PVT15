FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY . .

RUN ./gradlew bootJar --no-daemon

EXPOSE 8082

CMD ["java", "-jar", "build/libs/event-service-0.0.1-SNAPSHOT.jar"]