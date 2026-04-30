FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY . .

RUN ./gradlew bootJar --no-daemon

EXPOSE 8083

CMD ["java", "-jar", "build/libs/transit-service-0.0.1-SNAPSHOT.jar"]