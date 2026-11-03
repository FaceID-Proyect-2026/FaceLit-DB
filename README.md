# FaceLit database

# Documentación : https://github.com/FaceID-Proyect-2026/facelit-docs

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
5. [Schema naming migrations](06_migrations/001_english_nomenclature.changelog.yaml): expand and contract run after historical seeds and patches.

### Migration traceability

| Requirement or decision | Changeset | Verification |
| --- | --- | --- |
| HU-002 · Persist recovery sessions in the database | [`facelit-hu-mej-002-recovery-session-security`](01_ddl/04_alter/0000changelog.yaml) | [HU-002 migration check](scripts/test-hu002-migration.ps1) |
| Store authorization for facial re-registration | [`facelit-face-reset-authorization`](01_ddl/04_alter/017_face_reset_authorization.changelog.yaml) | [Database CI](.github/workflows/ci.yml) validates and applies the active changelog. This checks migration execution. |
| H50 · Adopt English schema names in expand and contract phases | [`facelit-h50-english-nomenclature-expand` and `facelit-h50-english-nomenclature-contract`](06_migrations/001_english_nomenclature.changelog.yaml) | [Naming migration check](scripts/test-nomenclature-migration.ps1) and [contracted schema assertions](tests/nomenclature/contracted.sql) |

Use the changeset ID to find its source and rollback declaration, then record the commit and the CI run or local check result when reviewing a migration. The table points to verification procedures rather than recording a new test run.

The table changelog defines the seven component groups. Alterations include account-access fields, notification catalog changes, facial reset authorization, session times, email-only reminders and subsequent corrections. Follow include order; numerical filenames alone do not determine execution order.

[Index changes](01_ddl/10_indexes/0000changelog.yaml) are active. They cover role assignments, academic relationships, environment sessions, unread notifications, legal acceptance and facial attendance/template constraints. Additional constraints/indexes may also be defined inside table or alteration SQL.

[Seed changes](02_dml/00_inserts/0000changelog.yaml) retain [seed.sql](02_dml/00_inserts/seed.sql) for roles and permissions. The obsolete `02-seed-coordinator` account changeset and its credential-bearing SQL/rollback files have been retired from the active tree. A fresh migration does not create a user account. Create the first coordinator through the backend's private one-time configuration.

For an already migrated database, keep its historical `DATABASECHANGELOG` entry and checksum: do not delete the account, reset checksums or recreate the database. The remaining schema changesets are unchanged. Update to this changelog, then use `FaceLit-Backend/scripts/initialize-coordinator.ps1 -Mode Rotate` with the existing coordinator's document/email and a new password entered privately. Its IDs and history remain intact; sessions and recovery authorizations are invalidated. Historical credential material remains in old Git commits, so removing current files is not proof of rotation in any real environment. The retired account changeset is no longer a rollback target in the active changelog; use reviewed backups/recovery procedures instead of deleting an established coordinator.

Run [scripts/test-coordinator-bootstrap.ps1](scripts/test-coordinator-bootstrap.ps1) with Docker and the sibling backend to verify a fresh database and an upgrade from the pinned historical baseline. The test uses two temporary databases on loopback port 55447, checks unchanged historical metadata and login after rotation, and removes its own container. It does not operate on the normal database. Its historical baseline archive is test evidence, not a deployment input or a file to publish.

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

The [rollback helper](scripts/rollback-by-id.ps1) and [reapply helper](scripts/reapply-after-rollback.ps1) are executable tools. Their default project is `facelit-docker-compose`; the rollback helper defaults to user `facelit_user` and database `facelit-db`, matching the development Compose defaults. Override these parameters when your environment uses different values, and select preview mode before considering execution. Existing confirmation, dependency checks and rollback/reapply logic are preserved. Generated SQL previews belong in ignored `.tmp/`, not in Git.

When introducing new database changes, create a new changeset and preserve applied ones. Validate the entire include chain and test forward/reverse behavior in an isolated database. Do not renumber files, clear checksums or mark changes as applied merely to hide a mismatch.

