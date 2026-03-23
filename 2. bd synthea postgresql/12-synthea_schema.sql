BEGIN;

DROP TABLE IF EXISTS claims_transactions CASCADE;
DROP TABLE IF EXISTS claims CASCADE;
DROP TABLE IF EXISTS supplies CASCADE;
DROP TABLE IF EXISTS medications CASCADE;
DROP TABLE IF EXISTS immunizations CASCADE;
DROP TABLE IF EXISTS imaging_studies CASCADE;
DROP TABLE IF EXISTS devices CASCADE;
DROP TABLE IF EXISTS procedures CASCADE;
DROP TABLE IF EXISTS observations CASCADE;
DROP TABLE IF EXISTS careplans CASCADE;
DROP TABLE IF EXISTS allergies CASCADE;
DROP TABLE IF EXISTS conditions CASCADE;
DROP TABLE IF EXISTS payer_transitions CASCADE;
DROP TABLE IF EXISTS encounters CASCADE;
DROP TABLE IF EXISTS providers CASCADE;
DROP TABLE IF EXISTS organizations CASCADE;
DROP TABLE IF EXISTS payers CASCADE;
DROP TABLE IF EXISTS patients CASCADE;

CREATE TABLE patients (
    id uuid PRIMARY KEY,
    birthdate date NOT NULL,
    deathdate date NULL,
    ssn text NOT NULL,
    drivers text NULL,
    passport text NULL,
    prefix text NULL,
    first text NOT NULL,
    middle text NULL,
    last text NOT NULL,
    suffix text NULL,
    maiden text NULL,
    marital text NULL,
    race text NOT NULL,
    ethnicity text NOT NULL,
    gender text NOT NULL,
    birthplace text NOT NULL,
    address text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    county text NULL,
    fips_county_code text NULL,
    zip text NULL,
    lat numeric NULL,
    lon numeric NULL,
    healthcare_expenses numeric NOT NULL,
    healthcare_coverage numeric NOT NULL,
    income numeric NOT NULL
);

CREATE TABLE organizations (
    id uuid PRIMARY KEY,
    name text NOT NULL,
    address text NOT NULL,
    city text NOT NULL,
    state text NULL,
    zip text NULL,
    lat numeric NULL,
    lon numeric NULL,
    phone text NULL,
    revenue numeric NOT NULL,
    utilization integer NOT NULL
);

CREATE TABLE payers (
    id uuid PRIMARY KEY,
    name text NOT NULL,
    ownership text NULL,
    address text NULL,
    city text NULL,
    state_headquartered text NULL,
    zip text NULL,
    phone text NULL,
    amount_covered numeric NOT NULL,
    amount_uncovered numeric NOT NULL,
    revenue numeric NOT NULL,
    covered_encounters integer NOT NULL,
    uncovered_encounters integer NOT NULL,
    covered_medications integer NOT NULL,
    uncovered_medications integer NOT NULL,
    covered_procedures integer NOT NULL,
    uncovered_procedures integer NOT NULL,
    covered_immunizations integer NOT NULL,
    uncovered_immunizations integer NOT NULL,
    unique_customers integer NOT NULL,
    qols_avg numeric NOT NULL,
    member_months integer NOT NULL
);

CREATE TABLE providers (
    id uuid PRIMARY KEY,
    organization uuid NOT NULL REFERENCES organizations(id),
    name text NOT NULL,
    gender text NOT NULL,
    speciality text NOT NULL,
    address text NOT NULL,
    city text NOT NULL,
    state text NULL,
    zip text NULL,
    lat numeric NULL,
    lon numeric NULL,
    encounters integer NOT NULL,
    procedures integer NOT NULL
);

CREATE TABLE encounters (
    id uuid PRIMARY KEY,
    start_ts timestamptz NOT NULL,
    stop_ts timestamptz NULL,
    patient uuid NOT NULL REFERENCES patients(id),
    organization uuid NOT NULL REFERENCES organizations(id),
    provider uuid NOT NULL REFERENCES providers(id),
    payer uuid NOT NULL REFERENCES payers(id),
    encounter_class text NOT NULL,
    code text NOT NULL,
    description text NOT NULL,
    base_encounter_cost numeric NOT NULL,
    total_claim_cost numeric NOT NULL,
    payer_coverage numeric NOT NULL,
    reasoncode text NULL,
    reasondescription text NULL
);

