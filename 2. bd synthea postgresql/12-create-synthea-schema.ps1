# Optional manual check after:
# nerdctl exec -it pgsql psql -U postgres -d synthea

$ErrorActionPreference = "Stop"

nerdctl cp .\12-synthea_schema.sql pgsql:/tmp/12-synthea_schema.sql

nerdctl exec pgsql psql -U postgres -d synthea -f /tmp/12-synthea_schema.sql