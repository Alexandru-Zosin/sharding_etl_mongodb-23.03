# Manual shell from host, if you want:
# nerdctl exec -it pgsql psql -U postgres -d synthea

$ErrorActionPreference = "Stop"

nerdctl exec pgsql psql -U postgres -d synthea -c "\dt"

nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS allergies_count FROM allergies;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS careplans_count FROM careplans;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS claims_count FROM claims;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS conditions_count FROM conditions;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS encounters_count FROM encounters;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS devices_count FROM devices;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS imaging_studies_count FROM imaging_studies;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS immunizations_count FROM immunizations;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS medications_count FROM medications;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS organizations_count FROM organizations;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS observations_count FROM observations;"

nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS payer_transitions_count FROM payer_transitions;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS patients_count FROM patients;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS payers_count FROM payers;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS procedures_count FROM procedures;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS providers_count FROM providers;"
nerdctl exec pgsql psql -U postgres -d synthea -c "SELECT COUNT(*) AS supplies_count FROM supplies;"

nerdctl cp .\14-verify_top_patients.sql pgsql:/tmp/14-verify_top_patients.sql
nerdctl exec pgsql psql -U postgres -d synthea -f /tmp/14-verify_top_patients.sql