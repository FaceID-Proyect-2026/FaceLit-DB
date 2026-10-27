param(
    [string]$MicroImage = 'facelit-architecture-e2e:local',
    [switch]$SkipImageBuild,
    [switch]$Browser,
    [string]$PlaywrightModule = '',
    [string]$WebExport = ''
)

$ErrorActionPreference = 'Stop'
$dbRoot = Split-Path $PSScriptRoot -Parent
$workspace = Split-Path $dbRoot -Parent
$backend = Join-Path $workspace 'FaceLit-Backend'
$frontend = Join-Path $workspace 'FaceLit'
$micro = Join-Path $workspace 'micro-facial'
$project = 'facelit-arch-e2e-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$microContainer = "$project-micro"
$compose = Join-Path $dbRoot 'docker-compose.yml'
$artifacts = Join-Path $dbRoot ".tmp/$project"
$createdDatabase = $false
$createdMicro = $false
$savedEnvironment = @{}
$variables = @('POSTGRES_DB', 'POSTGRES_USER', 'POSTGRES_PASSWORD', 'POSTGRES_PORT',
    'FACELIT_ARCH_E2E', 'FACELIT_ARCH_BROWSER_SCRIPT', 'FACELIT_PLAYWRIGHT_MODULE',
    'FACELIT_ARCH_WEB_EXPORT', 'FACELIT_ARCH_ARTIFACTS', 'EXPO_PUBLIC_API_URL', 'EXPO_NO_DOTENV', 'CI')

function Assert-NativeSuccess([string]$Operation) {
    if ($LASTEXITCODE -ne 0) { throw "$Operation failed with exit code $LASTEXITCODE" }
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
    $env:POSTGRES_DB = 'facelit_arch'
    $env:POSTGRES_USER = 'facelit_arch'
    $env:POSTGRES_PASSWORD = 'architecture-e2e-local-only'
    $env:POSTGRES_PORT = '127.0.0.1:55439'

    $createdDatabase = $true
    docker compose -f $compose -p $project up -d --wait postgres
    Assert-NativeSuccess 'Start isolated PostgreSQL'
    docker compose -f $compose -p $project --profile tooling run --rm liquibase validate 2>&1 |
        Tee-Object -FilePath (Join-Path $artifacts 'liquibase-validate.log')
    Assert-NativeSuccess 'Validate existing migration chain'
    docker compose -f $compose -p $project --profile tooling run --rm liquibase update 2>&1 |
        Tee-Object -FilePath (Join-Path $artifacts 'liquibase-update.log')
    Assert-NativeSuccess 'Apply existing migrations'

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
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        try {
            $health = Invoke-RestMethod 'http://127.0.0.1:18090/health' -TimeoutSec 2
            if ($health.status -eq 'ok') { $ready = $true; break }
        } catch { Start-Sleep -Milliseconds 250 }
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
        & (Join-Path $backend 'mvnw.cmd') '-Dtest=ArchitectureFlowPostgresIT' test 2>&1 |
            Tee-Object -FilePath (Join-Path $artifacts 'http-e2e.log')
        Assert-NativeSuccess 'HTTP architecture integration'
    } finally { Pop-Location }
    Write-Host "Integration passed. Evidence: $artifacts"
} finally {
    # Only resources created under this unique test project are removed.
    if ($createdMicro) {
        docker logs $microContainer 2>&1 | Out-File (Join-Path $artifacts 'facial.log')
        docker rm -f $microContainer | Out-Null
    }
    if ($createdDatabase) {
        docker compose -f $compose -p $project down --volumes --remove-orphans
    }
    foreach ($name in $savedEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
    }
}
