{#
    Thread · Silver. Incremental por id_thread, con estado: cada ejecución combina
    el lote nuevo de posts con la fila que el thread ya tiene en la tabla.

    - titulo: la grafía más frecuente del PRIMER lote del thread; después se
      conserva (el estado previo pesa más que cualquier lote nuevo).
    - id_post_raiz y fecha_primer_post: el post más antiguo del thread (con fecha;
      si ninguno la tiene, el de menor id_post). Si llega después un post más
      antiguo, la raíz se actualiza. dim_post la usa para rellenar post_padre.
    Se calcula así, y no con una función de ventana sobre todos los posts, porque
    leer toda la tabla de posts en cada ejecución no escala.
    Sin ventana en el merge: hay muchos menos threads que posts.
#}

{{ config(materialized='incremental', unique_key='id_thread') }}

with lote as (

    select id_thread, id_tablon, titulo_thread, id_post, fecha_post, _loaded_at
    from {{ ref('stg_sql_server_dbo__thread') }}
    {{ filtro_incremental() }}

),

por_grafia as (

    select
          id_thread
        , id_tablon
        , titulo_thread
        , count(*)                              as peso
        , min_by(id_post, fecha_post)           as id_post_con_fecha
        , min(fecha_post)                       as fecha_post
        , min(id_post)                          as id_post_min
        , max(_loaded_at)                       as _loaded_at
    from lote
    group by id_thread, id_tablon, titulo_thread

)

{% if is_incremental() %}
, previo as (

    -- Estado ya guardado de los threads que aparecen en el lote.
    select
          id_thread
        , id_tablon
        , titulo                                as titulo_thread
        , 1000000000                            as peso
        , id_post_raiz                          as id_post_con_fecha
        , fecha_primer_post                     as fecha_post
        , id_post_raiz                          as id_post_min
        , _loaded_at
    from {{ this }}
    where id_thread in (select id_thread from lote)

),

combinado as (

    select * from por_grafia
    union all
    select * from previo

)
{% else %}
, combinado as (

    select * from por_grafia

)
{% endif %}

select
      id_thread
    , max(id_tablon)                                                    as id_tablon
    , max_by(titulo_thread, peso)                                       as titulo
    , coalesce(min_by(id_post_con_fecha, fecha_post), min(id_post_min)) as id_post_raiz
    , min(fecha_post)                                                   as fecha_primer_post
    , max(_loaded_at)                                                   as _loaded_at
from combinado
group by id_thread