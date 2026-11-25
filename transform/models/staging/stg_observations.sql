-- One row per observation: vital signs, lab results, survey answers.
-- By far the largest table.

with source as (

    select
        resource_id,
        resource_json as r,
        loaded_at
    from {{ source('raw', 'fhir_resources') }}
    where resource_type = 'Observation'

)

select
    resource_id                                                 as observation_id,
    {{ fhir_ref_id("r ->> '$.subject.reference'") }}            as patient_id,
    {{ fhir_ref_id("r ->> '$.encounter.reference'") }}          as encounter_id,

    r ->> '$.status'                                            as status,
    r ->> '$.category[0].coding[0].code'                        as category,
    r ->> '$.code.coding[0].code'                               as loinc_code,
    r ->> '$.code.coding[0].display'                            as observation_name,

    -- Numeric results (weight, glucose, etc.)
    try_cast(r ->> '$.valueQuantity.value' as double)           as value_numeric,
    r ->> '$.valueQuantity.unit'                                as value_unit,

    -- Coded results (e.g. smoking status: "Never smoked")
    r ->> '$.valueCodeableConcept.unit'                         as value_text,

    cast(r ->> '$.effectiveDateTime' as timestamptz)            as oberved_at,

    loaded_at

from source