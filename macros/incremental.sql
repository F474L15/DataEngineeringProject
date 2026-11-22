{#
    Filtro de carga incremental para los modelos de Silver.

    En la primera ejecución, y con --full-refresh, no filtra: carga todo. En las
    siguientes solo deja pasar lo que staging ha recibido después de la última
    carga de la tabla (_loaded_at lo rellena Bronze en cada COPY INTO).

    El coalesce evita un fallo silencioso: si la tabla Silver existe pero está
    vacía (como menciona_evento_* mientras no se define la coincidencia),
    max(_loaded_at) es NULL y `_loaded_at > NULL` no devolvería nunca ninguna
    fila, ni siquiera cuando staging empezara a tener datos.

    Uso, al final del SELECT:  {{ filtro_incremental() }}
#}
{% macro filtro_incremental(columna='_loaded_at') -%}
    {%- if is_incremental() -%}
    where {{ columna }} > coalesce(
        (select max({{ columna }}) from {{ this }}),
        '1900-01-01'::timestamp_ltz
    )
    {%- endif -%}
{%- endmacro %}