CREATE TABLE payer_transitions (
    payer_transition_id bigserial PRIMARY KEY,
    patient uuid NOT NULL REFERENCES patients(id),
    member_id uuid NULL,
    start_year timestamptz NOT NULL,
    end_year timestamptz NOT NULL,
    payer uuid NOT NULL REFERENCES payers(id),
    secondary_payer uuid NULL REFERENCES payers(id),
    ownership text NULL,
    owner_name text NULL
);

CREATE TABLE conditions (
    condition_id bigserial PRIMARY KEY,
    start_date date NOT NULL,
    stop_date date NULL,
    patient uuid NOT NULL REFERENCES patients(id),
    encounter uuid NOT NULL REFERENCES encounters(id),
    system text NOT NULL,
    code text NOT NULL,
    description text NOT NULL
);

CREATE TABLE allergies (
    allergy_id bigserial PRIMARY KEY,
    start_date date NOT NULL,
    stop_date date NULL,
    patient uuid NOT NULL REFERENCES patients(id),
    encounter uuid NOT NULL REFERENCES encounters(id),
    code text NOT NULL,
    system text NOT NULL,
    description text NOT NULL,
    type text NULL,
    category text NULL,
    reaction1 text NULL,
    description1 text NULL,
    severity1 text NULL,
    reaction2 text NULL,
    description2 text NULL,
    severity2 text NULL
);

CREATE TABLE careplans (
    id uuid PRIMARY KEY,
    start_date date NOT NULL,
    stop_date date NULL,
    patient uuid NOT NULL REFERENCES patients(id),
    encounter uuid NOT NULL REFERENCES encounters(id),
    code text NOT NULL,
    description text NOT NULL,
    reasoncode text NULL,
    reasondescription text NULL
);

CREATE TABLE observations (
    observation_id bigserial PRIMARY KEY,
    date_ts timestamptz NOT NULL,
    patient uuid NOT NULL REFERENCES patients(id),
    encounter uuid NULL REFERENCES encounters(id),
    category text NULL,
    code text NOT NULL,
    description text NOT NULL,
    value text NOT NULL,
    units text NULL,
    type text NOT NULL
);

CREATE TABLE procedures (
    procedure_id bigserial PRIMARY KEY,
    start_ts timestamptz NOT NULL,
    stop_ts timestamptz NULL,
    patient uuid NOT NULL REFERENCES patients(id),
    encounter uuid NOT NULL REFERENCES encounters(id),
    system text NOT NULL,
    code text NOT NULL,
    description text NOT NULL,
    base_cost numeric NOT NULL,
    reasoncode text NULL,
    reasondescription text NULL
);

CREATE TABLE devices (
    device_id bigserial PRIMARY KEY,
    start_ts timestamptz NOT NULL,
    stop_ts timestamptz NULL,
    patient uuid NOT NULL REFERENCES patients(id),
    encounter uuid NOT NULL REFERENCES encounters(id),
    code text NOT NULL,
    description text NOT NULL,
    udi text NOT NULL UNIQUE
);

CREATE TABLE imaging_studies (
    imaging_study_row_id bigserial PRIMARY KEY,
    id uuid NOT NULL,
    date_ts timestamptz NOT NULL,
    patient uuid NOT NULL REFERENCES patients(id),
    encounter uuid NOT NULL REFERENCES encounters(id),
    series_uid text NOT NULL,
    body_site_code text NOT NULL,
    body_site_description text NOT NULL,
    modality_code text NOT NULL,
    modality_description text NOT NULL,
    instance_uid text NOT NULL,
    sop_code text NOT NULL,
    sop_description text NOT NULL,
    procedure_code text NOT NULL
);

CREATE TABLE immunizations (
    immunization_id bigserial PRIMARY KEY,
    date_ts timestamptz NOT NULL,
    patient uuid NOT NULL REFERENCES patients(id),
    encounter uuid NOT NULL REFERENCES encounters(id),
    code text NOT NULL,
    description text NOT NULL,
    cost numeric NOT NULL
);

CREATE TABLE medications (
    medication_id bigserial PRIMARY KEY,
    start_ts timestamptz NOT NULL,
    stop_ts timestamptz NULL,
    patient uuid NOT NULL REFERENCES patients(id),
    payer uuid NOT NULL REFERENCES payers(id),
    encounter uuid NOT NULL REFERENCES encounters(id),
    code text NOT NULL,
    description text NOT NULL,
    base_cost numeric NOT NULL,
    payer_coverage numeric NOT NULL,
    dispenses integer NOT NULL,
    totalcost numeric NOT NULL,
    reasoncode text NULL,
    reasondescription text NULL
);

