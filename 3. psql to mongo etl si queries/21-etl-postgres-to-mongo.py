import datetime
import decimal
import os
import time
import uuid
from collections import defaultdict
from typing import Any

import psycopg
from pymongo import MongoClient
from pymongo.errors import BulkWriteError


PG_CONNINFO = (
    f"host={os.getenv('PGHOST', 'localhost')} "
    f"port={os.getenv('PGPORT', '5432')} "
    f"dbname={os.getenv('PGDATABASE', 'synthea')} "
    f"user={os.getenv('PGUSER', 'postgres')} "
    f"password={os.getenv('PGPASSWORD', 'postgres')}"
)

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:26061")
MONGO_DB = os.getenv("MONGO_DB", "synthea_mongo")
BATCH_SIZE = max(1, min(int(os.getenv("BATCH_SIZE", "200")), 1000))
DROP_COLLECTIONS = os.getenv("DROP_COLLECTIONS", "1") == "1"
UTC = datetime.timezone.utc

PATIENTS_BASE_SQL = """
SELECT
    p.id,
    p.first,
    p.last,
    p.birthdate,
    p.deathdate,
    p.gender,
    p.race,
    p.ethnicity,
    p.marital,
    p.city,
    p.state,
    p.healthcare_expenses,
    p.healthcare_coverage,
    p.income
FROM patients p
ORDER BY p.id
"""

CONDITIONS_BY_PATIENT_SQL = """
SELECT
    c.patient,
    c.condition_id,
    c.start_date,
    c.stop_date,
    c.encounter,
    c.code,
    c.system,
    c.description
FROM conditions c
WHERE c.patient = ANY(%s::uuid[])
ORDER BY c.patient, c.start_date NULLS LAST, c.condition_id
"""

ALLERGIES_BY_PATIENT_SQL = """
SELECT
    a.patient,
    a.allergy_id,
    a.start_date,
    a.stop_date,
    a.encounter,
    a.code,
    a.system,
    a.description,
    a.type,
    a.category,
    a.reaction1,
    a.severity1
FROM allergies a
WHERE a.patient = ANY(%s::uuid[])
ORDER BY a.patient, a.start_date NULLS LAST, a.allergy_id
"""

ENCOUNTERS_BASE_SQL = """
SELECT
    e.id,
    e.start_ts,
    e.stop_ts,
    e.patient,
    e.provider,
    e.organization,
    e.payer,
    e.encounter_class,
    e.code,
    e.description,
    e.base_encounter_cost,
    e.total_claim_cost,
    e.payer_coverage
FROM encounters e
ORDER BY e.id
"""

OBSERVATIONS_BY_ENCOUNTER_SQL = """
SELECT
    o.encounter,
    o.observation_id,
    o.date_ts,
    o.category,
    o.code,
    o.description,
    o.value,
    o.units,
    o.type
FROM observations o
WHERE o.encounter IS NOT NULL
  AND o.encounter = ANY(%s::uuid[])
ORDER BY o.encounter, o.date_ts NULLS LAST, o.observation_id
"""

PROCEDURES_BY_ENCOUNTER_SQL = """
SELECT
    pr.encounter,
    pr.procedure_id,
    pr.start_ts,
    pr.stop_ts,
    pr.code,
    pr.system,
    pr.description,
    pr.base_cost
FROM procedures pr
WHERE pr.encounter = ANY(%s::uuid[])
ORDER BY pr.encounter, pr.start_ts NULLS LAST, pr.procedure_id
"""

PROVIDERS_SQL = """
SELECT
    p.id,
    p.name,
    p.gender,
    p.speciality,
    p.city,
    p.state,
    p.encounters,
    p.procedures,
    o.id,
    o.name,
    o.city,
    o.state,
    o.zip,
    o.revenue,
    o.utilization
FROM providers p
JOIN organizations o ON o.id = p.organization
ORDER BY p.id
"""

