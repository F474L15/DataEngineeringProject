{#
    Thread · Silver. Incremental por id_thread. staging calcula _loaded_at como
    el del post más reciente del thread, así que un thread vuelve a procesarse
    (y su título se recalcula) cuando le llegan posts nuevos.
#}

{{ config(materialized='incremental', unique_key='id_thread') }}

select
      id_thread
    , id_tablon
    , titulo
    , _loaded_at
from {{ ref('stg_sql_server_dbo__thread') }}
{{ filtro_incremental() }}
order by id_thread
