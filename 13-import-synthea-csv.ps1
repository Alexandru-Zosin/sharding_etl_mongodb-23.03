# Optional manual checks:
# nerdctl exec -it pgsql bash
# ls -lah /opt/synthea/output/csv
# nerdctl exec -it pgsql psql -U postgres -d synthea

$ErrorActionPreference = "Stop"

nerdctl cp .\13-synthea_import.sql pgsql:/tmp/13-synthea_import.sql
nerdctl exec pgsql psql -U postgres -d synthea -f /tmp/13-synthea_import.sql