## Continuous integration

The [CI workflow](.github/workflows/ci.yml) runs on pull requests and pushes to develop, dev, qa and main, with optional manual dispatch. Its `PostgreSQL and Liquibase integration` job starts a disposable PostgreSQL instance with dummy CI credentials, runs Liquibase `validate`, `update` and `status --verbose`, and removes only the runner's temporary environment at completion. It does not connect to the installed development or production database.

The `database-migration-logs` artifact preserves command output. Bash pipefail prevents log capture from hiding a Liquibase failure. This checks the active migration chain on a fresh database; it does not certify every rollback, an upgrade of existing production data or application login. It produces migration evidence rather than a source-code coverage percentage.

For HU-MEJ-006 acceptance, record the exact head SHA and green Actions run, inspect its artifact, verify the required check and independent approval, and retain failed-check blocking evidence. Earlier runs and reports remain historical evidence only; new migrations must be assessed on the branch that actually contains them.

## Integration, verification and documentation policy

### Isolated cross-repository HTTP verification (HU46)

From this repository in PowerShell, with Docker running and the four sibling repositories available:

```powershell
.\scripts\test-architecture-e2e.ps1
```

The runner was recovered from `hu-44-dev` without merging that branch. It uses the current working trees, builds the facial image, applies this checkout's Liquibase chain on a separate PostgreSQL database, starts the test-only FastAPI inference fixture, and runs the backend's `ArchitectureFlowPostgresIT`. Ports `55439`, `18090`, `18080` and (for browser mode) `18081` must be free. It never targets the normal database on port 5439. Only containers, network and volumes created under its unique `facelit-arch-e2e-*` project are removed at completion; logs and revision metadata remain under ignored `.tmp/<project>/`.

Inference is deterministic and email is mocked. HTTP, JWT, liveness rules, repositories and PostgreSQL are exercised; camera recognition accuracy, production connectivity and facial inference latency are not certified by this test. Optional `-Browser` requires existing Playwright tooling and a browser; it is not enabled by default. `-MavenCommand` selects an installed Maven executable. `-SkipImageBuild -MicroImage <image>` reuses an existing compatible image while mounting the current microservice application and test fixture.

See the sibling backend's `docs/HU46_E2E_QA.md` for the review scope, execution results and remaining acceptance evidence. Integration into main still requires the team's reviewed PR; recovering this script locally does not itself close that delivery requirement or the separate CI integration point.

The standalone PowerShell regression for restoring process environment variables in the bootstrap and E2E runners can be run without Docker:

```powershell
.\scripts\tests\test-environment-restoration.ps1
```

It checks success/error cleanup, variables that were absent, pre-existing values, and that both runners restore from `finally`. The E2E runner's actual early-error path was also exercised with its test port deliberately occupied; it restored the environment and started no containers. These are script regressions; they do not rerun Liquibase or the HTTP integration flow.

The backend uses Hibernate validation and does not apply Liquibase automatically. The current facial service also queries academic/security/environment relationships when resolving owners and session candidates; separation of database ownership is a distinct architectural change. Apply compatible database changes before starting those services.

For acceptance, record the database commit and changelog status, test a fresh disposable database, and verify the coordinated application's login and relevant academic/facial/attendance flows. Migration success alone is not an application login test.

This README is the single maintained explanatory document. Active SQL, YAML changelogs, rollback scripts, configuration examples, Dockerfiles and executable utilities remain in place because they are functional inputs. Repository cleanup aligns tooling names with FaceLit and removes an unrelated generated SQL preview; it does not change schemas, migrations, roles, seed records or installed data.

Related repositories: [backend](https://github.com/FaceID-Proyect-2026/FaceLit-Backend), [frontend](https://github.com/FaceID-Proyect-2026/FaceLit), [facial service](https://github.com/FaceID-Proyect-2026/micro-facial).
