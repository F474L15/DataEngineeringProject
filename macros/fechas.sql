{# Una fecha es válida si existe, no es anterior a la fecha mínima ni futura.
   Mínima ajustable con --vars '{fecha_minima_valida: 2005-01-01}'. #}
{% macro fecha_es_valida(columna) -%}
    ({{ columna }} is not null
     and {{ columna }} >= '{{ var("fecha_minima_valida", "2009-01-01") }}'::timestamp_ntz
     and {{ columna }} <= sysdate())
{%- endmacro %}
