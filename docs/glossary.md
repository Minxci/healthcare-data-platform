# Healthcare Data Glossary

Terms used throughout this project, grouped by topic. Updated as the project grows.

---

## Data Standards

| Term | Meaning |
|---|---|
| **FHIR** | Fast Healthcare Interoperability Resources (pronounced "fire"). The modern standard for exchanging healthcare data as JSON. Used by Epic, Oracle Health, and most health tech APIs. |
| **HL7** | Health Level Seven International, the organization that publishes FHIR. Older systems use "HL7 v2" pipe-delimited messages. |
| **Resource** | A single FHIR record, such as a Patient, Encounter, or Observation. Every resource has a `resourceType` and an `id`. |
| **Bundle** | A FHIR container holding many resources. Synthea writes one Bundle per patient. |
| **Reference** | How one resource points to another, e.g. an Encounter's `subject.reference` points to its Patient. Formats vary (`urn:uuid:<id>` in bundles, `Patient/<id>` in APIs). |
| **EHR / EMR** | Electronic Health Record / Electronic Medical Record. The system clinicians use day to day (Epic, Oracle Health/Cerner). |
| **Interoperability** | The ability of different healthcare systems to exchange and use each other's data. The main reason standards like FHIR and LOINC exist. |

## Code Systems

| Term | Meaning | In this project |
|---|---|---|
| **SNOMED CT** | Codes for clinical concepts: conditions, procedures, findings. What the patient **has**. | `stg_conditions.snomed_code`, `stg_encounters.encounter_type_code` |
| **LOINC** | Codes for lab tests and measurements. What was **measured**. Different hospitals name the same test differently; the LOINC code stays the same. | `stg_observations.loinc_code` |
| **RxNorm** | Codes for medications. What the patient **takes**. | MedicationRequest resources |
| **ICD-10** | Diagnosis codes used mainly for billing and reporting. | Not used by Synthea's default output |
| **CPT** | Procedure codes used for billing. | Not used by Synthea's default output |

**Common LOINC codes in this data:**
- `8302-2`: Body height
- `29463-7`: Body weight
- `4548-4`: Hemoglobin A1c (diabetes blood test)
- `85354-9`: Blood pressure panel

## Encounter Classes

| Code | Meaning |
|---|---|
| **AMB** | Ambulatory: outpatient visits (checkups, appointments) |
| **EMER** | Emergency room visit |
| **IMP** | Inpatient: admitted to the hospital |
| **HH** | Home health: care delivered at the patient's home |
| **VR** | Virtual: telehealth |

## FHIR Resource Types

| Resource | Meaning |
|---|---|
| **Patient** | Demographics: name, gender, birth date, address |
| **Encounter** | A visit or interaction with the healthcare system |
| **Condition** | A diagnosis or health problem |
| **Observation** | A measurement: vitals, lab results, survey answers |
| **Procedure** | Something done to the patient (surgery, screening) |
| **MedicationRequest** | A prescription |
| **Immunization** | A vaccine given |
| **AllergyIntolerance** | A recorded allergy |
| **DiagnosticReport** | A grouped set of results, like a lab panel |
| **Claim** | A bill sent to insurance |
| **ExplanationOfBenefit (EOB)** | What insurance paid on a claim |

## Privacy and Compliance

| Term | Meaning |
|---|---|
| **PHI** | Protected Health Information: health data that can be tied to a specific person. |
| **PII** | Personally Identifiable Information: names, addresses, phone numbers, IDs. |
| **HIPAA** | The US law that governs how PHI is stored, shared, and protected. |
| **De-identification** | Removing or masking identifiers so data can be used safely for analytics. |

## Business Terms

| Term | Meaning |
|---|---|
| **Payer** | The insurance company (or government program) that pays for care. |
| **Provider** | The doctor, hospital, or clinic that delivers care. |
| **Clinical status** | Whether a condition is `active` or `resolved`. |

## Data Engineering Terms

| Term | Meaning |
|---|---|
| **ELT** | Extract, Load, Transform. Load raw data first, transform it afterward inside the warehouse (this project's approach). |
| **Raw layer** | Untouched source data (`raw.fhir_resources`). |
| **Staging layer** | Cleaned, renamed, typed tables, one per source entity (`staging.stg_*`). |
| **Idempotent** | Running something once or ten times gives the same result, with no duplicates. |
| **Synthetic data** | Realistic but fake data (from Synthea), so no real patient information is ever used. |
| **Row count reconciliation** | Checking that row totals match between layers, so no data was lost or duplicated. |