{#
    Post · Silver. Incremental por id_post (merge).

    - Lee el lote nuevo de Bronze a través de staging (vista fila a fila) y lo
      deduplica por id_post: gana la carga más reciente; a igualdad, la fecha más
      reciente y, si sigue el empate, un desempate determinista por contenido.
    - El merge solo compara contra los últimos `merge_ventana_dias` días de la
      tabla (ver predicado_merge). Un id_post que reaparezca después quedaría
      duplicado: lo detecta el test de unicidad.
    - Elimina los posts cuya fecha no es válida (ilegible, anterior a la fecha
      mínima o futura): no se puede saber cuándo se escribieron ni sanearlos.
    - post_padre se guarda tal cual llega (puede ser NULL). El post raíz del thread
      se calcula en slv_thread y dim_post rellena con él los vacíos.
    Columnas del modelo (ID_Post, ID_Thread, ID_Usuario, Name_Usuario, Comment,
    Image, Post_Padre, Fecha_post). El tablón y el título viven en Thread.
#}

{{ config(
    materialized='incremental',
    unique_key='id_post',
    incremental_predicates=predicado_merge()
) }}

with validos as (

    select * from {{ ref('stg_sql_server_dbo__post') }}
    where {{ fecha_es_valida('fecha_post') }}

)

select
      id_post
    , id_thread
    , id_usuario
    , name_usuario
    , comment
    , image
    , post_padre
    , fecha_post
    , _loaded_at
from validos
{{ filtro_incremental() }}
qualify row_number() over (
    partition by id_post
    order by _loaded_at desc, fecha_post desc nulls last
           , hash(comment, name_usuario, id_usuario, post_padre)
) = 1