{#
    Thread de 4chan, fila a fila. Entidad Thread del modelo (ID_Thread, ID_tablon,
    Titulo).

    No hay una tabla de threads en Bronze: cada fila de posts_4chan lleva el
    tablón y el título de su thread. Esta vista toma de cada fila los datos del
    thread. Parte de stg_sql_server_dbo__post y no de la fuente para que id_thread
    y la resolución del tablón sean idénticos en ambos modelos sin repetir la
    lógica. No es una tabla intermedia: es una vista de staging más.

    Sin agrupar ni deduplicar, para que el filtro `_loaded_at` de Silver llegue a
    Bronze. slv_thread agrupa el lote: elige el título más frecuente y calcula el
    post raíz. id_post y fecha_post van aquí solo para ese cálculo.
#}

select
      id_thread
    , id_tablon
    , titulo_thread
    , id_post
    , fecha_post
    , _loaded_at
from {{ ref('stg_sql_server_dbo__post') }}