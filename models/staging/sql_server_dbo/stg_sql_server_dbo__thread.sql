{#
    Thread de 4chan. Entidad Thread del modelo (ID_Thread, ID_tablon, Titulo).

    No existe en Bronze: se deriva de los posts, un thread por (tablón, título
    normalizado). Parte de stg_sql_server_dbo__post y no de la fuente para que
    id_thread sea idéntico en ambos modelos sin repetir la resolución del tablón.
    No es una tabla intermedia: es una vista de staging más.

    El título es la grafía más frecuente entre los posts del thread (en origen
    varía en mayúsculas y espacios). _loaded_at es el del post más reciente, para
    que un incremental en Silver vuelva a procesar el thread cuando llegan posts.
#}

with posts as (

    select * from {{ ref('stg_sql_server_dbo__post') }}

),

por_grafia as (

    select
          id_thread
        , id_tablon
        , titulo_thread
        , count(*)              as n_posts
        , max(_loaded_at)       as _loaded_at
    from posts
    group by id_thread, id_tablon, titulo_thread

)

select
      id_thread
    , id_tablon
    , max_by(titulo_thread, n_posts)    as titulo
    , max(_loaded_at)                   as _loaded_at
from por_grafia
group by id_thread, id_tablon
