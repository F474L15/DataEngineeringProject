{#
    Post · Silver. Incremental: solo procesa los posts que staging ha recibido
    desde la última carga y los inserta o actualiza por id_post (merge).
    Columnas del modelo (ID_Post, ID_Thread, ID_Usuario, Name_Usuario, Comment,
    Image, Post_Padre, Fecha_post). El tablón y el título viven en Thread.
#}

{{ config(materialized='incremental', unique_key='id_post') }}

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
from {{ ref('stg_sql_server_dbo__post') }}
{{ filtro_incremental() }}
