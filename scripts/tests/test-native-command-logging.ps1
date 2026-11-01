# Regression for Docker/Java stderr handling under Windows PowerShell 5.1 and PowerShell 7.
# No Docker daemon, application services or database required.
$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot '../test-architecture-e2e.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path -LiteralPath $runner).Path, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'E2E script has PowerShell syntax errors' }
$helper = $ast.Find({ param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Invoke-NativeLogged'
}, $true)
if (-not $helper) { throw 'Native logging helper is missing' }
. ([scriptblock]::Create($helper.Extent.Text))
$artifacts = Join-Path $PSScriptRoot ('../../.tmp/native-logging-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $artifacts -Force | Out-Null
$successLog = Join-Path $artifacts 'success.log'
Invoke-NativeLogged -Executable cmd.exe -NativeArguments @('/d','/c','echo stdout-ok & echo progress-on-stderr 1>&2 & exit /b 0') -LogPath $successLog -Quiet
$output = Get-Content -LiteralPath $successLog -Raw
if ($output -notmatch 'stdout-ok' -or $output -notmatch 'progress-on-stderr') {
    throw 'Both stdout and stderr must be preserved on native success'
}
$failed = $false
try {
    Invoke-NativeLogged -Executable cmd.exe -NativeArguments @('/d','/c','echo genuine-failure 1>&2 & exit /b 7') `
        -LogPath (Join-Path $artifacts 'failure.log') -Quiet
} catch {
    if ($_.Exception.Message -notmatch 'exit code 7') { throw }
    $failed = $true
}
if (-not $failed) { throw 'A nonzero native exit code must fail the runner' }
if ($ErrorActionPreference -ne 'Stop') { throw 'The caller error preference must be preserved' }
Write-Output "PASS: stdout/stderr retained, exit 0 accepted, exit 7 rejected; PowerShell $($PSVersionTable.PSVersion)"
