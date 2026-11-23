select
      id_post
    , id_thread
    , id_usuario
    , name_usuario
    , post_padre
    , comment
    , fecha_post
    , {{ fecha_es_valida('fecha_post') }} as fecha_post_valida
from {{ ref('slv_sql_server_dbo__post') }}
order by id_post