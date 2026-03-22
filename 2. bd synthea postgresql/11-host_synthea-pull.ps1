$ErrorActionPreference = "Stop"

$repoDir = "$PWD\synthea"
if (-not (Test-Path $repoDir)) {
    git clone https://github.com/synthetichealth/synthea.git $repoDir
} else {
    git -C $repoDir pull --ff-only
}

$propsFile = "$repoDir\src\main\resources\synthea.properties"
$props = Get-Content $propsFile

$props = $props `
    -replace '^exporter\.csv\.export\s*=.*$', 'exporter.csv.export = true' `
    -replace '^exporter\.csv\.folder_per_run\s*=.*$', 'exporter.csv.folder_per_run = false'

Set-Content -Path $propsFile -Value $props