PAYERS_SQL = """
SELECT
    py.id,
    py.name,
    py.city,
    py.state_headquartered,
    py.amount_covered,
    py.amount_uncovered,
    py.revenue,
    py.covered_encounters,
    py.uncovered_encounters,
    py.covered_medications,
    py.uncovered_medications,
    py.covered_procedures,
    py.uncovered_procedures,
    py.unique_customers,
    py.member_months
FROM payers py
ORDER BY py.id
"""


def log(message: str) -> None:
    print(message, flush=True)


def as_utc_datetime(value: datetime.date) -> datetime.datetime:
    return datetime.datetime.combine(
        value,
        datetime.time.min,
    ).replace(tzinfo=UTC)


def normalize_value(value: Any) -> Any:
    if isinstance(value, decimal.Decimal):
        return float(value)

    if isinstance(value, uuid.UUID):
        return str(value)

    if isinstance(value, datetime.datetime):
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)

    if isinstance(value, datetime.date):
        return as_utc_datetime(value)

    if isinstance(value, list):
        return [normalize_value(item) for item in value]

    if isinstance(value, dict):
        return {
            key: normalize_value(item)
            for key, item in value.items()
        }

    return value


def insert_batch(collection, documents: list[dict[str, Any]]) -> int:
    if not documents:
        return 0

    try:
        result = collection.insert_many(documents, ordered=False)
        return len(result.inserted_ids)
    except BulkWriteError as exc:
        details = exc.details or {}
        errors = details.get("writeErrors", [])
        return len(documents) - len(errors)


def fetch_grouped_rows(
    lookup_connection: psycopg.Connection,
    sql: str,
    ids: list[Any],
    parent_key_index: int,
    build_item,
) -> dict[Any, list[dict[str, Any]]]:
    grouped: dict[Any, list[dict[str, Any]]] = defaultdict(list)

    if not ids:
        return grouped

    with lookup_connection.cursor() as cursor:
        cursor.execute(sql, (ids,))
        for row in cursor:
            grouped[row[parent_key_index]].append(build_item(row))

    return grouped


def load_patients(
    stream_connection: psycopg.Connection,
    lookup_connection: psycopg.Connection,
    collection,
    batch_size: int,
) -> int:
    inserted_total = 0
    batch_no = 0

    with stream_connection.cursor(name="cur_patients") as cursor:
        cursor.itersize = batch_size
        cursor.execute(PATIENTS_BASE_SQL)

        while True:
            rows = cursor.fetchmany(batch_size)
            if not rows:
                break

            batch_no += 1
            patient_ids = [row[0] for row in rows]

            conditions = fetch_grouped_rows(
                lookup_connection=lookup_connection,
                sql=CONDITIONS_BY_PATIENT_SQL,
                ids=patient_ids,
                parent_key_index=0,
                build_item=lambda row: {
                    "condition_id": normalize_value(row[1]),
                    "start_date": normalize_value(row[2]),
                    "stop_date": normalize_value(row[3]),
                    "encounter_id": normalize_value(row[4]),
                    "code": normalize_value(row[5]),
                    "system": normalize_value(row[6]),
                    "description": normalize_value(row[7]),
                },
            )

            allergies = fetch_grouped_rows(
                lookup_connection=lookup_connection,
                sql=ALLERGIES_BY_PATIENT_SQL,
                ids=patient_ids,
                parent_key_index=0,
                build_item=lambda row: {
                    "allergy_id": normalize_value(row[1]),
                    "start_date": normalize_value(row[2]),
                    "stop_date": normalize_value(row[3]),
                    "encounter_id": normalize_value(row[4]),
                    "code": normalize_value(row[5]),
                    "system": normalize_value(row[6]),
                    "description": normalize_value(row[7]),
                    "type": normalize_value(row[8]),
                    "category": normalize_value(row[9]),
                    "reaction1": normalize_value(row[10]),
                    "severity1": normalize_value(row[11]),
                },
            )

            documents = []
            for row in rows:
                patient_id = row[0]
                documents.append(
                    {
                        "patient_id": normalize_value(patient_id),
                        "first": normalize_value(row[1]),
                        "last": normalize_value(row[2]),
                        "birthdate": normalize_value(row[3]),
                        "deathdate": normalize_value(row[4]),
                        "gender": normalize_value(row[5]),
                        "race": normalize_value(row[6]),
                        "ethnicity": normalize_value(row[7]),
                        "marital": normalize_value(row[8]),
                        "city": normalize_value(row[9]),
                        "state": normalize_value(row[10]),
                        "healthcare_expenses": normalize_value(row[11]),
                        "healthcare_coverage": normalize_value(row[12]),
                        "income": normalize_value(row[13]),
                        "conditions": conditions.get(patient_id, []),
                        "allergies": allergies.get(patient_id, []),
                    }
                )

            inserted_total += insert_batch(collection, documents)
            log(f"conditions_allergies_patient batch {batch_no}: {inserted_total}")

    return inserted_total


