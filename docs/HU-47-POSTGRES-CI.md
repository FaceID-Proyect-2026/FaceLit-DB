# HU-47 — Punto 4: integración PostgreSQL y migraciones en CI

Fecha: 1 de noviembre de 2026. Equipo 4 — FaceLit.

## Alcance

Automatizar las pruebas PostgreSQL de sesiones, validación JPA y reemplazo facial,
y comprobar migración, rollback y
reaplicación sobre bases temporales. Se conserva PostgreSQL compartido por las
dos APIs, la organización de cada repositorio y el recorrido facial existente.
Esta entrega modifica automatización y su evidencia; no cambia controladores,
servicios, repositorios de aplicación ni changesets aplicados.

## Archivos modificados

| Repositorio / rama | Archivo | Cambio |
|---|---|---|
| FaceLit-Backend / `hu-47-dev` | `.github/workflows/ci.yml` | Job PostgreSQL con pgvector, Liquibase y las suites existentes de sesión HTTP y validación del esquema JPA. |
| micro-facial / `hu-47-dev` | `.github/workflows/ci.yml` | PostgreSQL con esquema Liquibase y `RF54_POSTGRES_TEST=1`; la prueba de reemplazo facial debe ejecutarse y aprobar. |
| FaceLit-DB / `hu-47-main` | `.github/workflows/ci.yml` | Rollback de los dos últimos changesets, reaplicación y comparación del esquema, roles semilla y cantidad de changesets. |
| FaceLit-DB / `hu-47-main` | `docs/HU-47-POSTGRES-CI.md` | Alcance, comandos y pasos de revisión de esta entrega. |

Frontend no requiere cambios para este punto.

Backend y micro obtienen el esquema de FaceLit-DB en el SHA
`74c1af01ccc8690080f746b745a037555a85547e`, revisado y probado en el punto 3.
Se fija el SHA para evitar que un cambio posterior de `main` altere silenciosamente
el resultado de un PR. Al adoptar nuevas migraciones se debe actualizar este SHA
en ambos workflows y validar compatibilidad.

## Qué debe comprobar QA en GitHub Actions

1. Abrir los PR de HU-47: backend y micro hacia `dev`; DB hacia `main`.
2. Backend: comprobar `PostgreSQL integration` y `Maven tests and JaCoCo coverage`.
   Descargar `backend-postgres-integration`; sus XML deben contener ambas suites
   con al menos una prueba y sin errores, fallos ni omisiones.
3. Micro: comprobar `Python unit tests and coverage`. Descargar
   `micro-facial-tests-and-coverage`; el XML debe incluir
   `test_real_postgres_replacement_consumption_and_rollback` aprobada.
4. DB: comprobar `PostgreSQL and Liquibase integration`. En
   `database-migration-logs` revisar `rollback.log`, `reapply.log`,
   `revalidate.log` y los archivos `before`/`after`.
5. Guardar el SHA final de cada PR, URL de ejecución y aprobación independiente.

El job obligatorio existente del backend depende del job PostgreSQL y ejecuta
`exit 1` si este falla o se omite. Así, la integración también bloquea el check
ya requerido, sin depender de añadir manualmente otro nombre a las reglas.
Las reglas activas consultadas el 1 de noviembre requieren:

| Repositorio | Check requerido | Ramas protegidas |
|---|---|---|
| Backend | `Maven tests and JaCoCo coverage` | dev, qa, main |
| Micro | `Python unit tests and coverage` | dev, qa, main |
| DB | `PostgreSQL and Liquibase integration` | dev, qa, main |

## Comandos y condiciones de ejecución

CI crea PostgreSQL temporal en `127.0.0.1:5439`, usando las credenciales de prueba
que aparecen en el workflow. Estos valores no son credenciales de producción.
Los pasos terminan con código distinto de cero ante un error y conservan logs;
la limpieza de contenedores y volúmenes temporales se ejecuta incluso si falla
una prueba. Los comandos con `tee` usan Bash con `pipefail` de GitHub Actions.

