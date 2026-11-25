-- One row per encounter (a visit: wellness checkup, ER trip, inpatient stay, etc. )

with source as (

    select
        resource_id,
        resource_json as r,
        loaded_at
    from {{ source('raw', 'fhir_resources') }}
    where resource_type = 'Encounter'

)

select
    resource_id                                                            as encounter_id,
    {{ fhir_ref_id("r ->> '$.subject.reference'") }}                       as patient_id,

    r ->> '$.status'                                                       as status,
    r ->> '$.class.code'                                                   as encounter_class,
    r ->> '$.type[0].coding[0].code'                                       as encounter_type_code,
    r ->> '$.type[0].coding[0].display'                                    as encounter_type,

    cast(r ->> '$.period.start' as timestamptz)                            as started_at,
    cast(r ->> '$.period.end' as timestamptz)                              as ended_at,

    r ->> '$.serviceProvider.display'                                      as provider_organization,

    loaded_at

from source