def load_encounters(
    stream_connection: psycopg.Connection,
    lookup_connection: psycopg.Connection,
    collection,
    batch_size: int,
) -> int:
    inserted_total = 0
    batch_no = 0

    with stream_connection.cursor(name="cur_encounters") as cursor:
        cursor.itersize = batch_size
        cursor.execute(ENCOUNTERS_BASE_SQL)

        while True:
            rows = cursor.fetchmany(batch_size)
            if not rows:
                break

            batch_no += 1
            encounter_ids = [row[0] for row in rows]

            observations = fetch_grouped_rows(
                lookup_connection=lookup_connection,
                sql=OBSERVATIONS_BY_ENCOUNTER_SQL,
                ids=encounter_ids,
                parent_key_index=0,
                build_item=lambda row: {
                    "observation_id": normalize_value(row[1]),
                    "date_ts": normalize_value(row[2]),
                    "category": normalize_value(row[3]),
                    "code": normalize_value(row[4]),
                    "description": normalize_value(row[5]),
                    "value": normalize_value(row[6]),
                    "units": normalize_value(row[7]),
                    "type": normalize_value(row[8]),
                },
            )

            procedures = fetch_grouped_rows(
                lookup_connection=lookup_connection,
                sql=PROCEDURES_BY_ENCOUNTER_SQL,
                ids=encounter_ids,
                parent_key_index=0,
                build_item=lambda row: {
                    "procedure_id": normalize_value(row[1]),
                    "start_ts": normalize_value(row[2]),
                    "stop_ts": normalize_value(row[3]),
                    "code": normalize_value(row[4]),
                    "system": normalize_value(row[5]),
                    "description": normalize_value(row[6]),
                    "base_cost": normalize_value(row[7]),
                },
            )

            documents = []
            for row in rows:
                encounter_id = row[0]
                documents.append(
                    {
                        "encounter_id": normalize_value(encounter_id),
                        "start_ts": normalize_value(row[1]),
                        "stop_ts": normalize_value(row[2]),
                        "patient_id": normalize_value(row[3]),
                        "provider_id": normalize_value(row[4]),
                        "organization_id": normalize_value(row[5]),
                        "payer_id": normalize_value(row[6]),
                        "encounter_class": normalize_value(row[7]),
                        "code": normalize_value(row[8]),
                        "description": normalize_value(row[9]),
                        "base_encounter_cost": normalize_value(row[10]),
                        "total_claim_cost": normalize_value(row[11]),
                        "payer_coverage": normalize_value(row[12]),
                        "observations": observations.get(encounter_id, []),
                        "procedures": procedures.get(encounter_id, []),
                    }
                )

            inserted_total += insert_batch(collection, documents)
            log(f"observations_procedures_encounter batch {batch_no}: {inserted_total}")

    return inserted_total


def load_simple_stream(
    stream_connection: psycopg.Connection,
    collection,
    sql: str,
    cursor_name: str,
    batch_size: int,
    build_document,
    label: str,
) -> int:
    inserted_total = 0
    batch_no = 0

    with stream_connection.cursor(name=cursor_name) as cursor:
        cursor.itersize = batch_size
        cursor.execute(sql)

        while True:
            rows = cursor.fetchmany(batch_size)
            if not rows:
                break

            batch_no += 1
            documents = [build_document(row) for row in rows]
            inserted_total += insert_batch(collection, documents)
            log(f"{label} batch {batch_no}: {inserted_total}")

    return inserted_total


