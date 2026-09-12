# BuyMe Auction System

A JSP/Servlet auction site (Java 21, Tomcat 9, MySQL 8) — proxy/auto-bidding,
three user roles (end user, customer rep, admin), scheduled auction closing.
See [ARCHITECTURE.md](ARCHITECTURE.md) for how it's put together.

## Setup

Prerequisites: JDK 21, Maven, and either a local MySQL 8 or Docker.

**Database** — either:

- Local MySQL: create a database and import the dump:
  ```
  mysql -u root -p -e "CREATE DATABASE buyme"
  mysql -u root -p buyme < buy_me_db.sql
  ```
- Or Docker (no local MySQL needed):
  ```
  docker compose up -d
  ```
  This seeds a `buyme` database from `buy_me_db.sql` automatically on first
  start.

**Environment variables** — `DatabaseConnection` reads these, with the shown
defaults if unset:

| Variable | Default |
|---|---|
| `DB_URL` | `jdbc:mysql://localhost:3306/buyme?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true` |
| `DB_USER` | `root` |
| `DB_PASSWORD` | *(empty)* |

Set `DB_PASSWORD` (and `DB_URL`/`DB_USER` if needed) to match your MySQL setup
before running the app or the test suite — nothing is hardcoded in source.

**Build and run**:

```
mvn compile          # compile only
mvn package           # build target/Buy_Me.war, deploy it to Tomcat 9
```

## Tests

```
mvn test              # unit tests only — no database needed
mvn verify            # unit + integration tests — needs a reachable schema
```

Integration tests (`*IT.java`) default to a separate `buyme_test` database (not
`buyme`) so they never touch real data:

```
mysql -u root -p -e "CREATE DATABASE buyme_test"
mysql -u root -p buyme_test < buy_me_db.sql
DB_URL="jdbc:mysql://localhost:3306/buyme_test?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true" \
DB_USER=root DB_PASSWORD=yourpassword mvn verify
```

## Login credentials (demo/seed data)

- **Admin:** `admin` / `admin123`
- **Representative:** `rep1` / `rep123`
- **Test user:** `testuser` / `test123`

Passwords are hashed with bcrypt at rest — you still log in with the plaintext
password above.

## Demo video

https://drive.google.com/file/d/1eNDvC3UXfGIPVxB62knIVJrv9m8mJx2c/view
