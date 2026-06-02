# Mikrotjänstarkitektur

Nattkartan är uppdelad i fyra fristående backend-tjänster bakom en gemensam Keycloak-baserad inloggning. Varje tjänst byggs och körs separat via docker-compose.yml i repo-roten. Frontend (frontend/) pratar med tjänsterna via REST och skickar med JWT från Keycloak i Authorization-headern.

Tjänsterna lyssnar internt på portarna 8081 till 8084. Keycloak, event-service och plan-service mappas också ut externt. Transit-service är i nuläget bara nåbar inifrån dockernätet eftersom den inte har någon ports-mappning i compose, så om frontend ska nå den utifrån behöver det fixas.

## kulturnatten-auth (Keycloak)

Hanterar registrering, inloggning, utloggning och utfärdar de JWT-tokens som övriga tjänster validerar. Realmet kulturnatten-dev importeras automatiskt från realm-export.json vid uppstart.

Tjänsten innehåller ingen domänlogik, inga events, planer eller resor lever här. Issuern är http://localhost:8081/realms/kulturnatten-dev utåt och http://keycloak:8080/... internt i dockernätet.

## event-service

Exponerar evenemangskatalogen för Kulturnatten, alltså namn, plats, tid, beskrivning och koordinater. Datan ligger i en read-only SQLite-fil (/data/events.db) som seedas externt. Tjänsten filtrerar bort events utan koordinater så frontend kan rita ut kartan utan extra logik.

Det går att lista events via GET /api/events. Den tar tre valfria query-parametrar: category och search för filtrering, samt ids för att hämta en specifik mängd events på en gång (används bland annat när "Min plan" ska visa sparade events). Enskilda events hämtas via GET /api/events/{id}, som returnerar 404 om det inte finns.

Tjänsten skriver aldrig data, eftersom katalogen är statisk per kulturnatt. Den vet heller inget om användare, planer eller resvägar.

## transit-service

Slår upp resor mellan punkter via ResRobot (Trafiklab) och kräver en RESROBOT_API_KEY som env-var. Klassen heter SlApiClient av historiska skäl men det är ResRobot-API:t som faktiskt anropas. Svaren översätts till appens egna TransitJourneyResponse-modeller.

Två endpoints finns:

- POST /api/transit/journey med { origin, destination } för en enkel resa mellan två punkter.
- POST /api/transit/legs med en lista stopp, som returnerar resorna mellan varje par. Det är den här "Hinner jag?" använder för att räkna ut hela rundan.

Tjänsten är statslös och har ingen egen databas. Den känner inte till specifika events utan får bara koordinater eller adresser från frontend.

## plan-service

Lagrar användarens personliga preferenser, t.ex. favoritkategorier och sparade event-ID:n. Den hanterar också kontoskapande och kontoradering genom att prata med Keycloaks admin-API. Egen SQLite-databas (/data/plans.db) skild från event-katalogen.

Alla preferens-endpoints kräver giltig JWT och scope:as till jwt.subject, alltså den inloggade användaren:

- GET /api/preferences hämtar alla preferenser.
- GET /api/preferences/{key} hämtar en specifik, eller 404 om den saknas.
- PUT /api/preferences/{key} gör upsert (skapar eller uppdaterar).
- DELETE /api/preferences/{key} raderar en, returnerar 204 eller 404.
- DELETE /api/preferences raderar alla och returnerar antal raderade.

Utöver det finns två konto-endpoints:

- POST /api/account/register skapar en ny användare i Keycloak via admin-API:t. Tar e-post och lösenord, returnerar 409 om mejlen redan finns.
- DELETE /api/account raderar både preferenserna och Keycloak-användaren för den inloggade.

För admin-API:t använder plan-service ett separat service-account-konto i Keycloak, konfigurerat via KEYCLOAK_BASE_URL, KEYCLOAK_REALM, KEYCLOAK_ADMIN_CLIENT_ID och KEYCLOAK_ADMIN_CLIENT_SECRET.

Datan ligger i tabellen user_preferences med en surrogatnyckel id, ett user_id (Keycloaks sub från JWT), en pref_key, ett pref_value (JSON-sträng) och updated_at i epoch millis. Det finns en UNIQUE(user_id, pref_key) så att PUT kan göra upsert, plus ett index på user_id för listning. Schemat initieras från src/main/resources/schema.sql vid uppstart via spring.sql.init.mode=always.

Valet att lagra preferenser som key/value istället för typade kolumner gjordes för att frontend ska kunna introducera nya preferenser (t.ex. theme, language, notifications) utan att vi behöver köra en migration varje gång. pref_value är en JSON-textsträng, så listor och objekt funkar direkt utan extra tabeller. Kompromissen är att backend inte garanterar formen på värdet, det ansvaret ligger på frontend per key.

På säkerhetssidan plockas user_id alltid från JWT-subject. Ingen preferens-endpoint accepterar user_id som parameter, så en användare kan bara läsa, skriva och radera sina egna preferenser. Token-validering sker mot Keycloak-issuern i SecurityConfig. Tjänsten refererar event-ID:n men duplicerar inte event-data, frontend joinar mot event-service själv. Resvägslogiken hör hemma i transit-service.

## Hur tjänsterna pratar med varandra

Frontend pratar med varje tjänst direkt via REST och JWT, och det är frontend som orkestrerar flödet (hämtar events, frågar transit, sparar i plan). Tjänsterna anropar inte varandra.

Mot Keycloak finns det två sorters trafik: alla tjänster hämtar JWK-set vid uppstart för att kunna validera tokens, och plan-service anropar dessutom Keycloaks admin-API runtime vid registrering och kontoradering. Den enda externa integrationen i övrigt är transit-service mot ResRobot.

## Varför uppdelningen ser ut så här

Auth är utbruten så att vi kan byta IdP utan att röra domänkoden. Event-katalogen ligger för sig eftersom den är read-only och har en helt annan livscykel, den seedas inför varje kulturnatt och uppdateras sällan däremellan. Transit är fristående eftersom den bara wrappar ett externt API och kan skalas eller cacheas oberoende. Plan ligger för sig eftersom det är den enda skrivande, användarspecifika tjänsten, och då vill vi hålla persistensen för användardata åtskild från katalogdatan.
