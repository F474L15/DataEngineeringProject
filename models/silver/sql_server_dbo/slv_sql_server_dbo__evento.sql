{#
    Evento · Silver. Incremental por id_evento. Pocas filas (unos 20 eventos al
    día), así que el merge compara contra toda la tabla, sin ventana.
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