CREATE TABLE supplies (
    supply_id bigserial PRIMARY KEY,
    date_date date NOT NULL,
    patient uuid NOT NULL REFERENCES patients(id),
    encounter uuid NOT NULL REFERENCES encounters(id),
    code text NOT NULL,
    description text NOT NULL,
    quantity numeric NOT NULL
);

CREATE TABLE claims (
    id uuid PRIMARY KEY,
    patient_id uuid NOT NULL REFERENCES patients(id),
    provider_id uuid NOT NULL REFERENCES providers(id),
    primary_patient_insurance_id uuid NULL REFERENCES payers(id),
    secondary_patient_insurance_id uuid NULL REFERENCES payers(id),
    department_id numeric NOT NULL,
    patient_department_id numeric NOT NULL,
    diagnosis1 text NULL,
    diagnosis2 text NULL,
    diagnosis3 text NULL,
    diagnosis4 text NULL,
    diagnosis5 text NULL,
    diagnosis6 text NULL,
    diagnosis7 text NULL,
    diagnosis8 text NULL,
    referring_provider_id uuid NULL REFERENCES providers(id),
    appointment_id uuid NULL REFERENCES encounters(id),
    current_illness_date timestamptz NOT NULL,
    service_date timestamptz NOT NULL,
    supervising_provider_id uuid NULL REFERENCES providers(id),
    status1 text NULL,
    status2 text NULL,
    statusp text NULL,
    outstanding1 numeric NULL,
    outstanding2 numeric NULL,
    outstandingp numeric NULL,
    lastbilleddate1 timestamptz NULL,
    lastbilleddate2 timestamptz NULL,
    lastbilleddatep timestamptz NULL,
    healthcareclaimtypeid1 numeric NULL,
    healthcareclaimtypeid2 numeric NULL
);

CREATE TABLE claims_transactions (
    id uuid NOT NULL,
    claim_id uuid NOT NULL REFERENCES claims(id),
    charge_id numeric NOT NULL,
    patient_id uuid NOT NULL REFERENCES patients(id),
    type text NOT NULL,
    amount numeric NULL,
    method text NULL,
    from_date timestamptz NULL,
    to_date timestamptz NULL,
    place_of_service uuid NOT NULL REFERENCES organizations(id),
    procedure_code text NOT NULL,
    modifier1 text NULL,
    modifier2 text NULL,
    diagnosisref1 numeric NULL,
    diagnosisref2 numeric NULL,
    diagnosisref3 numeric NULL,
    diagnosisref4 numeric NULL,
    units numeric NULL,
    department_id numeric NULL,
    notes text NULL,
    unit_amount numeric NULL,
    transfer_out_id numeric NULL,
    transfer_type text NULL,
    payments numeric NULL,
    adjustments numeric NULL,
    transfers numeric NULL,
    outstanding numeric NULL,
    appointment_id uuid NULL REFERENCES encounters(id),
    line_note text NULL,
    patient_insurance_id uuid NULL,
    fee_schedule_id numeric NULL,
    provider_id uuid NOT NULL REFERENCES providers(id),
    supervising_provider_id uuid NULL REFERENCES providers(id),
    PRIMARY KEY (id, claim_id, charge_id, type)
);

CREATE INDEX idx_encounters_patient ON encounters(patient);
CREATE INDEX idx_encounters_provider ON encounters(provider);
CREATE INDEX idx_encounters_org ON encounters(organization);
CREATE INDEX idx_payer_transitions_patient ON payer_transitions(patient);
CREATE INDEX idx_payer_transitions_member_id ON payer_transitions(member_id);
CREATE INDEX idx_conditions_patient ON conditions(patient);
CREATE INDEX idx_conditions_encounter ON conditions(encounter);
CREATE INDEX idx_allergies_patient ON allergies(patient);
CREATE INDEX idx_allergies_encounter ON allergies(encounter);
CREATE INDEX idx_observations_patient ON observations(patient);
CREATE INDEX idx_observations_encounter ON observations(encounter);
CREATE INDEX idx_observations_code ON observations(code);
CREATE INDEX idx_procedures_patient ON procedures(patient);
CREATE INDEX idx_medications_patient ON medications(patient);
CREATE INDEX idx_claims_patient ON claims(patient_id);
CREATE INDEX idx_claims_transactions_claim ON claims_transactions(claim_id);
CREATE INDEX idx_claims_transactions_patient ON claims_transactions(patient_id);
CREATE INDEX idx_claims_transactions_patient_insurance_id ON claims_transactions(patient_insurance_id);

COMMIT;