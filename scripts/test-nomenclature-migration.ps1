param()
$ErrorActionPreference = 'Stop'
$dbRoot = Split-Path $PSScriptRoot -Parent
$project = 'facelit-h50-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$compose = Join-Path $dbRoot 'docker-compose.yml'
$artifacts = Join-Path $dbRoot ".tmp/$project"
$saved = @{}
$created = $false

function Assert-NativeSuccess([string]$operation) {
    if ($LASTEXITCODE -ne 0) { throw "$operation failed with exit code $LASTEXITCODE" }
}
function Invoke-Migration([string[]]$arguments, [string]$log) {
    docker compose -f $compose -p $project --profile tooling run --rm liquibase @arguments 2>&1 |
        Tee-Object -FilePath (Join-Path $artifacts $log)
    Assert-NativeSuccess "Liquibase $arguments"
}
function Assert-Sql([string]$file) {
    $container = "$project-postgres-1"
    docker cp (Join-Path $dbRoot "tests/nomenclature/$file.sql") "${container}:/tmp/h50-check.sql"
    Assert-NativeSuccess 'Copy SQL check'
    docker exec $container psql -U facelit_h50 -d facelit_h50 -v ON_ERROR_STOP=1 -f /tmp/h50-check.sql
    Assert-NativeSuccess "SQL assertions: $file"
}

try {
    foreach ($name in @('POSTGRES_DB','POSTGRES_USER','POSTGRES_PASSWORD','POSTGRES_PORT')) {
        $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    }
    $probe = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 55440)
    try { $probe.Start() } finally { $probe.Stop() }
    New-Item -ItemType Directory -Path $artifacts -Force | Out-Null
    $env:POSTGRES_DB = 'facelit_h50'
    $env:POSTGRES_USER = 'facelit_h50'
    $env:POSTGRES_PASSWORD = 'migration-test-only'
    $env:POSTGRES_PORT = '127.0.0.1:55440'
    $created = $true
    docker compose -f $compose -p $project up -d --wait postgres
    Assert-NativeSuccess 'Start disposable PostgreSQL'
    Invoke-Migration -arguments @('validate') -log 'validate.log'
    Invoke-Migration -arguments @('update', '--label-filter=!nomenclature-expand AND !nomenclature-contract') -log 'legacy-update.log'
    Assert-Sql 'legacy-fixture'
    Invoke-Migration -arguments @('update', '--label-filter=!nomenclature-contract') -log 'expand.log'
    Assert-Sql 'expanded'
    Invoke-Migration -arguments @('update') -log 'contract.log'
    Assert-Sql 'contracted'
    Invoke-Migration -arguments @('rollback-count', '--count=1') -log 'rollback-contract.log'
    Assert-Sql 'expanded'
    Invoke-Migration -arguments @('rollback-count', '--count=1') -log 'rollback-expand.log'
    Assert-Sql 'rolled-back'
    Invoke-Migration -arguments @('update') -log 'reapply.log'
    Assert-Sql 'contracted'
    Invoke-Migration -arguments @('status', '--verbose') -log 'status.log'
    Write-Host "PASS H50: existing data, both writers, constraints, both rollbacks and reapply. Evidence: $artifacts"
} finally {
    if ($created) { docker compose -f $compose -p $project down --volumes --remove-orphans }
    foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
}
