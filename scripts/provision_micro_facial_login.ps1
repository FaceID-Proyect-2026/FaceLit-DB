param(
    [string]$AdminUser = 'facelit_user',
    [string]$Database = 'facelit-db',
    [string]$RuntimeUser = 'facelit_micro_runtime'
)

$ErrorActionPreference = 'Stop'
$password = [Environment]::GetEnvironmentVariable('FACELIT_MICRO_DB_PASSWORD')
if ([string]::IsNullOrWhiteSpace($password)) {
    throw 'Define FACELIT_MICRO_DB_PASSWORD en el entorno antes de provisionar el usuario.'
}
if ($RuntimeUser -cnotmatch '^[a-z_][a-z0-9_]{0,62}$') {
    throw 'RuntimeUser debe ser un nombre de rol PostgreSQL simple.'
}

$encodedPassword = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($password))
$sqlTemplate = @'
DO $provision$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '__RUNTIME_USER__') THEN
        EXECUTE format('ALTER ROLE %I WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION INHERIT PASSWORD %L',
            '__RUNTIME_USER__', convert_from(decode('__PASSWORD_BASE64__', 'base64'), 'UTF8'));
    ELSE
        EXECUTE format('CREATE ROLE %I LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION INHERIT PASSWORD %L',
            '__RUNTIME_USER__', convert_from(decode('__PASSWORD_BASE64__', 'base64'), 'UTF8'));
    END IF;
END
$provision$;
GRANT facelit_micro_facial TO __RUNTIME_USER__;
'@
$sql = $sqlTemplate.Replace('__RUNTIME_USER__', $RuntimeUser).Replace('__PASSWORD_BASE64__', $encodedPassword)
$sql | docker compose exec -T postgres psql -U $AdminUser -d $Database -v ON_ERROR_STOP=1
if ($LASTEXITCODE -ne 0) {
    throw 'No se pudo crear el usuario de ejecución de micro-facial.'
}
