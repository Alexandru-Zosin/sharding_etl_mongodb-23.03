$repoDir = "$PWD\..\synthea"
$outputDirInRepo = "$repoDir\output\csv"
if (Test-Path $outputDirInRepo) {
    Remove-Item -Recurse -Force $outputDirInRepo
}

# creez un container throwaway caruia ii montez folderul local synthea la opt synthea, apoi intru 
# in opt synthea si rulez bash din acest container temporar JAVA (are nev synthea de el)
# numai pt comanda asta ...  
# cand Synthea gen fisiere in opt/synth/..., ele apar de fapt si pe host in \synth\output\csv (BIND VOLUME)
nerdctl run --rm `
    -v "${repoDir}:/opt/synthea" `
    -w /opt/synthea `
    docker.io/library/eclipse-temurin:17-jdk `
    bash -lc "./run_synthea -p 80"

# -v volume mount (bind mount  x:y )
# -w working directory pt container (echivalent cu cd /opt/synthea)

# exista si ps script in proiect pt run_synthea, dar am vrut sa rulez .bat ul :)

if (-not (Test-Path $outputDirInRepo)) {
    throw "Synthea did not generate output in $outputDirInRepo"
}

# copierea efectiva in container
nerdctl exec pgsql bash -lc "rm -rf /tmp/synthea-csv && mkdir -p /tmp/synthea-csv"
nerdctl cp "$outputDirInRepo\." "pgsql:/tmp/synthea-csv"
nerdctl exec pgsql bash -lc "ls -lah /tmp/synthea-csv"