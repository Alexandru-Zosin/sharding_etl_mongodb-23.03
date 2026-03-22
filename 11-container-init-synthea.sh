set -e

if [ ! -d /opt/synthea ]; then
  git clone https://github.com/synthetichealth/synthea.git /opt/synthea
fi

cd /opt/synthea

sed -i "s/^exporter.csv.export *= *.*/exporter.csv.export = true/" src/main/resources/synthea.properties
sed -i "s/^exporter.csv.folder_per_run *= *.*/exporter.csv.folder_per_run = false/" src/main/resources/synthea.properties

./run_synthea -p 1000

echo "CSV files:"
ls -lah /opt/synthea/output/csv