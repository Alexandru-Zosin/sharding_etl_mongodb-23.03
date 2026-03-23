param(
    [string]$SqlQueryScript = '23-queries-sql.sql'
)

$ErrorActionPreference = 'Stop'

$PgContainer = 'pgsql'

function Invoke-Step {
    param(
        [string]$StepName,
        [scriptblock]$Action
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Host "Starting: $StepName"

    & $Action

    $sw.Stop()
    Write-Host ("Finished: {0} in {1:N2} sec" -f $StepName, $sw.Elapsed.TotalSeconds)
    Write-Host ''
}

$runningContainers = nerdctl ps --format '{{.Names}}'
if (-not ($runningContainers | Select-String "^$PgContainer$")) {
    throw "Container '$PgContainer' is not running."
}

if (-not (Test-Path $SqlQueryScript)) {
    throw "File '$SqlQueryScript' was not found."
}

nerdctl cp $SqlQueryScript "${PgContainer}:/tmp/$SqlQueryScript"

Invoke-Step 'Run SQL queries' {
    nerdctl exec -i $PgContainer psql -U postgres -d synthea -f "/tmp/$SqlQueryScript"
}