param(
    [string]$ChangesetId,

    [string]$Author,

    [string]$ProjectName = "facelit-docker-compose",

    [string]$DbUser = "facelit_user",

    [string]$DbName = "facelit-db",

    [switch]$Execute,

    [switch]$PreviewOnly,

    [switch]$AllowCascade
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

function Invoke-PsqlScalar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Sql,
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,
        [Parameter(Mandatory = $true)]
        [string]$DbUser,
        [Parameter(Mandatory = $true)]
        [string]$DbName
    )

    $result = docker compose -p $ProjectName exec -T postgres psql -U $DbUser -d $DbName -At -c $Sql
    if ($null -eq $result) {
        throw "No output returned from psql. Check database connection and parameters."
    }
    return $result.Trim()
}

function Escape-SqlLiteral {
    param([Parameter(Mandatory = $true)][string]$Text)
    return $Text.Replace("'", "''")
}

function Confirm-Yes {
    param([Parameter(Mandatory = $true)][string]$Prompt)
    $answer = (Read-Host $Prompt).Trim().ToLowerInvariant()
    return $answer -in @("y", "yes", "s", "si")
}

function Get-RollbackCountSqlLines {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Count,
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $tmpDir = Join-Path $RepoRoot ".tmp"
    if (-not (Test-Path $tmpDir)) {
        New-Item -ItemType Directory -Path $tmpDir | Out-Null
    }

    $tmpFile = Join-Path $tmpDir ("rollback-count-{0}.sql" -f [Guid]::NewGuid().ToString("N"))
    $relativePath = $tmpFile.Substring($RepoRoot.Length).TrimStart('\', '/').Replace('\', '/')

    try {
        $previousErrorAction = $ErrorActionPreference
        $runExitCode = 0
        $ErrorActionPreference = "Continue"
        try {
            docker compose -p $ProjectName --profile tooling run --rm -T liquibase --show-banner=false --log-level=SEVERE --output-file=$relativePath rollback-count-sql --count=$Count 2>$null | Out-Null
            $runExitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousErrorAction
        }

        if ($runExitCode -ne 0) {
            throw "Failed to generate rollback SQL (exit code $runExitCode)."
        }

        if (-not (Test-Path $tmpFile)) {
            throw "Could not generate rollback SQL output file."
        }
        return @(Get-Content $tmpFile | ForEach-Object { $_.ToString() })
    }
    finally {
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    }
}

function Extract-RollbackBlockForChangeset {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$SqlLines,
        [Parameter(Mandatory = $true)]
        [string]$ChangesetId,
        [Parameter(Mandatory = $true)]
        [string]$Author
    )

    $idRegex = [Regex]::Escape($ChangesetId)
    $authorRegex = [Regex]::Escape($Author)
    $startPattern = "^-- Rolling Back ChangeSet: .*::${idRegex}::${authorRegex}\s*$"
    $startIndex = -1

    for ($i = 0; $i -lt $SqlLines.Count; $i++) {
        if ($SqlLines[$i] -match $startPattern) {
            $startIndex = $i
            break
        }
    }

    if ($startIndex -lt 0) {
        throw "Could not find rollback block for changeset '$ChangesetId' and author '$Author'."
    }

    $endIndex = $SqlLines.Count
    for ($i = $startIndex + 1; $i -lt $SqlLines.Count; $i++) {
        if ($SqlLines[$i] -match "^-- Rolling Back ChangeSet:" -or $SqlLines[$i] -match "^-- Release Database Lock") {
            $endIndex = $i
            break
        }
    }

    $block = $SqlLines[$startIndex..($endIndex - 1)]
    return ($block -join "`n").Trim()
}

function Invoke-LiquibaseExecuteSqlText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SqlText,
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$FilePrefix
    )

    $tmpDir = Join-Path $RepoRoot ".tmp"
    if (-not (Test-Path $tmpDir)) {
        New-Item -ItemType Directory -Path $tmpDir | Out-Null
    }

    $tmpFile = Join-Path $tmpDir ("{0}-{1}.sql" -f $FilePrefix, [Guid]::NewGuid().ToString("N"))
    Set-Content -Path $tmpFile -Value $SqlText -Encoding UTF8

    $relativePath = $tmpFile.Substring($RepoRoot.Length).TrimStart('\', '/').Replace('\', '/')

    try {
        $previousErrorAction = $ErrorActionPreference
        $runExitCode = 0
        $ErrorActionPreference = "Continue"
        try {
            docker compose -p $ProjectName --profile tooling run --rm -T liquibase --show-banner=false --log-level=SEVERE execute-sql --sql-file=$relativePath 2>$null | Out-Null
            $runExitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousErrorAction
        }

        if ($runExitCode -ne 0) {
            throw "Liquibase execute-sql failed (exit code $runExitCode)."
        }
    }
    finally {
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    }
}

function Test-IsolatedRollbackSafety {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RollbackSqlText,
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $restricted = $RollbackSqlText -replace "(?im)\bCASCADE\b", "RESTRICT"
    $precheckSql = "BEGIN;`n$restricted`nROLLBACK;"

    Invoke-LiquibaseExecuteSqlText -SqlText $precheckSql -ProjectName $ProjectName -RepoRoot $RepoRoot -FilePrefix "rollback-precheck"
}

