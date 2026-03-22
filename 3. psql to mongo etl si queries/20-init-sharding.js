const dbName = 'synthea_mongo';
const mainColl = 'observations_procedures_encounter';

const dbRef = db.getSiblingDB(dbName);

print('Using database: ' + dbName);

dbRef.conditions_allergies_patient.deleteMany({});
dbRef.organizations_provider.deleteMany({});
dbRef.payer.deleteMany({});
dbRef[mainColl].deleteMany({});
dbRef.observations_procedures_medications_encounter.drop();

try {
  sh.enableSharding(dbName);
} catch (e) {
  print('enableSharding skipped: ' + e.message);
}

dbRef[mainColl].createIndex({ encounter_id: 'hashed' });

try {
  sh.shardCollection(dbName + '.' + mainColl, { encounter_id: 'hashed' });
} catch (e) {
  print('shardCollection skipped: ' + e.message);
}

dbRef.conditions_allergies_patient.createIndex({ patient_id: 1 }, { unique: true });
dbRef.conditions_allergies_patient.createIndex({ birthdate: 1 });
dbRef.conditions_allergies_patient.createIndex({ deathdate: 1 });
dbRef.conditions_allergies_patient.createIndex({ 'conditions.code': 1 });
dbRef.conditions_allergies_patient.createIndex({ 'conditions.start_date': 1 });
dbRef.conditions_allergies_patient.createIndex({ 'allergies.code': 1 });
dbRef.conditions_allergies_patient.createIndex({ 'allergies.start_date': 1 });

dbRef[mainColl].createIndex({ patient_id: 1 });
dbRef[mainColl].createIndex({ provider_id: 1 });
dbRef[mainColl].createIndex({ organization_id: 1 });
dbRef[mainColl].createIndex({ payer_id: 1 });
dbRef[mainColl].createIndex({ start_ts: 1 });
dbRef[mainColl].createIndex({ stop_ts: 1 });
dbRef[mainColl].createIndex({ 'observations.code': 1 });
dbRef[mainColl].createIndex({ 'observations.date_ts': 1 });
dbRef[mainColl].createIndex({ 'procedures.code': 1 });
dbRef[mainColl].createIndex({ 'procedures.start_ts': 1 });

dbRef.organizations_provider.createIndex({ provider_id: 1 }, { unique: true });
dbRef.organizations_provider.createIndex({ speciality: 1 });
dbRef.organizations_provider.createIndex({ 'organization.id': 1 });

dbRef.payer.createIndex({ payer_id: 1 }, { unique: true });
dbRef.payer.createIndex({ name: 1 });

print('Ready for ETL load');