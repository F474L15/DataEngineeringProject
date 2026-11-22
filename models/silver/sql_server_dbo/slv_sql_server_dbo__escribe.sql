{#
    Escribe · Silver. Relación noticia-periodista con la marca de autor
    principal. Incremental por id_escribe, porque crece al ritmo de las noticias.
#}

{{ config(materialized='incremental', unique_key='id_escribe') }}

select
      id_escribe
    , id_noticia
    , id_periodista
    , autor_principal
    , _loaded_at
from {{ ref('stg_sql_server_dbo__escribe') }}
{{ filtro_incremental() }}
order by id_escribe
