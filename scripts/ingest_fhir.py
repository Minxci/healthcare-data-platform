"""
Load Synthea FHIR bundles into DuckDB as raw, untouched JSON.

One row per FHIR resource. Nothing gets cleaned here on purpose:
cleaning happens later in dbt, so the raw layer is always a faithful
copy of what the source system sent us (ELT, not ETL).
"""

import json
from datetime import datetime, timezone
from pathlib import Path

import duckdb
import pandas as pd

# Paths are built from this file's location, so the script works
# no matter which folder you run it from.
PROJECT_ROOT = Path(__file__).resolve().parent.parent
FHIR_DIR = PROJECT_ROOT / "data" / "raw" / "fhir"
DB_PATH = PROJECT_ROOT / "data" / "warehouse.duckdb"


def find_patient_id(bundle: dict) -> str | None:
    """Return the Patient id in this bundle, or None for shared files
    like hospitalInformation and practitionerInformation."""
    for entry in bundle.get("entry", []):
        resource = entry.get("resource", {})
        if resource.get("resourceType") == "Patient":
            return resource.get("id")
    return None


def bundle_to_rows(path: Path, loaded_at: datetime) -> list[dict]:
    """Turn one FHIR Bundle file into a list of rows, one per resource."""
    with path.open(encoding="utf-8") as f:
        bundle = json.load(f)

    patient_id = find_patient_id(bundle)
    rows = []

    for entry in bundle.get("entry", []):
        resource = entry.get("resource")
        if not resource:
            continue
        rows.append(
            {
                "resource_id": resource.get("id"),
                "resource_type": resource.get("resourceType"),
                "patient_id": patient_id,
                "source_file": path.name,
                "resource_json": json.dumps(resource),
                "loaded_at": loaded_at,
            }
        )
    return rows


def main() -> None:
    files = sorted(FHIR_DIR.glob("*.json"))
    if not files:
        raise SystemExit(f"No JSON files found in {FHIR_DIR}. Did Synthea run?")

    print(f"Found {len(files)} bundle files in {FHIR_DIR}")

    con = duckdb.connect(str(DB_PATH))
    con.execute("CREATE SCHEMA IF NOT EXISTS raw")

    # CREATE OR REPLACE rebuilds the table every run (a full refresh).
    # That makes the script idempotent: run it 1 time or 10 times,
    # you get the same result and never duplicate rows.
    con.execute(
        """
        CREATE OR REPLACE TABLE raw.fhir_resources (
            resource_id    VARCHAR,
            resource_type  VARCHAR,
            patient_id     VARCHAR,
            source_file    VARCHAR,
            resource_json  JSON,
            loaded_at      TIMESTAMP
        )
        """
    )

    # One timestamp for the whole run, so every row from this load matches.
    loaded_at = datetime.now(timezone.utc).replace(tzinfo=None)
    total = 0
    failed: list[tuple[str, str]] = []

    for i, path in enumerate(files, start=1):
        try:
            rows = bundle_to_rows(path, loaded_at)
        except (json.JSONDecodeError, UnicodeDecodeError) as e:
            # One bad file shouldn't kill the whole load. Record it and move on.
            failed.append((path.name, str(e)))
            continue

        if rows:
            # Insert one file at a time, so memory stays low even with
            # thousands of patients.
            batch = pd.DataFrame(rows)
            con.register("batch_df", batch)
            con.execute(
                """
                INSERT INTO raw.fhir_resources
                SELECT
                    resource_id,
                    resource_type,
                    patient_id,
                    source_file,
                    CAST(resource_json AS JSON),
                    loaded_at
                FROM batch_df
                """
            )
            con.unregister("batch_df")
            total += len(rows)

        if i % 25 == 0 or i == len(files):
            print(f"  {i}/{len(files)} files loaded, {total:,} resources so far")

    print(f"\nDone. Loaded {total:,} resources into raw.fhir_resources")

    print("\nResources by type:")
    counts = con.execute(
        """
        SELECT resource_type, COUNT(*) AS n
        FROM raw.fhir_resources
        GROUP BY resource_type
        ORDER BY n DESC
        """
    ).fetchall()
    for resource_type, n in counts:
        print(f"  {resource_type:<28} {n:>10,}")

    if failed:
        print(f"\nWARNING: {len(failed)} files failed to parse:")
        for name, err in failed:
            print(f"  {name}: {err}")

    con.close()


if __name__ == "__main__":
    main()