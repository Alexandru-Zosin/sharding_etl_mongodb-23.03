$ErrorActionPreference = "Stop"

# cand s-a tras repoul de pe git pe windows, s-a adaugat autoamt \r de Windows si nu merge rulat
# run_synthea din cauza shebangului eronat (cu \r la final)

$repoDir = "$PWD\synthea"

Get-ChildItem -Path $repoDir -Recurse -File -Include *.sh,run_synthea,gradlew | ForEach-Object {
    $content = Get-Content -Raw -LiteralPath $_.FullName
    $content = $content -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($_.FullName, $content, (New-Object System.Text.UTF8Encoding($false)))
}