if ($Execute -and $PreviewOnly) {
    throw "Use either -Execute or -PreviewOnly, not both."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    if ([string]::IsNullOrWhiteSpace($ChangesetId)) {
        $ChangesetId = Read-Host "Enter changeset id (example: facelit-model-security)"
    }

    if ([string]::IsNullOrWhiteSpace($ChangesetId)) {
        throw "Changeset id is required."
    }

    $idEscaped = Escape-SqlLiteral -Text $ChangesetId
    $where = "id = '$idEscaped'"

    if ($Author) {
        $authorEscaped = Escape-SqlLiteral -Text $Author
        $where = "$where AND author = '$authorEscaped'"
    }

    $matchCount = [int](Invoke-PsqlScalar -Sql "SELECT COUNT(*) FROM public.databasechangelog WHERE $where;" -ProjectName $ProjectName -DbUser $DbUser -DbName $DbName)

    if ($matchCount -eq 0) {
        $authorText = ""
        if ($Author) {
            $authorText = ", author '$Author'"
        }
        throw "No deployed changeset found with id '$ChangesetId'$authorText."
    }

    if (-not $Author) {
        $authorCount = [int](Invoke-PsqlScalar -Sql "SELECT COUNT(DISTINCT author) FROM public.databasechangelog WHERE id = '$idEscaped';" -ProjectName $ProjectName -DbUser $DbUser -DbName $DbName)
        if ($authorCount -gt 1) {
            $matches = docker compose -p $ProjectName exec -T postgres psql -U $DbUser -d $DbName -c "SELECT id, author, filename, orderexecuted FROM public.databasechangelog WHERE id = '$idEscaped' ORDER BY orderexecuted;"
            throw "Multiple authors found for id '$ChangesetId'. Re-run with -Author.`n$matches"
        }
    }

    $resolvedAuthor = $Author
    if (-not $resolvedAuthor) {
        $resolvedAuthor = Invoke-PsqlScalar -Sql "SELECT author FROM public.databasechangelog WHERE id = '$idEscaped' ORDER BY orderexecuted DESC LIMIT 1;" -ProjectName $ProjectName -DbUser $DbUser -DbName $DbName
    }

    $targetOrder = [int](Invoke-PsqlScalar -Sql "SELECT MAX(orderexecuted) FROM public.databasechangelog WHERE $where;" -ProjectName $ProjectName -DbUser $DbUser -DbName $DbName)
    $maxOrder = [int](Invoke-PsqlScalar -Sql "SELECT COALESCE(MAX(orderexecuted), 0) FROM public.databasechangelog;" -ProjectName $ProjectName -DbUser $DbUser -DbName $DbName)

    $count = $maxOrder - $targetOrder + 1

    if ($count -le 0) {
        throw "Calculated rollback count is $count. Nothing to rollback."
    }

    Write-Host "Target changeset order: $targetOrder"
    Write-Host "Last executed order:    $maxOrder"
    Write-Host "Rollback count:         $count"

    if ($targetOrder -lt $maxOrder -and -not $AllowCascade) {
        Write-Host ""
        Write-Host "Detected non-latest changeset. Switching to isolated rollback mode."

        $allRollbackSqlLines = Get-RollbackCountSqlLines -Count $count -ProjectName $ProjectName -RepoRoot $repoRoot
        $isolatedRollbackSql = Extract-RollbackBlockForChangeset -SqlLines $allRollbackSqlLines -ChangesetId $ChangesetId -Author $resolvedAuthor

        Write-Host ""
        Write-Host "Isolated rollback SQL preview:"
        Write-Host $isolatedRollbackSql

        Write-Host ""
        Write-Host "Running dependency safety check (RESTRICT mode)..."
        try {
            Test-IsolatedRollbackSafety -RollbackSqlText $isolatedRollbackSql -ProjectName $ProjectName -RepoRoot $repoRoot
            Write-Host "Safety check passed. No downstream DB dependency would be dropped."
        }
        catch {
            throw @"
Isolated rollback rejected because dependencies were detected.
This protected later changesets from being dropped implicitly.

If you want to rollback everything from this point upward, re-run with -AllowCascade.
"@
        }

        $shouldExecute = $Execute
        if (-not $Execute -and -not $PreviewOnly) {
            Write-Host ""
            $shouldExecute = Confirm-Yes -Prompt "Execute isolated rollback now? (Y/N)"
        }

        if ($shouldExecute) {
            Write-Host ""
            Write-Host "Executing isolated rollback for '$ChangesetId' ..."
            Invoke-LiquibaseExecuteSqlText -SqlText $isolatedRollbackSql -ProjectName $ProjectName -RepoRoot $repoRoot -FilePrefix "rollback-isolated"
            Write-Host ""
            Write-Host "Isolated rollback executed."
            Write-Host "Later changesets were preserved."
            Write-Host "To re-apply the rolled-back changeset, run:"
            Write-Host "powershell -ExecutionPolicy Bypass -File .\scripts\reapply-after-rollback.ps1 -OnlyNext -AutoConfirm"
        } else {
            Write-Host ""
            Write-Host "Preview only. No rollback executed."
        }
    } else {
        Write-Host ""
        Write-Host "Preview SQL:"
        $previewLines = Get-RollbackCountSqlLines -Count $count -ProjectName $ProjectName -RepoRoot $repoRoot
        Write-Host ($previewLines -join "`n")

        $shouldExecute = $Execute
        if (-not $Execute -and -not $PreviewOnly) {
            Write-Host ""
            $shouldExecute = Confirm-Yes -Prompt "Execute rollback now? (Y/N)"
        }

        if ($shouldExecute) {
            Write-Host ""
            Write-Host "Executing rollback-count --count=$count ..."
            docker compose -p $ProjectName --profile tooling run --rm -T liquibase rollback-count --count=$count
            Write-Host ""
            Write-Host "Rollback executed."
            Write-Host "To re-apply pending changes run:"
            Write-Host "powershell -ExecutionPolicy Bypass -File .\scripts\reapply-after-rollback.ps1"
        } else {
            Write-Host ""
            Write-Host "Preview only. No rollback executed."
        }
    }
}
finally {
    Pop-Location
}
