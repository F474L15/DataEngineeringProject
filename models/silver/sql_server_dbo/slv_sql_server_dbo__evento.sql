{#
    Evento · Silver. Incremental por id_evento. Hecho principal de Gold.
    Mantiene los eventos casi duplicados con IDs distintos: esa decisión sigue
    pendiente y se resolverá antes de Gold, no aquí.
#}

{{ config(materialized='incremental', unique_key='id_evento') }}

select
      id_evento
    , evento
    , fecha_evento
    , descripcion
    , id_categoria
    , ubicacion
    , _loaded_at
from {{ ref('stg_sql_server_dbo__evento') }}
{{ filtro_incremental() }}
order by id_evento