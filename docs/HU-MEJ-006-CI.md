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

## Actualización de evidencia y alcance — 25 de octubre de 2026

Rama de esta entrega: `hu-11-db`, PR [#60 hacia main](https://github.com/FaceID-Proyect-2026/FaceLit-DB/pull/60). El SHA base `d328a074f93c93396dabbbe596aea40c54d9005f` ya tiene una [ejecución real verde](https://github.com/FaceID-Proyect-2026/FaceLit-DB/actions/runs/40196918463); queda resuelta la falta de enlace remoto de la sección anterior para ese SHA. Al publicar esta actualización documental debe verificarse también el nuevo head del PR.

Se repitieron Liquibase 5.0.2 validate/update/status en PostgreSQL 16/pgvector temporal, sin publicar puertos ni montar datos de desarrollo: **41 changesets aplicados desde cero, validación correcta, sin cambios pendientes**. El contenedor temporal se eliminó y los servicios de desarrollo continuaron activos. Logs y comprobaciones están fuera del repositorio, en `ci-evidence/hu006-validation-20261025/` del directorio de trabajo.

Esta rama no contiene la migración 023 posterior de HU-MEJ-002: `security.auth_rate_limit` no existe en el SHA validado. Es una diferencia entre ramas, no un fallo de Liquibase. No se ejecutó rollback de todos los changesets en esta validación ni se alteraron migraciones aplicadas. No se calcula cobertura porcentual SQL.

La delimitación solicitada asigna HU-MEJ-006 a **H-16/H-18: automatización y evidencia**. Las reglas de autorización y recuperación de H-17 corresponden a HU-MEJ-001/HU-MEJ-002. La propuesta inicial incluía H-17; se conserva esta aclaración para trazabilidad y revisión de QA.

Se configuró como obligatorio `PostgreSQL and Liquibase integration` en el ruleset CI activo de dev/qa/main, con una aprobación y sin bypass. develop no está incluida. La responsable informa haber probado el bloqueo con CI rojo: falta adjuntar su evidencia y contrastarla. La aprobación independiente sigue pendiente de acreditar en el PR. No se cambiaron workflow ni SQL en esta actualización documental; no se declara Done antes de evidencia y aprobación.

Documento de entrega compartido: [alcance, inventario y resultados de HU-MEJ-006](https://github.com/FaceID-Proyect-2026/FaceLit/blob/hu-38-dev/docs/HU-MEJ-006-ALCANCE-Y-ENTREGA-QA.md).

Origen de la HU: https://code-sena.github.io/ADSO-3145555/informes/2026-10-23-evaluacion-e2e-3145555/equipo-04.html — H-18, según los extractos suministrados. Esta entrega no amplía los casos de autorización H-17 ni configura despliegue.
