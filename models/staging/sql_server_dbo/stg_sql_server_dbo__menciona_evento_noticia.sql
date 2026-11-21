{#
    MEN · Menciona_Evento_Noticia. Relación entre un evento y las noticias que lo
    mencionan (ID_MEN, ID_Evento, ID_Noticia, Palabras_clave).

    Una fila por (evento, noticia, palabra clave). id_men es el hash de las tres.
    No existe en Bronze: se construye comparando el token del evento con el texto
    de la noticia.

    PENDIENTE: la condición de coincidencia está en el JOIN de `coincidencias`
    (ahora `on 1 = 0`, así que el modelo sale vacío) y el token en el macro
    palabras_clave_evento. Textos de la noticia disponibles: titular, subtitulo
    y cuerpo.

    _loaded_at es el más reciente de las dos filas que se cruzan, para que un
    incremental en Silver vuelva a evaluar el par cuando llega un evento o una
    noticia nuevos.
#}

with eventos as (

    select
          id_evento
        , evento_clave
        , {{ palabras_clave_evento('evento_clave') }}   as palabras_clave
        , _loaded_at
    from {{ ref('stg_sql_server_dbo__evento') }}

),

noticias as (

    select
          id_noticia
        , titular
        , subtitulo
        , cuerpo
        , _loaded_at
    from {{ ref('stg_sql_server_dbo__noticia') }}

),

coincidencias as (

    select
          e.id_evento
        , n.id_noticia
        , e.palabras_clave
        , greatest(e._loaded_at, n._loaded_at)          as _loaded_at
    from eventos e
    join noticias n
        -- PENDIENTE. Ejemplo (no activo):
        --   on contains(lower(n.titular), e.palabras_clave)
        on 1 = 0

)

select
      hash(id_evento, id_noticia, palabras_clave)       as id_men
    , id_evento
    , id_noticia
    , palabras_clave
    , _loaded_at
from coincidencias
