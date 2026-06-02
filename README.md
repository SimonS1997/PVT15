# Nattkartan

Mobilapp för Nattkartan i Stockholm där användaren kan bläddra bland evenemang, spara favoriter, planera sitt besök och se resvägar mellan eventen.

Projektet består av en Flutter-app och fyra backend-tjänster: Keycloak för inloggning, en event-tjänst för evenemangskatalogen, en plan-tjänst för användarnas sparade event och preferenser, samt en transit-tjänst som hämtar resvägar från SL/ResRobot. Allt körs via Docker Compose. Mer om hur tjänsterna hänger ihop finns i docs/microservices.md.

## Vad du behöver

Du behöver Docker (vi har testat med Docker Desktop), Flutter SDK 3.10 eller senare, samt en Android-emulator för att köra appen. Vill du bygga backenden lokalt utan Docker behövs JDK 21.

Transit-tjänsten använder SL/ResRobot, så du behöver en gratis API-nyckel från trafiklab.se.

## Konfiguration

Skapa en .env i repo-roten med två variabler:


RESROBOT_API_KEY=
KEYCLOAK_ADMIN_CLIENT_SECRET=


RESROBOT_API_KEY hämtar du från trafiklab. KEYCLOAK_ADMIN_CLIENT_SECRET får du från Keycloak-admin första gången du startar projektet, gå in på klienten plan-service-admin under Credentials och kopiera secret:en, lägg in i .env och starta om Compose.

För frontenden kopierar du mallen:


cp frontend/env/auth.example.json frontend/env/auth.local.json


Default-värdena i exemplet fungerar mot den lokala Keycloak-instansen. Variablerna som läses är AUTH_CLIENT_ID, AUTH_REDIRECT_URI, AUTH_ISSUER_URL och AUTH_SCOPES.

## Köra projektet

Starta backend från repo-roten:


docker compose up --build


Det startar Keycloak på port 8081, event-service på 8082, transit-service på 8083 och plan-service på 8084. Keycloak importerar realmen från backend/kulturnatten-auth/realm-export.json vid första uppstart, och admin-konsolen nås på http://localhost:8081.

Starta sedan frontend i en separat terminal med Android-emulatorn igång:


cd frontend
flutter pub get
flutter run --dart-define-from-file=env/auth.local.json


URL:erna i appen pekar på 10.0.2.2 vilket är hostmaskinen sett från emulatorn.

## Köra tester

Backend har enhetstester per tjänst. Kör dem med:


cd backend/event-service && ./gradlew test
cd backend/plan-service && ./gradlew test
cd backend/transit-service && ./gradlew test


Frontend-tester körs med flutter test från frontend/.

## Projektstruktur

backend/ innehåller de tre Spring Boot-tjänsterna och Keycloak-konfigurationen. frontend/ är Flutter-appen. data/ innehåller SQLite-databaserna som mountas in i event- och plan-service. docs/ har arkitekturdokumentation. docker-compose.yml orkestrerar backenden.

## Om något inte funkar

Om Keycloak inte importerar realmen, kör docker compose down och starta om importen körs bara vid första uppstart. Om transit-service svarar med 500, kontrollera att RESROBOT_API_KEY är satt. Om appen visar ett meddelande om att AUTH_CLIENT_ID saknas så har auth.local.json inte skickats med via --dart-define-from-file.
