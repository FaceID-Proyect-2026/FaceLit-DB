# FaceLit database

PostgreSQL 16 and Liquibase migrations for FaceLit academic attendance. This repository owns the versioned schema, indexes, seed changes and rollback definitions used by the backend and facial service. [changelog-master.yaml](changelog-master.yaml) is the active deployment entry point.

## Architecture and active schema

| Schema | Responsibility |
| --- | --- |
| `security` | Application users, credentials, recovery/session/configuration and account-access changes |
| `roleandpermission` | Roles, permissions and their assignments |
| `academic` | Programs, instructors, apprentices, training groups, membership and transfers |
| `environment` | Environments and attendance sessions |
| `notification` | Notifications and email delivery records |
| `legal` | Terms acceptance |
| `facialrecognition` | Devices, facial templates, attendance events, biometric logs and reset requests |

The [schema creation script](01_ddl/01_schemas/001_create_schemas.sql) declares all seven schemas. The [extension script](01_ddl/00_extensions/001_enable_uuid_extension.sql) enables `uuid-ossp` and `vector`; use PostgreSQL with pgvector installed, as provided by the current Compose image.

```text
FaceLit-DB/
  changelog-master.yaml
  01_ddl/        Extensions, schemas, tables, alterations and indexes
  02_dml/        Seed/data changes, selected through their changelogs
  03_dcl/        Role, grant and policy changelog slots
  04_tcl/        Transaction/recovery changelog slots
  05_rollbacks/  Referenced reversal scripts
  docker/        Liquibase image with the PostgreSQL JDBC driver
  scripts/       Existing rollback/reapply utilities
  docker-compose.yml
  .env.example
  liquibase.properties.example
  README.md      Single maintained documentation entry
```

An existing directory or SQL file is not automatically deployed. Only entries reachable through the master changelog participate. Preserve their existing relative paths, IDs, authors, order and checksums.

## Changelog order and actual contents

The master includes these layers in order:

1. [DDL](01_ddl/changelog.yaml): extensions, schemas and dedicated type slots, tables, alterations, remaining object-family slots, then indexes.
2. [DML](02_dml/changelog.yaml): the configured insert/update/delete/upsert/patch changelogs.
3. [DCL](03_dcl/changelog.yaml): the configured role/grant/policy slots.
4. [TCL](04_tcl/changelog.yaml): the configured transaction/recovery slots.

The table changelog defines the seven component groups. Alterations include account-access fields, notification catalog changes, facial reset authorization, session times, email-only reminders and subsequent corrections. Follow include order; numerical filenames alone do not determine execution order.

[Index changes](01_ddl/10_indexes/0000changelog.yaml) are active. They cover role assignments, academic relationships, environment sessions, unread notifications, legal acceptance and facial attendance/template constraints. Additional constraints/indexes may also be defined inside table or alteration SQL.

[Seed changes](02_dml/00_inserts/0000changelog.yaml) are active, including [seed.sql](02_dml/00_inserts/seed.sql) and the initial coordinator changeset. They are not an assertion that no initial data exists. Do not publish personal credentials or infer a seed account's plaintext password from a stored hash; obtain authorized access through the operator.

Several dedicated object families and DCL/TCL slots currently contain empty `databaseChangeLog` lists. Their presence describes extension points, not implemented views, functions, policies or recovery operations. Conversely, populated indexes and seeds must not be described as unused placeholders.

## Prerequisites and local configuration

Use Docker with Compose, or a compatible local PostgreSQL/pgvector and Liquibase installation. The current [Liquibase Dockerfile](docker/liquibase/Dockerfile) uses Liquibase 5.0.2 with PostgreSQL JDBC 42.7.8.

Copy [.env.example](.env.example) to `.env` only if a local file does not already exist. The Compose variables are:

| Variable | Purpose |
| --- | --- |
| `POSTGRES_DB` | Database name |
| `POSTGRES_USER` | Database account |
| `POSTGRES_PASSWORD` | Local connection password; configure privately for each environment |
| `POSTGRES_PORT` | Host port, normally 5439 in this development topology |

Example values are development configuration, not production credentials. From a host process, connect to the configured localhost port. Other containers on the same Compose network use `postgres:5432`, not the host-mapped port. Backend JDBC and micro-facial SQLAlchemy URLs must point to the same intended environment where that is the current integration contract.

## Start and migrate with Docker

From this repository root:

```bash
docker compose -p facelit-docker-compose up -d postgres
docker compose -p facelit-docker-compose --profile tooling build liquibase
docker compose -p facelit-docker-compose --profile tooling run --rm liquibase validate
docker compose -p facelit-docker-compose --profile tooling run --rm liquibase status
docker compose -p facelit-docker-compose --profile tooling run --rm liquibase update-sql
docker compose -p facelit-docker-compose --profile tooling run --rm liquibase update
docker compose -p facelit-docker-compose --profile tooling run --rm liquibase history
```

These commands use the actual `postgres` and `liquibase` services and `tooling` profile in [docker-compose.yml](docker-compose.yml). `update-sql` generates a preview; `update` changes the selected database. Inspect the target and pending changes first. A successful `validate` alone does not prove application compatibility or a successful migration on a new database.

For local Liquibase, copy [liquibase.properties.example](liquibase.properties.example) to ignored `liquibase.properties`, set the intended private connection values and ensure the JDBC driver is installed. From the repository root, the corresponding commands are `liquibase validate`, `status`, `update-sql`, `update` and `history`.

## Rollback and operational constraints

Reversal scripts live under [05_rollbacks](05_rollbacks), referenced from individual changesets. Support is per changeset: do not assume every alteration has a complete or validated rollback. In particular, inspect the current declarations and reversals rather than promising that all data changes are reversible.

Preview a reversal before any authorized execution:

```bash
docker compose -p facelit-docker-compose --profile tooling run --rm liquibase rollback-count-sql --count=1
```

On a disposable verification database or an approved maintenance target, `rollback-count --count=1` reverses the last changeset if its rollback is supported. Tags/history can help identify a release boundary. Preserve backups and application compatibility; do not remove existing volumes as an upgrade or troubleshooting step.

The [rollback helper](scripts/rollback-by-id.ps1) and [reapply helper](scripts/reapply-after-rollback.ps1) are executable tools, not documentation to delete. Their inherited defaults reference a different project, so explicitly select `facelit-docker-compose`, the intended user/database and preview mode when inspecting their use. They do not replace review of dependencies or authorization for a destructive operation. This README correction does not alter these utilities or their behavior.

When introducing new database changes, create a new changeset and preserve applied ones. Validate the entire include chain and test forward/reverse behavior in an isolated database. Do not renumber files, clear checksums or mark changes as applied merely to hide a mismatch.

## Integration, verification and documentation policy

The backend uses Hibernate validation and does not apply Liquibase automatically. The current facial service also queries academic/security/environment relationships when resolving owners and session candidates; separation of database ownership is a distinct architectural change. Apply compatible database changes before starting those services.

For acceptance, record the database commit and changelog status, test a fresh disposable database, and verify the coordinated application's login and relevant academic/facial/attendance flows. Migration success alone is not an application login test.

This README is the single maintained explanatory document. SQL, YAML changelogs, rollback scripts, configuration examples, Dockerfiles and executable utilities remain in place because they are functional inputs. This correction modifies documentation only; it does not change schemas, migrations, roles, seed records or installed data.

Related repositories: [backend](https://github.com/FaceID-Proyect-2026/FaceLit-Backend), [frontend](https://github.com/FaceID-Proyect-2026/FaceLit), [facial service](https://github.com/FaceID-Proyect-2026/micro-facial).
