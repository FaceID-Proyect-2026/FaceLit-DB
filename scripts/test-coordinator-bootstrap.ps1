param(
    [string]$BackendRepository = (Join-Path $PSScriptRoot '../../FaceLit-Backend'),
    [string]$MavenCommand,
    [string]$BaselineRef = 'd2879d7330f995e7ee1f854b72d87024cd9a09d2',
    [string]$EvidenceDirectory
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/Restore-ProcessEnvironment.ps1')
$databasePath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$backendPath = (Resolve-Path $BackendRepository).Path
if (!$MavenCommand) { $MavenCommand = Join-Path $backendPath 'mvnw.cmd' }
if (!$EvidenceDirectory) { $EvidenceDirectory = Join-Path $databasePath ("../ci-evidence/bootstrap-" + [guid]::NewGuid().ToString('N')) }
if (Test-Path -LiteralPath $EvidenceDirectory) { throw 'Choose a new evidence directory.' }
New-Item -ItemType Directory -Path $EvidenceDirectory > $null
$evidence = (Resolve-Path $EvidenceDirectory).Path
$baseline = Join-Path $evidence 'baseline'
& git -C $databasePath archive --format=zip "--output=$(Join-Path $evidence 'baseline.zip')" $BaselineRef
if ($LASTEXITCODE -ne 0) { throw 'The historical baseline is unavailable. Fetch its history or provide BaselineRef.' }
Expand-Archive -LiteralPath (Join-Path $evidence 'baseline.zip') -DestinationPath $baseline
$container = "facelit-bootstrap-check-$PID"
$created = $false
$settings = @{
    FACELIT_BOOTSTRAP_POSTGRES_TEST = '1'
    FACELIT_BOOTSTRAP_TEST_URL = ''
    FACELIT_BOOTSTRAP_TEST_MODE = ''
    FACELIT_BOOTSTRAP_LEGACY_ID = ''
    FACELIT_BOOTSTRAP_LEGACY_HASH = ''
    FACELIT_BOOTSTRAP_LEGACY_CHECKSUM = ''
    FACELIT_BOOTSTRAP_LEGACY_SESSION = ''
    FACELIT_COORDINATOR_BOOTSTRAP = 'true'
    FACELIT_COORDINATOR_ROTATE_PASSWORD = 'false'
    FACELIT_COORDINATOR_EXIT_AFTER = 'false'
    FACELIT_COORDINATOR_DOCUMENT = '9876543210'
    FACELIT_COORDINATOR_FIRST_NAME = 'Bootstrap'
    FACELIT_COORDINATOR_LAST_NAME = 'Test'
    FACELIT_COORDINATOR_EMAIL = 'bootstrap@example.invalid'
    FACELIT_COORDINATOR_PASSWORD = 'BootstrapTest1!'
}
$previous = @{}
foreach ($key in $settings.Keys) { $previous[$key] = [Environment]::GetEnvironmentVariable($key,'Process') }
function Invoke-Docker {
    & docker @args
    if ($LASTEXITCODE -ne 0) { throw "Docker failed: $($args[0])" }
}
function Query([string]$database,[string]$sql) {
    $result = & docker exec $container psql -U bootstrap_test -d $database -Atc $sql
    if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL verification failed.' }
    return ($result -join "`n").Trim()
}
function Migrate([string]$source,[string]$database) {
    $arguments = @('run','--rm','--network',"container:$container",'--mount',"type=bind,source=$source,target=/workspace,readonly",'facelit-liquibase:5.0.2',
        '--search-path=/workspace','--changelog-file=changelog-master.yaml','--classpath=/liquibase/liquibase_libs/postgresql-42.7.8.jar',
        "--url=jdbc:postgresql://127.0.0.1:5432/$database",'--username=bootstrap_test','--password=bootstrap-test-local-only')
    Invoke-Docker @arguments validate
    Invoke-Docker @arguments update
}
function Test-Bootstrap([string]$mode,[string]$database) {
    $settings.FACELIT_BOOTSTRAP_TEST_MODE = $mode
    $settings.FACELIT_BOOTSTRAP_TEST_URL = "jdbc:postgresql://127.0.0.1:55447/$database"
    foreach ($key in $settings.Keys) { [Environment]::SetEnvironmentVariable($key,$settings[$key],'Process') }
    $log = Join-Path $evidence "$mode-tests.log"
    Push-Location $backendPath
    try {
        & $MavenCommand '-Dtest=CoordinatorBootstrapPostgresIT' test *> $log
        if ($LASTEXITCODE -ne 0) { throw "Bootstrap tests failed: $mode. See $log" }
    } finally { Pop-Location }
    Select-String -Path $log -Pattern '^\[INFO\] Tests run:|BUILD SUCCESS' | ForEach-Object Line
}
try {
    Invoke-Docker create --name $container --label facelit.test=coordinator-bootstrap --tmpfs /var/lib/postgresql/data `
        -p 127.0.0.1:55447:5432 -e POSTGRES_DB=facelit_bootstrap_fresh -e POSTGRES_USER=bootstrap_test `
        -e POSTGRES_PASSWORD=bootstrap-test-local-only pgvector/pgvector:pg16
    $created = $true
    Invoke-Docker start $container
    $ready = $false
    for ($i = 0; $i -lt 40; $i++) {
        & docker exec $container pg_isready -U bootstrap_test -d facelit_bootstrap_fresh *> $null
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
        Start-Sleep -Seconds 1
    }
    if (!$ready) { throw 'Temporary PostgreSQL did not start.' }
    Invoke-Docker build -t facelit-liquibase:5.0.2 -f (Join-Path $databasePath 'docker/liquibase/Dockerfile') $databasePath
    Migrate $databasePath 'facelit_bootstrap_fresh'
    if ((Query 'facelit_bootstrap_fresh' 'SELECT count(*) FROM security.user_app') -ne '0') { throw 'A fresh migration must not create a user account.' }
    Test-Bootstrap 'fresh' 'facelit_bootstrap_fresh'

    Query 'facelit_bootstrap_fresh' 'CREATE DATABASE facelit_bootstrap_upgrade' > $null
    Migrate $baseline 'facelit_bootstrap_upgrade'
    $settings.FACELIT_BOOTSTRAP_LEGACY_ID = Query 'facelit_bootstrap_upgrade' "SELECT id_user_app FROM security.user_app WHERE created_by='liquibase-seed'"
    $settings.FACELIT_COORDINATOR_DOCUMENT = Query 'facelit_bootstrap_upgrade' "SELECT number_document FROM security.user_app WHERE id_user_app='$($settings.FACELIT_BOOTSTRAP_LEGACY_ID)'"
    $settings.FACELIT_COORDINATOR_EMAIL = Query 'facelit_bootstrap_upgrade' "SELECT email FROM security.credential WHERE id_user_app='$($settings.FACELIT_BOOTSTRAP_LEGACY_ID)'"
    $settings.FACELIT_BOOTSTRAP_LEGACY_HASH = Query 'facelit_bootstrap_upgrade' "SELECT password_hash FROM security.credential WHERE id_user_app='$($settings.FACELIT_BOOTSTRAP_LEGACY_ID)'"
    $settings.FACELIT_BOOTSTRAP_LEGACY_CHECKSUM = Query 'facelit_bootstrap_upgrade' "SELECT md5sum FROM databasechangelog WHERE id='02-seed-coordinator'"
    $settings.FACELIT_BOOTSTRAP_LEGACY_SESSION = [guid]::NewGuid().ToString()
    Query 'facelit_bootstrap_upgrade' "INSERT INTO security.user_session(id_user_session,id_user_app,start_date,session_status) VALUES ('$($settings.FACELIT_BOOTSTRAP_LEGACY_SESSION)','$($settings.FACELIT_BOOTSTRAP_LEGACY_ID)',NOW(),'ACTIVE')" > $null
    Query 'facelit_bootstrap_upgrade' "INSERT INTO security.password_recovery(id_password_recovery,id_user_app,token,expiration_date,used) VALUES (uuid_generate_v4(),'$($settings.FACELIT_BOOTSTRAP_LEGACY_ID)','987654',NOW()+INTERVAL '5 minutes',FALSE)" > $null
    Migrate $databasePath 'facelit_bootstrap_upgrade'
    if ((Query 'facelit_bootstrap_upgrade' "SELECT md5sum FROM databasechangelog WHERE id='02-seed-coordinator'") -ne $settings.FACELIT_BOOTSTRAP_LEGACY_CHECKSUM) { throw 'Historical checksum was changed.' }
    $settings.FACELIT_COORDINATOR_ROTATE_PASSWORD = 'true'
    Test-Bootstrap 'upgrade' 'facelit_bootstrap_upgrade'
    "PASS: fresh creation, compatible upgrade, coordinator rotation, unchanged historical checksum. Evidence: $evidence"
} finally {
    Restore-ProcessEnvironment -Snapshot $previous
    $settings.FACELIT_BOOTSTRAP_LEGACY_HASH = $null
    $settings.FACELIT_COORDINATOR_PASSWORD = $null
    if ($created) {
        & docker rm -f $container
        if ($LASTEXITCODE -ne 0) { throw "Temporary container cleanup failed: $container" }
    }
}