def main() -> int:
    start_time = time.time()
    stream_connection = None
    lookup_connection = None
    mongo_client = None

    try:
        stream_connection = psycopg.connect(PG_CONNINFO)
        lookup_connection = psycopg.connect(PG_CONNINFO)
        lookup_connection.autocommit = True

        mongo_client = MongoClient(
            MONGO_URI,
            appname="synthea-etl",
            retryWrites=False,
        )
        db = mongo_client[MONGO_DB]

        if DROP_COLLECTIONS:
            db["conditions_allergies_patient"].delete_many({})
            db["observations_procedures_encounter"].delete_many({})
            db["organizations_provider"].delete_many({})
            db["payer"].delete_many({})
            db["observations_procedures_medications_encounter"].drop()

        total_patients = load_patients(
            stream_connection=stream_connection,
            lookup_connection=lookup_connection,
            collection=db["conditions_allergies_patient"],
            batch_size=BATCH_SIZE,
        )
        log(f"conditions_allergies_patient done: {total_patients}")

        total_encounters = load_encounters(
            stream_connection=stream_connection,
            lookup_connection=lookup_connection,
            collection=db["observations_procedures_encounter"],
            batch_size=BATCH_SIZE,
        )
        log(f"observations_procedures_encounter done: {total_encounters}")

        total_providers = load_simple_stream(
            stream_connection=stream_connection,
            collection=db["organizations_provider"],
            sql=PROVIDERS_SQL,
            cursor_name="cur_providers",
            batch_size=BATCH_SIZE,
            label="organizations_provider",
            build_document=lambda row: {
                "provider_id": normalize_value(row[0]),
                "name": normalize_value(row[1]),
                "gender": normalize_value(row[2]),
                "speciality": normalize_value(row[3]),
                "city": normalize_value(row[4]),
                "state": normalize_value(row[5]),
                "encounters": normalize_value(row[6]),
                "procedures": normalize_value(row[7]),
                "organization": {
                    "id": normalize_value(row[8]),
                    "name": normalize_value(row[9]),
                    "city": normalize_value(row[10]),
                    "state": normalize_value(row[11]),
                    "zip": normalize_value(row[12]),
                    "revenue": normalize_value(row[13]),
                    "utilization": normalize_value(row[14]),
                },
            },
        )
        log(f"organizations_provider done: {total_providers}")

        total_payers = load_simple_stream(
            stream_connection=stream_connection,
            collection=db["payer"],
            sql=PAYERS_SQL,
            cursor_name="cur_payers",
            batch_size=BATCH_SIZE,
            label="payer",
            build_document=lambda row: {
                "payer_id": normalize_value(row[0]),
                "name": normalize_value(row[1]),
                "city": normalize_value(row[2]),
                "state_headquartered": normalize_value(row[3]),
                "amount_covered": normalize_value(row[4]),
                "amount_uncovered": normalize_value(row[5]),
                "revenue": normalize_value(row[6]),
                "covered_encounters": normalize_value(row[7]),
                "uncovered_encounters": normalize_value(row[8]),
                "covered_medications": normalize_value(row[9]),
                "uncovered_medications": normalize_value(row[10]),
                "covered_procedures": normalize_value(row[11]),
                "uncovered_procedures": normalize_value(row[12]),
                "unique_customers": normalize_value(row[13]),
                "member_months": normalize_value(row[14]),
            },
        )
        log(f"payer done: {total_payers}")

        elapsed = time.time() - start_time
        log(f"elapsed_seconds: {elapsed:.2f}")
        return 0

    except Exception as exc:
        log(f"etl_failed: {exc}")
        return 1

    finally:
        if stream_connection is not None:
            try:
                stream_connection.close()
            except Exception:
                pass

        if lookup_connection is not None:
            try:
                lookup_connection.close()
            except Exception:
                pass

        if mongo_client is not None:
            try:
                mongo_client.close()
            except Exception:
                pass


if __name__ == "__main__":
    raise SystemExit(main())