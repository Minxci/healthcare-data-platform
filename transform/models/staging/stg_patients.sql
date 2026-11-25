-- One row per patient.
-- Still contains names and addresses (PII). De-identification happens on Day 5.

with source as (

    select
        resource_id,
        resource_json as r,
        loaded_at
    from {{ source('raw', 'fhir_resources') }}
    where resource_type = 'Patient'

)

select
    resource_id                                                         as patient_id,

    -- Synthea appends numnbers to names (e.g "Maria845"), so strip digits
    regexp_replace(r ->> '$.name[0].given[0]', '[0-9]+', '', 'g')       as first_name,
    regexp_replace(r ->> '$.name[0].family', '[0-9]+', '', 'g')         as last_name,

    r ->> '$.gender'                                                    as gender,
    cast(r ->> '$.birthdDate' as date)                                  as birth_date,
    cast(r ->> '$.deceasedDateTIme' as timestamptz)                     as deceased_at,

    r ->> '$.address[0].city'                                           as city,
    r ->> '$.address[0].state'                                          as state,
    r ->> '$.address[0].postalCode'                                     as postal_code,

    loaded_at

from source