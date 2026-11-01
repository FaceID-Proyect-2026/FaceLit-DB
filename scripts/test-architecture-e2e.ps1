param(
    [string]$MicroImage = 'facelit-architecture-e2e:local',
    [switch]$SkipImageBuild,
    [switch]$Browser,
    [string]$PlaywrightModule = '',
    [string]$WebExport = '',
    [string]$MavenCommand = '',
    [ValidateRange(30, 600)][int]$StartupTimeoutSeconds = 300
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/Restore-ProcessEnvironment.ps1')
$dbRoot = Split-Path $PSScriptRoot -Parent
$workspace = Split-Path $dbRoot -Parent
$backend = Join-Path $workspace 'FaceLit-Backend'
$frontend = Join-Path $workspace 'FaceLit'
$micro = Join-Path $workspace 'micro-facial'
$project = 'facelit-arch-e2e-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$microContainer = "$project-micro"
$compose = Join-Path $dbRoot 'docker-compose.yml'
$artifacts = Join-Path $dbRoot ".tmp/$project"
$composeArguments = @('-f', $compose, '-f', (Join-Path $artifacts 'compose.test.yaml'), '-p', $project)
$createdDatabase = $false
$createdMicro = $false
$savedEnvironment = @{}
if (-not $MavenCommand) { $MavenCommand = Join-Path $backend 'mvnw.cmd' }
foreach ($required in @($backend, $micro, (Join-Path $micro 'tests/support/e2e_app.py'),
    (Join-Path $backend 'src/test/java/com/FaceLit/backend/facial/ArchitectureFlowPostgresIT.java'))) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing E2E dependency: $required" }
}
$variables = @('POSTGRES_DB', 'POSTGRES_USER', 'POSTGRES_PASSWORD', 'POSTGRES_PORT',
    'FACELIT_ARCH_E2E', 'FACELIT_ARCH_BROWSER_SCRIPT', 'FACELIT_PLAYWRIGHT_MODULE',
    'FACELIT_ARCH_WEB_EXPORT', 'FACELIT_ARCH_ARTIFACTS', 'EXPO_PUBLIC_API_URL', 'EXPO_NO_DOTENV', 'CI',
    'FACELIT_COORDINATOR_BOOTSTRAP', 'FACELIT_COORDINATOR_ROTATE_PASSWORD', 'FACELIT_COORDINATOR_EXIT_AFTER')

function Assert-NativeSuccess([string]$Operation) {
    if ($LASTEXITCODE -ne 0) { throw "$Operation failed with exit code $LASTEXITCODE" }
}

function Invoke-NativeLogged {
    param(
        [string]$Executable,
        [string[]]$NativeArguments,
        [string]$LogPath,
        [switch]$Quiet,
        [switch]$AllowFailure
    )
    # Windows PowerShell 5.1 wraps redirected native stderr in ErrorRecord objects.
    # Docker progress and Java warnings are not failures: preserve their text and
    # decide success using the native exit code after the pipeline completes.
    $null = Get-Command -Name $Executable -ErrorAction Stop
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $Executable @NativeArguments 2>&1 |
            ForEach-Object { $_.ToString() } |
            Tee-Object -FilePath $LogPath -ErrorAction Stop |
            ForEach-Object { if (-not $Quiet) { Write-Output $_ } }
        $nativeExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($nativeExitCode -ne 0) {
        if ($AllowFailure) { Write-Warning "$Executable exited with code $nativeExitCode; see $LogPath" }
        else { throw "$Executable failed with exit code $nativeExitCode; see $LogPath" }
    }
}

