## Keycloak

Local Keycloak for development. The realm `kulturnatten-dev` is auto-imported on first boot from `realm-export.json` — no manual setup required.

### Start

```bash
docker compose -f kulturnatten-auth/docker-compose.yml up -d
```

Available at `http://localhost:8081` (Android emulator: `http://10.0.2.2:8081`).

Issuer URL: `http://localhost:8081/realms/kulturnatten-dev`

### Test user (fixture)

| username | password |
|----------|----------|
| `testuser` | `test123` |

### Admin console

`http://localhost:8081` → admin / admin123

### Reset

The container has no volume — `docker compose down` discards all runtime data and the next `up` re-imports the realm from `realm-export.json`.
