# Mikrotjänstarkitektur

Kulturnatten-appen är uppdelad i fyra fristående tjänster bakom en gemensam Keycloak-baserad auth. Varje tjänst byggs och deployas separat via `docker-compose.yml` i repo-roten och har sitt eget ansvarsområde.

## Översikt

| Tjänst | Port | Ansvar | Datakälla |
|---|---|---|---|
| kulturnatten-auth (Keycloak) | 8081 | Identitet, inloggning, JWT-utfärdande | Keycloak realm-export |
| event-service | 8082 | Tillhandahålla evenemangsdata | SQLite (`events.db`) |
| transit-service | 8083 | Resvägsplanering via SL | SL API (extern) |
| plan-service | 8084 | Användarens preferenser och planerade besök | SQLite (`plans.db`) |

Frontend (`frontend/`) konsumerar dessa REST-API:er och skickar med JWT från Keycloak i `Authorization`-headern.

## kulturnatten-auth (Keycloak)

**Ansvar**
- Hanterar användarregistrering, inloggning och utloggning.
- Utfärdar och signerar JWT-tokens som de övriga tjänsterna validerar.
- Realm `kulturnatten-dev` importeras automatiskt från `realm-export.json`.

**Gränser**
- Innehåller ingen domänlogik (inga events, planer eller resor).
- Övriga tjänster pratar inte med Keycloak under request-flödet — de validerar bara token-signaturen mot issuern.

**Issuer-URL:** `http://keycloak:8080/realms/kulturnatten-dev` (internt) / `http://localhost:8081/...` (extern).

## event-service

**Ansvar**
- Exponerar evenemangskatalogen (namn, plats, tid, beskrivning, koordinater m.m.).
- Läser från en read-only SQLite-databas (`/data/events.db`) som seedas externt.
- Filtrerar bort events utan koordinater så frontend kan rita kartan utan extra logik.

**Endpoints**
- `GET /api/events` → lista alla geokodade events.

**Gränser**
- Skriver inte data — katalogen är statisk per kulturnatt.
- Vet inget om användare, planer eller resvägar.

## transit-service

**Ansvar**
- Slår upp resor mellan två punkter via SL:s publika API (`SlApiClient`).
- Översätter SL:s svar till appens egna `TransitJourneyResponse`-modeller.

**Endpoints**
- `POST /api/transit/journey` med `{ origin, destination }` → planerad resa.

**Gränser**
- Statslös — ingen egen databas.
- Känner inte till specifika events; den får bara koordinater/adresser från frontend.

## plan-service

**Ansvar**
- Lagrar användarens personliga preferenser (favoritkategorier, sparade event-ID:n, m.m.).
- Egen SQLite-databas (`/data/plans.db`) skild från event-katalogen.

**Endpoints** — alla kräver giltig JWT, alla operationer scope:as till `jwt.subject`:
- `GET /api/preferences/{key}` → preferensens JSON-värde, eller 404.
- `PUT /api/preferences/{key}` med JSON-body → upsert (skapar eller uppdaterar).
- `DELETE /api/preferences/{key}` → 204 om raderad, 404 om okänd.

**Datamodell**

Tabell `user_preferences` (SQLite):

| Kolumn | Typ | Beskrivning |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | surrogatnyckel |
| `user_id` | TEXT NOT NULL | Keycloak `sub` från JWT |
| `pref_key` | TEXT NOT NULL | preferens-nyckel (t.ex. `favorite_categories`) |
| `pref_value` | TEXT NOT NULL | preferens-värde som JSON-sträng (godtycklig struktur) |
| `updated_at` | INTEGER NOT NULL | epoch millis |

- `UNIQUE(user_id, pref_key)` — en rad per (användare, nyckel), upsert via PUT.
- Index på `user_id` för listning.

Schema initieras från `src/main/resources/schema.sql` vid uppstart (`spring.sql.init.mode=always`).

**Designval — varför key/value istället för typade kolumner**
- Frontend kan introducera nya preferenser (t.ex. `theme`, `language`, `notifications`) utan migration.
- `pref_value` lagras som JSON-textsträng, så listor och objekt fungerar utan extra tabeller.
- Kompromiss: ingen schemagaranti på värdets form — frontend äger validering per key.

**Privacy/security**
- `user_id` plockas alltid från JWT-subject; ingen endpoint accepterar `user_id` som parameter.
- En användare kan därmed bara läsa, skriva och radera sina egna preferenser.
- Token-validering sker mot Keycloak-issuern i `SecurityConfig`.

**Gränser**
- Refererar event-ID:n men duplicerar inte event-data; frontend joinar via event-service.
- Ingen resvägslogik — den ligger i transit-service.

## Kommunikationsmönster

- **Frontend → tjänst:** REST/JSON med JWT i `Authorization: Bearer ...`.
- **Tjänst → Keycloak:** endast vid uppstart för att hämta JWK-set (token-validering).
- **Tjänst → tjänst:** ingen direkt kommunikation idag. Frontend orkestrerar (hämtar events, frågar transit, sparar plan).
- **Externa beroenden:** transit-service → SL API.

## Varför uppdelningen

- **Auth isolerad** så att vi kan byta IdP utan att röra domänkoden.
- **Event-katalogen separat** eftersom den är read-only och har en helt annan livscykel (seedas inför varje kulturnatt).
- **Transit fristående** eftersom den bara wrappar ett externt API och kan skalas/cacheas oberoende.
- **Plan separat** eftersom det är den enda skrivande, användarspecifika tjänsten — håller persistensen för användardata åtskild från katalogdata.