try {
    foreach ($name in $variables) {
        $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    }
    # Fixed loopback ports are the opt-in test contract. Refuse occupied ports.
    foreach ($port in @(55439, 18090, 18080, 18081)) {
        $probe = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
        try { $probe.Start() } finally { $probe.Stop() }
    }
    New-Item -ItemType Directory -Path $artifacts -Force | Out-Null
    # Allow Docker Desktop cold starts without changing the development Compose health policy.
    @'
services:
  postgres:
    healthcheck:
      interval: 5s
      timeout: 15s
      retries: 30
      start_period: 60s
'@ | Set-Content -LiteralPath (Join-Path $artifacts 'compose.test.yaml') -Encoding UTF8
    $revisions = foreach ($repository in @($frontend, $backend, $dbRoot, $micro)) {
        $revision = & git -C $repository rev-parse HEAD
        Assert-NativeSuccess 'Read revision'
        $branch = & git -C $repository branch --show-current
        Assert-NativeSuccess 'Read branch'
        [pscustomobject]@{ Repository = Split-Path $repository -Leaf; Branch = $branch; SHA = $revision;
            WorkingChanges = @(& git -C $repository status --short) }
    }
    $revisions | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $artifacts 'revisions.json') -Encoding UTF8
    # Bootstrap belongs to its dedicated tests, never to this disposable HTTP fixture.
    $env:FACELIT_COORDINATOR_BOOTSTRAP = 'false'
    $env:FACELIT_COORDINATOR_ROTATE_PASSWORD = 'false'
    $env:FACELIT_COORDINATOR_EXIT_AFTER = 'false'
    $env:POSTGRES_DB = 'facelit_arch'
    $env:POSTGRES_USER = 'facelit_arch'
    $env:POSTGRES_PASSWORD = 'architecture-e2e-local-only'
    $env:POSTGRES_PORT = '127.0.0.1:55439'

    $createdDatabase = $true
    docker compose @composeArguments up -d --wait --wait-timeout $StartupTimeoutSeconds postgres
    Assert-NativeSuccess 'Start isolated PostgreSQL'
    Invoke-NativeLogged -Executable docker -NativeArguments (@('compose') + $composeArguments + @('--profile','tooling','run','--rm','liquibase','validate')) `
        -LogPath (Join-Path $artifacts 'liquibase-validate.log')
    Invoke-NativeLogged -Executable docker -NativeArguments (@('compose') + $composeArguments + @('--profile','tooling','run','--rm','liquibase','update')) `
        -LogPath (Join-Path $artifacts 'liquibase-update.log')

    if (-not $SkipImageBuild) {
        docker build -t $MicroImage $micro
        Assert-NativeSuccess 'Build facial test image'
    }
    $createdMicro = $true
    docker run -d --name $microContainer --network "${project}_default" -p '127.0.0.1:18090:8090' `
        --mount "type=bind,source=$(Join-Path $micro 'app'),target=/app/app,readonly" `
        --mount "type=bind,source=$(Join-Path $micro 'tests/support'),target=/e2e,readonly" `
        -e PYTHONPATH=/app -e API_KEY=architecture-test-key -e PRELOAD_MODEL=false `
        -e DATABASE_URL=postgresql+asyncpg://facelit_arch:architecture-e2e-local-only@postgres:5432/facelit_arch `
        $MicroImage uvicorn e2e_app:app --app-dir /e2e --host 0.0.0.0 --port 8090
    Assert-NativeSuccess 'Start isolated facial fixture'
    $ready = $false
    $startup = [System.Diagnostics.Stopwatch]::StartNew()
    while ($startup.Elapsed.TotalSeconds -lt $StartupTimeoutSeconds) {
        try {
            $health = Invoke-RestMethod 'http://127.0.0.1:18090/health' -TimeoutSec 2
            if ($health.status -eq 'ok') { $ready = $true; break }
        } catch { }
        Start-Sleep -Seconds 1
    }
    if (-not $ready) { throw 'The isolated facial API did not become ready' }

    $env:FACELIT_ARCH_E2E = '1'
    $env:FACELIT_ARCH_BROWSER_SCRIPT = ''
    if ($Browser) {
        $env:FACELIT_PLAYWRIGHT_MODULE = $PlaywrightModule
        $env:FACELIT_ARCH_WEB_EXPORT = if ($WebExport) { (Resolve-Path -LiteralPath $WebExport).Path } else { Join-Path $artifacts 'web' }
        $env:FACELIT_ARCH_ARTIFACTS = Join-Path $artifacts 'browser'
        $env:EXPO_PUBLIC_API_URL = 'http://127.0.0.1:18080'
        $env:EXPO_NO_DOTENV = '1'
        $env:CI = '1'
        if (-not $WebExport) {
            Push-Location $frontend
            try {
                & (Join-Path $frontend 'node_modules/.bin/expo.cmd') export --platform web `
                    --output-dir $env:FACELIT_ARCH_WEB_EXPORT --max-workers 2 --clear
                Assert-NativeSuccess 'Export test web application'
            } finally { Pop-Location }
        }
        $env:FACELIT_ARCH_BROWSER_SCRIPT = Join-Path $frontend 'scripts/test-architecture-browser.cjs'
    }
    Push-Location $backend
    try {
        Invoke-NativeLogged -Executable $MavenCommand `
            -NativeArguments @('-Dtest=ArchitectureFlowPostgresIT','-Dsurefire.failIfNoSpecifiedTests=true','test') `
            -LogPath (Join-Path $artifacts 'http-e2e.log')
        $reportPath = Join-Path $backend 'target/surefire-reports/TEST-com.FaceLit.backend.facial.ArchitectureFlowPostgresIT.xml'
        if (-not (Test-Path -LiteralPath $reportPath)) { throw 'E2E report was not generated' }
        [xml]$report = Get-Content -LiteralPath $reportPath -Raw
        if ([int]$report.testsuite.tests -lt 1 -or [int]$report.testsuite.skipped -gt 0 -or
            [int]$report.testsuite.failures -gt 0 -or [int]$report.testsuite.errors -gt 0) {
            throw 'The architecture integration must run without skipped or failed tests'
        }
        Copy-Item -LiteralPath $reportPath -Destination (Join-Path $artifacts 'architecture-tests.xml')
    } finally { Pop-Location }
    Write-Host "Integration passed. Evidence: $artifacts"
} finally {
    # Only resources created under this unique test project are removed.
    if ($createdMicro) {
        Invoke-NativeLogged -Executable docker -NativeArguments @('logs', $microContainer) `
            -LogPath (Join-Path $artifacts 'facial.log') -Quiet -AllowFailure
        docker rm -f $microContainer | Out-Null
    }
    if ($createdDatabase) {
        Invoke-NativeLogged -Executable docker -NativeArguments (@('compose') + $composeArguments + @('logs','--no-color','postgres')) `
            -LogPath (Join-Path $artifacts 'postgres.log') -Quiet -AllowFailure
        docker compose @composeArguments down --volumes --remove-orphans
    }
    Restore-ProcessEnvironment -Snapshot $savedEnvironment
}
