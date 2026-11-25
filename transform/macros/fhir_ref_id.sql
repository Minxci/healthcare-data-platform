{#
    FHIR reference point to other resources in different formats:
        Synthea bundles: "urn:uuid:8f3a2c1e-..."
        FHIR REST APIs: "Patient/8f3a2c1e-..."
    Both should match a resource whose id is "8f3a2c1e-...".
    This strips either prefix so joins work for both formats.

#}
{% macro fhir_ref_id(column) -%}
    regexp_replace({{ column }}, '^(urn:uuid:|[A-Za-z]+/)', '')
{%- endmacro %}