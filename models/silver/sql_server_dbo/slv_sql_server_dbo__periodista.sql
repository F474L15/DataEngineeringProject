{#
    Periodista · Silver. Incremental por id_periodista, solo inserta, con el mismo
    criterio que Periodico: cada campo es el valor más frecuente del lote en que el
    periodista aparece por primera vez, y no se modifica después (el merge solo
    actualiza _loaded_at). Un email o una biografía que llegue en un lote posterior
    no se incorpora; si hace falta, se corrige con --full-refresh.
#}

{{ config(
    materialized='incremental',
    unique_key='id_periodista',
    merge_update_columns=['_loaded_at']
) }}

select
      id_periodista
    , coalesce(mode(nombre), ' ')       as nombre
    , coalesce(mode(apellidos), ' ')    as apellidos
    , mode(email)                       as email
    , coalesce(mode(biografia), ' ')    as biografia
    , max(_loaded_at)                   as _loaded_at
from {{ ref('stg_sql_server_dbo__periodista') }}
{{ filtro_incremental() }}
group by id_periodista