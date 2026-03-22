$ErrorActionPreference = 'Stop'

$MongoContainer = 'mongos'
$PgContainer = 'pgsql'
$EtlContainer = 'synthea-etl'
$DockerNetwork = 'synthea-cluster_synthea-net'

$EtlScript = '21-etl-postgres-to-mongo.py'
$RequirementsFile = 'py-requirements.txt'

Write-Host 'Checking required containers...'
$runningContainers = nerdctl ps --format '{{.Names}}'
if (-not ($runningContainers | Select-String "^$MongoContainer$")) {
    throw "Container '$MongoContainer' is not running."
}
if (-not ($runningContainers | Select-String "^$PgContainer$")) {
    throw "Container '$PgContainer' is not running."
}

Write-Host 'Removing old ETL helper container if it exists...'
try {
    nerdctl rm -f $EtlContainer | Out-Null
} catch {
}

Write-Host 'Creating temporary Python ETL container on Docker network...'
nerdctl run -d --name $EtlContainer --network $DockerNetwork python:3.12-slim sleep infinity | Out-Null

try {
    Write-Host 'Copying ETL files into temporary container:/tmp ...'
    nerdctl cp ".\$RequirementsFile" "${EtlContainer}:/tmp/$RequirementsFile"
    nerdctl cp ".\$EtlScript" "${EtlContainer}:/tmp/$EtlScript"

    Write-Host 'Installing Python dependencies in ETL container...'
    nerdctl exec -i $EtlContainer python -m pip install --no-cache-dir -r "/tmp/$RequirementsFile"

    Write-Host 'Running ETL from pgsql -> mongos ...'
    nerdctl exec -i `
        -e PGHOST=pgsql `
        -e PGPORT=5432 `
        -e PGDATABASE=synthea `
        -e PGUSER=postgres `
        -e PGPASSWORD=postgres `
        -e MONGO_URI=mongodb://mongos:26061 `
        -e MONGO_DB=synthea_mongo `
        -e BATCH_SIZE=1000 `
        $EtlContainer python "/tmp/$EtlScript"

    Write-Host 'ETL finished.'
}
finally {
    Write-Host 'Cleaning up temporary ETL container...'
    try {
        nerdctl rm -f $EtlContainer | Out-Null
    } catch { }
}