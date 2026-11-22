{#
    MET · Silver. Incremental por id_met, con el mismo criterio de _loaded_at que
    MEN. Vacío mientras la coincidencia esté pendiente en staging.
#}

{{ config(materialized='incremental', unique_key='id_met') }}

select
      id_met
    , id_thread
    , id_evento
    , palabras_clave
    , fecha_primera_mencion
    , n_posts_mencionan
    , _loaded_at
from {{ ref('stg_sql_server_dbo__menciona_evento_thread') }}
{{ filtro_incremental() }}