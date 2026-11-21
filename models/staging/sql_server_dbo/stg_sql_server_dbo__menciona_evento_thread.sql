{#
    MET · Menciona_Evento_Thread. Relación entre un evento y los threads de 4chan
    que lo mencionan (ID_MET, ID_Thread, ID_Evento, Palabras_clave).

    Una fila por (evento, thread, palabra clave). id_met es el hash de las tres.
    No existe en Bronze: el texto está en los posts, así que la coincidencia se
    evalúa por post y se agrupa por thread (un thread menciona el evento si lo
    hace alguno de sus posts o su título).

    PENDIENTE: la condición de coincidencia está en el JOIN de `coincidencias`
    (ahora `on 1 = 0`, así que el modelo sale vacío) y el token en el macro
    palabras_clave_evento. Textos disponibles: comment (post) y titulo_thread.

    _loaded_at es el más reciente de las filas que se cruzan, para que un
    incremental en Silver vuelva a evaluar el par cuando llegan posts nuevos.
#}

with eventos as (

    select
          id_evento
        , evento_clave
        , {{ palabras_clave_evento('evento_clave') }}   as palabras_clave
        , _loaded_at
    from {{ ref('stg_sql_server_dbo__evento') }}

),

posts as (

    select
          id_thread
        , titulo_thread
        , comment
        , _loaded_at
    from {{ ref('stg_sql_server_dbo__post') }}

),

coincidencias as (

    select
          e.id_evento
        , p.id_thread
        , e.palabras_clave
        , max(greatest(e._loaded_at, p._loaded_at))     as _loaded_at
    from eventos e
    join posts p
        -- PENDIENTE. Ejemplo (no activo):
        --   on contains(lower(p.comment), e.palabras_clave)
        on 1 = 0
    group by e.id_evento, p.id_thread, e.palabras_clave

)

select
      hash(id_evento, id_thread, palabras_clave)        as id_met
    , id_thread
    , id_evento
    , palabras_clave
    , _loaded_at
from coincidencias
