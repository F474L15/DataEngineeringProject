{# Thread · Gold. Incremental por id_thread (hay muchos menos threads que posts). #}

{{ config(materialized='incremental', unique_key='id_thread') }}

select
      t.id_thread
    , t.titulo
    , t.id_tablon
    , coalesce(b.name_tablon, ' ')    as name_tablon
    , coalesce(b.siglas, ' ')         as siglas
    , t.id_post_raiz
    , t.fecha_primer_post
    , t._loaded_at
from {{ ref('slv_sql_server_dbo__thread') }} t
left join {{ ref('tablones') }} b on b.id_tablon = t.id_tablon
{{ filtro_incremental('t._loaded_at', '_loaded_at') }}