Después de aplicar Liquibase al PostgreSQL temporal, el comando del backend es:

```bash
./mvnw -B -ntp -Dtest=EnvironmentSessionIntegrationTest,SchemaValidationPostgresIT -Dsurefire.failIfNoSpecifiedTests=true test
```

Requiere las variables `FACELIT_SESSION_TEST_*` y `FACELIT_DB_*` indicadas en el
job. `EnvironmentSessionIntegrationTest` activa su perfil de prueba, con conexión,
driver, dialecto y `ddl-auto=validate` dirigidos a PostgreSQL. La validación JPA
usa el esquema migrado sin activar globalmente el perfil H2.

Micro ejecuta la suite completa con `RF54_POSTGRES_TEST=1` y `DATABASE_URL`
apuntando al PostgreSQL temporal. El test sigue rechazando hosts remotos.

DB ejecuta `liquibase validate`, `update`, `status --verbose`,
`rollback-count --count=2`, `update` y `validate`. El rollback cubre la pareja
actual de nomenclatura expandir/contraer, no el historial completo de migraciones.
La comparación de roles prueba conservación de esos datos semilla; no acredita
conservación de todos los datos de negocio posibles.

## Evidencias y cierre

La validación local equivalente se registra en
`ci-evidence/hu47-postgres/` del directorio de trabajo que contiene los repositorios.
Utiliza el puerto local 55439 porque 5439 pertenece al PostgreSQL de desarrollo.
Los reportes simulados para comprobar los detectores de omisiones son evidencia
negativa del detector; no se contabilizan como pruebas funcionales aprobadas.

Resultados locales ya obtenidos:

- Migración limpia: 44 changesets aplicados.
- Rollback y reaplicación: dos changesets; esquema, roles semilla y cantidad de
  changesets idénticos antes/después; segunda validación aprobada.
- Backend: 9 pruebas aprobadas, 0 fallos, 0 errores y 0 omitidas (8 de sesiones
  y 1 de esquema JPA). Java local 21; el workflow utiliza Java 17.
- Micro: 139 pruebas aprobadas, 0 fallos, 0 errores y 0 omitidas, incluida la
  integración PostgreSQL. Cobertura total 68 %; Ruff y `pip check` aprobados.
  Python local 3.11 en Docker; 46 advertencias de deprecaciones/metadata existentes.
- Detectores de omisiones: reportes correctos aceptados y reportes con integración
  omitida rechazados con código 1, en backend y micro.
- Changelog negativo temporal con SQL faltante: Liquibase lo rechazó con código 1;
  se guardó `negative-migration.log` y se retiró el changelog de prueba.

La primera validación local del micro no llegó a pytest porque Ruff intentó crear
su caché en el montaje de solo lectura. El reintento local usa `--no-cache`.
Esta condición corresponde al montaje del ensayo local, no al checkout escribible
de GitHub Actions. El reintento pasó las 139 pruebas. Los contenedores y volúmenes
temporales se eliminaron al finalizar.

No se incorporan en este job las pruebas opcionales de cámara/navegador, el ejecutor
arquitectónico completo ni el escenario de bootstrap con base heredada. Este alcance
no acredita esos recorridos en CI.

Las pruebas de ejecución locales aprobaron; las comprobaciones de sintaxis YAML
y `git diff --check` también. Los cambios permanecen locales en las ramas HU-47.
Pendiente publicar los cambios, abrir PR, asociar los SHA finales y guardar URLs
de CI verde. También falta comprobar en GitHub el bloqueo del merge con un check
rojo controlado; la prueba negativa local no sustituye esa evidencia.
Una ejecución local aprobada no acredita por sí sola CI verde ni bloqueo real
del merge con un check rojo. QA debe verificar ambos y emitir su aprobación.
