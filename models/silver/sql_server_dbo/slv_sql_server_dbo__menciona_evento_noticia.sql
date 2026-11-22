{#
    MEN · Silver. Incremental por id_men. staging calcula _loaded_at como el más
    reciente de las dos filas que se cruzan, así que un evento o una noticia
    nuevos generan sus pares sin reprocesar el resto.
    Vacío mientras la coincidencia esté pendiente en staging.
#}

{{ config(materialized='incremental', unique_key='id_men') }}

select
      id_men
    , id_evento
    , id_noticia
    , palabras_clave
    , _loaded_at
from {{ ref('stg_sql_server_dbo__menciona_evento_noticia') }}
{{ filtro_incremental() }}
order by id_men
