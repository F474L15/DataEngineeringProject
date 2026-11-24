{#
    Post de 4chan limpio, fila a fila. Entidad Post del modelo.

    Es una vista SIN deduplicar, sin funciones de ventana y sin agregados, a
    propósito: así Snowflake empuja el filtro `_loaded_at` de Silver hasta Bronze y
    solo lee el lote nuevo (≈ 7.000 posts cada 10 minutos, no toda la historia).
    La deduplicación por id_post vive en slv_post y el post_padre vacío se rellena
    en dim_post, porque ambos necesitan más filas que las de la fila actual.

    - El tablón se resuelve por el nombre, que solo tiene erratas ('Intrnational'),
      acercándolo al tablón más parecido del seed (distancia de edición <= 3). Las
      siglas se usan solo si el nombre no resuelve: traen valores de otro tablón
      (p. ej. 'Science & Math' con '/pol/') en unas 80 filas. El seed tiene pocas
      filas, así que la comparación es barata aunque se haga por fila.
    - id_thread: hash de (tablón, título normalizado). El mismo título existe en
      varios tablones, así que el título solo no identifica un thread.
#}

with src as (

    select * from {{ source('bronze', 'posts_4chan') }}

),

tablones as (

    select
          id_tablon
        , {{ clave_texto('name_tablon') }}              as nombre_clave
        , regexp_replace(lower(siglas), '[^a-z]', '')    as siglas_clave
    from {{ ref('tablones') }}

),

limpio as (

    select
          s.id_post
        , coalesce(tn.id_tablon, ts.id_tablon)                          as id_tablon
        , {{ limpiar_texto('s.titulo_thread') }}                         as titulo_thread
        , {{ clave_texto('s.titulo_thread') }}                           as titulo_clave
        , {{ recortar('s.id_usuario') }}                                 as id_usuario
        , {{ limpiar_texto('s.name_usuario') }}                          as name_usuario
        , {{ recortar(reparar_encoding('s.comment')) }}                  as comment
        , {{ recortar('s.image') }}                                      as image
        , try_to_number(trim(s.post_padre))                              as post_padre
        , {{ parse_fecha('s.fecha_post') }}                              as fecha_post
        , s._loaded_at
    from src s
    left join tablones tn
        on editdistance({{ clave_texto('s.name_tablon') }}, tn.nombre_clave) <= 3
    left join tablones ts
        on ts.siglas_clave = regexp_replace(lower(s.siglas), '[^a-z]', '')

)

select
      id_post
    , abs(hash(id_tablon, titulo_clave))         as id_thread
    , id_tablon
    , {{ texto_o_blanco('titulo_thread') }}      as titulo_thread
    , titulo_clave
    , {{ texto_o_blanco('id_usuario') }}         as id_usuario
    , {{ texto_o_blanco('name_usuario') }}       as name_usuario
    , {{ texto_o_blanco('comment') }}            as comment
    , {{ texto_o_blanco('image') }}              as image
    , post_padre
    , fecha_post
    , _loaded_at
from limpio