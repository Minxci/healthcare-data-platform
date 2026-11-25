-- One row per diagnosed condition, coded in SNOMED CT.

with source as (

    select 
        resource_id,
        resource_json as r,
        loaded_at
    from {{ source('raw', 'fhir_resources') }}
    where resource_type = 'Conditions'

)

select
    resource_id                                                         as condition_id,
    {{ fhir_ref_id("r ->> '$.subject.reference'") }}                    as patient_id,
    {{ fhir_ref_id("r ->> '$.encounter.reference'") }}                  as encounter_id,

    r ->> '$.code.coding[0].code'                                       as snomed_code,
    r ->> '$.code.coding[0].display'                                    as condition_code,
    r ->> '$.clinicalStatus.coding[0].code'                             as clinical_status,

    cast(r ->> '$.onsetDateTime' as timestamptz)                        as onset_at,
    cast(r ->> '$.abatementDateTime' as timestamptz)                    as resolved_at,

    loaded_at

from source