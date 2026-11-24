{#
    Post · Gold. Incremental por id_post, con la misma ventana de merge que Silver.
    post_padre vacío, o que apunta a un post que no existe en Silver, se rellena con
    el post raíz de su thread (el más antiguo); el propio post raíz se apunta a sí
    mismo. Así todo post_padre de Gold tiene fila en dim_post. Si más tarde llega un post anterior que
    cambia la raíz, los posts ya cargados no se actualizan hasta que se reprocesen.
#}

{{ config(
    materialized='incremental',
    unique_key='id_post',
    incremental_predicates=predicado_merge()
) }}

select
      p.id_post
    , p.id_thread
    , p.id_usuario
    , p.name_usuario
    , coalesce(pp.id_post, t.id_post_raiz)       as post_padre
    , p.comment
    , p.fecha_post
    , {{ fecha_es_valida('p.fecha_post') }}      as fecha_post_valida
    , p._loaded_at
from {{ ref('slv_sql_server_dbo__post') }} p
left join {{ ref('slv_sql_server_dbo__thread') }} t
    on t.id_thread = p.id_thread
-- Solo se conserva el padre si existe en Silver.
left join {{ ref('slv_sql_server_dbo__post') }} pp
    on pp.id_post = p.post_padre
{{ filtro_incremental('p._loaded_at', '_loaded_at') }}