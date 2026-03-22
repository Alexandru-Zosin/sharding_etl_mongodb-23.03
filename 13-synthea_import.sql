BEGIN;

TRUNCATE TABLE
    claims_transactions,
    claims,
    supplies,
    medications,
    immunizations,
    imaging_studies,
    devices,
    procedures,
    observations,
    careplans,
    allergies,
    conditions,
    payer_transitions,
    encounters,
    providers,
    organizations,
    payers,
    patients
RESTART IDENTITY CASCADE;

COPY patients (
    id,
    birthdate,
    deathdate,
    ssn,
    drivers,
    passport,
    prefix,
    first,
    middle,
    last,
    suffix,
    maiden,
    marital,
    race,
    ethnicity,
    gender,
    birthplace,
    address,
    city,
    state,
    county,
    fips_county_code,
    zip,
    lat,
    lon,
    healthcare_expenses,
    healthcare_coverage,
    income
)
FROM '/tmp/synthea-csv/csv/patients.csv'
WITH (FORMAT csv, HEADER true);

COPY organizations (
    id,
    name,
    address,
    city,
    state,
    zip,
    lat,
    lon,
    phone,
    revenue,
    utilization
)
FROM '/tmp/synthea-csv/csv/organizations.csv'
WITH (FORMAT csv, HEADER true);

COPY payers (
    id,
    name,
    ownership,
    address,
    city,
    state_headquartered,
    zip,
    phone,
    amount_covered,
    amount_uncovered,
    revenue,
    covered_encounters,
    uncovered_encounters,
    covered_medications,
    uncovered_medications,
    covered_procedures,
    uncovered_procedures,
    covered_immunizations,
    uncovered_immunizations,
    unique_customers,
    qols_avg,
    member_months
)
FROM '/tmp/synthea-csv/csv/payers.csv'
WITH (FORMAT csv, HEADER true);

COPY providers (
    id,
    organization,
    name,
    gender,
    speciality,
    address,
    city,
    state,
    zip,
    lat,
    lon,
    encounters,
    procedures
)
FROM '/tmp/synthea-csv/csv/providers.csv'
WITH (FORMAT csv, HEADER true);

COPY encounters (
    id,
    start_ts,
    stop_ts,
    patient,
    organization,
    provider,
    payer,
    encounter_class,
    code,
    description,
    base_encounter_cost,
    total_claim_cost,
    payer_coverage,
    reasoncode,
    reasondescription
)
FROM '/tmp/synthea-csv/csv/encounters.csv'
WITH (FORMAT csv, HEADER true);

COPY payer_transitions (
    patient,
    member_id,
    start_year,
    end_year,
    payer,
    secondary_payer,
    ownership,
    owner_name
)
FROM '/tmp/synthea-csv/csv/payer_transitions.csv'
WITH (FORMAT csv, HEADER true);

COPY conditions (
    start_date,
    stop_date,
    patient,
    encounter,
    system,
    code,
    description
)
FROM '/tmp/synthea-csv/csv/conditions.csv'
WITH (FORMAT csv, HEADER true);

COPY allergies (
    start_date,
    stop_date,
    patient,
    encounter,
    code,
    system,
    description,
    type,
    category,
    reaction1,
    description1,
    severity1,
    reaction2,
    description2,
    severity2
)
FROM '/tmp/synthea-csv/csv/allergies.csv'
WITH (FORMAT csv, HEADER true);

COPY careplans (
    id,
    start_date,
    stop_date,
    patient,
    encounter,
    code,
    description,
    reasoncode,
    reasondescription
)
FROM '/tmp/synthea-csv/csv/careplans.csv'
WITH (FORMAT csv, HEADER true);

COPY observations (
    date_ts,
    patient,
    encounter,
    category,
    code,
    description,
    value,
    units,
    type
)
FROM '/tmp/synthea-csv/csv/observations.csv'
WITH (FORMAT csv, HEADER true);

COPY procedures (
    start_ts,
    stop_ts,
    patient,
    encounter,
    system,
    code,
    description,
    base_cost,
    reasoncode,
    reasondescription
)
FROM '/tmp/synthea-csv/csv/procedures.csv'
WITH (FORMAT csv, HEADER true);

COPY devices (
    start_ts,
    stop_ts,
    patient,
    encounter,
    code,
    description,
    udi
)
FROM '/tmp/synthea-csv/csv/devices.csv'
WITH (FORMAT csv, HEADER true);

COPY imaging_studies (
    id,
    date_ts,
    patient,
    encounter,
    series_uid,
    body_site_code,
    body_site_description,
    modality_code,
    modality_description,
    instance_uid,
    sop_code,
    sop_description,
    procedure_code
)
FROM '/tmp/synthea-csv/csv/imaging_studies.csv'
WITH (FORMAT csv, HEADER true);

COPY immunizations (
    date_ts,
    patient,
    encounter,
    code,
    description,
    cost
)
FROM '/tmp/synthea-csv/csv/immunizations.csv'
WITH (FORMAT csv, HEADER true);

COPY medications (
    start_ts,
    stop_ts,
    patient,
    payer,
    encounter,
    code,
    description,
    base_cost,
    payer_coverage,
    dispenses,
    totalcost,
    reasoncode,
    reasondescription
)
FROM '/tmp/synthea-csv/csv/medications.csv'
WITH (FORMAT csv, HEADER true);

COPY supplies (
    date_date,
    patient,
    encounter,
    code,
    description,
    quantity
)
FROM '/tmp/synthea-csv/csv/supplies.csv'
WITH (FORMAT csv, HEADER true);

COPY claims (
    id,
    patient_id,
    provider_id,
    primary_patient_insurance_id,
    secondary_patient_insurance_id,
    department_id,
    patient_department_id,
    diagnosis1,
    diagnosis2,
    diagnosis3,
    diagnosis4,
    diagnosis5,
    diagnosis6,
    diagnosis7,
    diagnosis8,
    referring_provider_id,
    appointment_id,
    current_illness_date,
    service_date,
    supervising_provider_id,
    status1,
    status2,
    statusp,
    outstanding1,
    outstanding2,
    outstandingp,
    lastbilleddate1,
    lastbilleddate2,
    lastbilleddatep,
    healthcareclaimtypeid1,
    healthcareclaimtypeid2
)
FROM '/tmp/synthea-csv/csv/claims.csv'
WITH (FORMAT csv, HEADER true);

COPY claims_transactions (
    id,
    claim_id,
    charge_id,
    patient_id,
    type,
    amount,
    method,
    from_date,
    to_date,
    place_of_service,
    procedure_code,
    modifier1,
    modifier2,
    diagnosisref1,
    diagnosisref2,
    diagnosisref3,
    diagnosisref4,
    units,
    department_id,
    notes,
    unit_amount,
    transfer_out_id,
    transfer_type,
    payments,
    adjustments,
    transfers,
    outstanding,
    appointment_id,
    line_note,
    patient_insurance_id,
    fee_schedule_id,
    provider_id,
    supervising_provider_id
)
FROM '/tmp/synthea-csv/csv/claims_transactions.csv'
WITH (FORMAT csv, HEADER true);

COMMIT;