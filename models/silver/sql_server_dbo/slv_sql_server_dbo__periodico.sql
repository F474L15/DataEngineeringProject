{#
    Periodico · Silver. Incremental por id_periodico, solo inserta.

    Hay 5 periódicos y cada lote trae miles de filas de cada uno, así que el
    nombre y la fecha de creación más frecuentes del lote son representativos. El
    primer valor que se guarda ya no cambia: el merge solo actualiza _loaded_at
    (merge_update_columns). Así no hace falta leer todas las noticias de la historia
    en cada ejecución, que era lo que obligaba a usar una tabla completa.
#}

{{ config(
    materialized='incremental',
    unique_key='id_periodico',
    merge_update_columns=['_loaded_at']
) }}

select
      id_periodico
    , coalesce(mode(nombre), ' ')       as nombre
    , mode(fecha_creacion)              as fecha_creacion
    , max(_loaded_at)                   as _loaded_at
from {{ ref('stg_sql_server_dbo__periodico') }}
{{ filtro_incremental() }}
group by id_periodico