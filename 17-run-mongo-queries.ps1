$ErrorActionPreference = 'Stop'

$MongoContainer = 'mongos'
$MongoQueryScript = '22-queries-mongo.js'
$MongoDatabase = 'synthea_mongo'

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
if (-not ($runningContainers | Select-String "^$MongoContainer$")) {
    throw "Container '$MongoContainer' is not running."
}

if (-not (Test-Path $MongoQueryScript)) {
    throw "File '$MongoQueryScript' was not found."
}

nerdctl cp ".\$MongoQueryScript" "${MongoContainer}:/tmp/$MongoQueryScript"

Invoke-Step 'Run MongoDB queries' {
    nerdctl exec -i $MongoContainer mongosh --port 26061 $MongoDatabase "/tmp/$MongoQueryScript"
}