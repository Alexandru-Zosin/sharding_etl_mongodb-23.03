$ErrorActionPreference = 'Stop'

$MongoContainer = 'mongos'
$InitScript = '20-init-sharding.js'

$runningContainers = nerdctl ps --format '{{.Names}}'
if (-not ($runningContainers | Select-String "^$MongoContainer$")) {
    throw "Container '$MongoContainer' is not running."
}

Write-Host 'Copying init script into mongos:/tmp ...'
nerdctl cp ".\$InitScript" "${MongoContainer}:/tmp/$InitScript"

Write-Host 'Running MongoDB init and sharding script through mongos...'
nerdctl exec -i $MongoContainer mongosh --port 26061 "/tmp/$InitScript"

Write-Host 'Mongo init finished.'