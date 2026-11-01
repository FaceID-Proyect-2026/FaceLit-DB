$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\Restore-ProcessEnvironment.ps1')

$wrappers = @(
    (Join-Path $PSScriptRoot '..\test-coordinator-bootstrap.ps1'),
    (Join-Path $PSScriptRoot '..\test-architecture-e2e.ps1')
)
foreach ($wrapper in $wrappers) {
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($wrapper, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) { throw "PowerShell syntax errors in $wrapper." }
    $cleanupFinally = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.TryStatementAst] -and
            $null -ne $node.Finally -and $node.Finally.Extent.Text -match 'Restore-ProcessEnvironment'
    }, $true)
    if ($cleanupFinally.Count -eq 0) { throw "$wrapper does not restore variables from its finally block." }
}

$keys = @('FACELIT_TEST_RESTORE_ABSENT', 'FACELIT_TEST_RESTORE_EXISTING')
$original = @{}
foreach ($key in $keys) { $original[$key] = [Environment]::GetEnvironmentVariable($key, 'Process') }

try {
    foreach ($scenario in @('success', 'error')) {
        [Environment]::SetEnvironmentVariable($keys[0], [NullString]::Value, 'Process')
        [Environment]::SetEnvironmentVariable($keys[1], 'original-value', 'Process')
        $snapshot = @{}
        foreach ($key in $keys) { $snapshot[$key] = [Environment]::GetEnvironmentVariable($key, 'Process') }

        try {
            [Environment]::SetEnvironmentVariable($keys[0], 'temporary-value', 'Process')
            [Environment]::SetEnvironmentVariable($keys[1], 'temporary-value', 'Process')
            if ($scenario -eq 'error') { throw 'synthetic script failure' }
        } catch {
            if ($scenario -ne 'error' -or $_.Exception.Message -ne 'synthetic script failure') { throw }
        } finally {
            Restore-ProcessEnvironment -Snapshot $snapshot
        }

        foreach ($key in $keys) {
            $actual = [Environment]::GetEnvironmentVariable($key, 'Process')
            if ($actual -cne $snapshot[$key]) { throw "Environment restoration failed for $key in the $scenario path." }
        }
    }
    'PASS: DB scripts restore process variables on success and error, for absent and pre-existing variables.'
} finally {
    Restore-ProcessEnvironment -Snapshot $original
}
