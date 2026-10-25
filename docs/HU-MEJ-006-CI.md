# HU-MEJ-006 — CI de base de datos

## Alcance

Base: main, SHA 3729fa3aa600acf107199d08b713a3851ebbd839. Publicación mediante codex/hu-mej-006-ci-db y PR hacia main, sin push directo a la rama protegida. Se añaden exclusivamente el workflow y esta guía; no se modifican SQL, changesets históricos, rollback ni Compose existente.

## Ejecución

.github/workflows/ci.yml ejecuta todos los PR y pushes a develop/dev/qa/main. Utiliza el Compose existente para iniciar PostgreSQL efímero con credenciales ficticias de CI, ejecutar Liquibase validate, update y status --verbose. Al finalizar elimina el entorno temporal y su volumen. Esto sucede en el runner de GitHub; no se conecta a la base local ni a producción.

Los comandos de Liquibase conservan sus logs en el artifact database-migration-logs. El shell Bash configurado por Actions usa pipefail: tee conserva los logs sin ocultar un fallo de Liquibase.

Check que debe exigirse en el ruleset: PostgreSQL and Liquibase integration. Seleccionarlo después de la primera ejecución y verificar que aparezca Required en el PR. La regla también debe exigir revisión independiente.

## Evidencia local previa

Se usó un proyecto Docker aislado facelit-hu006-ci, con PostgreSQL temporal en el puerto 55439. Liquibase validate terminó sin errores. Liquibase update aplicó 41 changesets desde cero, con 0 previos; salida 0. Después se retiraron únicamente los contenedores, red y volumen de ese proyecto temporal.

Los YAML se parsearon correctamente y git diff --check pasó. No se presenta como prueba de rollback de todos los changesets ni como validación de una actualización sobre una base productiva existente. Esta CI mide la integridad y aplicación del esquema; no produce un porcentaje de cobertura de código comparable a JaCoCo o pytest-cov.

## Pendiente de aceptación

Registrar SHA publicado, URL del PR y de la ejecución verde real, descargar el artifact y obtener revisión independiente. La configuración local y la prueba previa no sustituyen la ejecución de GitHub Actions ni permiten declarar HU-MEJ-006 Done por sí solas.

Origen de la HU: https://code-sena.github.io/ADSO-3145555/informes/2026-10-23-evaluacion-e2e-3145555/equipo-04.html — H-18, según los extractos suministrados. Esta entrega no amplía los casos de autorización H-17 ni configura despliegue.
