param(
    [string]$EvidenceDirectory,
    [int]$PostgresPort = 55440
)
$ErrorActionPreference = 'Stop'
$repoDirectory = Split-Path -Parent $PSScriptRoot
if (-not $EvidenceDirectory) {
    $EvidenceDirectory = Join-Path $repoDirectory ('.qa-evidence/hu002-' + [guid]::NewGuid().ToString('N'))
}
if (Test-Path -LiteralPath $EvidenceDirectory) { throw 'Choose a new evidence directory.' }
New-Item -ItemType Directory -Path $EvidenceDirectory -Force | Out-Null
$EvidenceDirectory = (Resolve-Path -LiteralPath $EvidenceDirectory).Path
$projectName = 'facelit-hu002-qa'
$existingContainers = docker ps -aq --filter "label=com.docker.compose.project=$projectName"
if ($LASTEXITCODE -ne 0) { throw 'Docker is unavailable.' }
$existingVolumes = docker volume ls -q --filter "label=com.docker.compose.project=$projectName"
if ($existingContainers -or $existingVolumes) { throw 'Existing QA project detected; refusing to reuse its data.' }

$baselineDirectory = Join-Path $EvidenceDirectory 'baseline'
$archivePath = Join-Path $EvidenceDirectory 'baseline.zip'
$baselineSha = '3729fa3aa600acf107199d08b713a3851ebbd839'
git -C $repoDirectory archive --format=zip "--output=$archivePath" $baselineSha
if ($LASTEXITCODE -ne 0) { throw 'Baseline commit is unavailable; fetch its history first.' }
Expand-Archive -LiteralPath $archivePath -DestinationPath $baselineDirectory
$baselineCompose = Join-Path $baselineDirectory 'docker-compose.yml'
$currentCompose = Join-Path $repoDirectory 'docker-compose.yml'
$logPath = Join-Path $EvidenceDirectory 'migration-rollback.log'
$env:POSTGRES_DB = 'facelit_hu002_qa'
$env:POSTGRES_USER = 'facelit_qa'
$env:POSTGRES_PASSWORD = 'local_disposable_qa_only'
$env:POSTGRES_PORT = [string]$PostgresPort

function Invoke-Migration([string]$ComposeFile, [string[]]$Command) {
    docker compose -p $projectName -f $ComposeFile run --rm liquibase @Command >> $logPath 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Liquibase failed. See $logPath" }
}
function Get-SchemaState {
    $sql = "SELECT (to_regclass('security.auth_rate_limit') IS NOT NULL)::int || ':' || (SELECT count(*) FROM information_schema.columns WHERE table_schema='security' AND table_name='password_recovery' AND column_name IN ('destination_email','verification_attempts','reset_token_hash'));"
    $result = docker compose -p $projectName -f $currentCompose exec -T postgres psql -U facelit_qa -d facelit_hu002_qa -Atc $sql
    if ($LASTEXITCODE -ne 0) { throw 'Schema inspection failed.' }
    return ($result -join '').Trim()
}

try {
    docker compose -p $projectName -f $baselineCompose up -d --wait postgres >> $logPath 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'Temporary PostgreSQL failed to start.' }
    Invoke-Migration $baselineCompose @('validate')
    Invoke-Migration $baselineCompose @('update')
    if ((Get-SchemaState) -ne '0:0') { throw 'Unexpected baseline schema.' }
    Invoke-Migration $baselineCompose @('tag', 'hu002-before')
    Invoke-Migration $currentCompose @('validate')
    Invoke-Migration $currentCompose @('update')
    if ((Get-SchemaState) -ne '1:3') { throw 'HU002 schema was not applied.' }
    Write-Output 'PASS: migration 023 applied.'
    Invoke-Migration $currentCompose @('rollback', '--tag=hu002-before')
    if ((Get-SchemaState) -ne '0:0') { throw 'HU002 rollback was incomplete.' }
    Write-Output 'PASS: migration 023 rolled back.'
    Invoke-Migration $currentCompose @('update')
    if ((Get-SchemaState) -ne '1:3') { throw 'HU002 schema was not reapplied.' }
    Write-Output 'PASS: migration 023 reapplied.'
} finally {
    docker compose -p $projectName -f $currentCompose down --volumes --remove-orphans >> $logPath 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'Temporary environment cleanup failed; inspect Docker before rerunning.' }
    Write-Output "Evidence: $logPath"
}
