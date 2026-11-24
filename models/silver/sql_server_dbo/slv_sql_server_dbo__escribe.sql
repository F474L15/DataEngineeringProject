{#
    Escribe · Silver. Relación noticia-periodista con la marca de autor
    principal. Incremental por id_escribe (crece al ritmo de las noticias), con
    ventana de merge de `merge_ventana_dias` días y deduplicación del lote.
#}

{{ config(
    materialized='incremental',
    unique_key='id_escribe',
    incremental_predicates=predicado_merge()
) }}

select
      id_escribe
    , id_noticia
    , id_periodista
    , autor_principal
    , _loaded_at
from {{ ref('stg_sql_server_dbo__escribe') }}
{{ filtro_incremental() }}
qualify row_number() over (
    partition by id_escribe
    order by _loaded_at desc
) = 1