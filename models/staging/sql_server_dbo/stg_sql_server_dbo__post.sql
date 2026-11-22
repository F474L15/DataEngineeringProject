{#
    Post de 4chan limpio. Entidad Post del modelo (ID_Post, ID_Thread, ...).

    - El tablón se resuelve por el nombre, que solo tiene erratas ('Intrnational'),
      acercándolo al tablón más parecido del seed (distancia de edición <= 3).
      Las siglas se usan solo si el nombre no resuelve: traen valores de otro
      tablón (p. ej. 'Science & Math' con '/pol/') en unas 80 filas.
    - id_thread: hash de (tablón, título normalizado). El mismo título existe en
      varios tablones, así que el título solo no identifica un thread.
    - Deduplica por id_post y se queda con la carga más reciente.
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

variantes_nombre as (

    select distinct {{ clave_texto('name_tablon') }} as nombre_clave
    from src

),

tablon_por_nombre as (

    select
          v.nombre_clave    as variante
        , t.id_tablon
    from variantes_nombre v
    cross join tablones t
    where editdistance(v.nombre_clave, t.nombre_clave) <= 3
    qualify row_number() over (
        partition by v.nombre_clave
        order by editdistance(v.nombre_clave, t.nombre_clave), t.id_tablon
    ) = 1

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
    left join tablon_por_nombre tn
        on tn.variante = {{ clave_texto('s.name_tablon') }}
    left join tablones ts
        on ts.siglas_clave = regexp_replace(lower(s.siglas), '[^a-z]', '')

)

,

deduplicado as (

    select
          id_post
        , abs(hash(id_tablon, titulo_clave))    as id_thread
        , id_tablon
        , titulo_thread
        , titulo_clave
        , id_usuario
        , name_usuario
        , comment
        , image
        , post_padre
        , fecha_post
        , _loaded_at
    from limpio
    qualify row_number() over (
        partition by id_post
        order by _loaded_at desc, fecha_post desc nulls last
               , hash(comment, name_usuario, id_usuario, post_padre)
    ) = 1

)

select
      id_post
    , id_thread
    , id_tablon
    , {{ texto_o_blanco('titulo_thread') }}      as titulo_thread
    , titulo_clave
    , {{ texto_o_blanco('id_usuario') }}         as id_usuario
    , {{ texto_o_blanco('name_usuario') }}       as name_usuario
    , {{ texto_o_blanco('comment') }}            as comment
    , {{ texto_o_blanco('image') }}              as image
    -- Gobernanza: un post sin padre apunta al post más antiguo de su thread
    -- (el propio post raíz se apunta a sí mismo).
    , coalesce(
          post_padre
        , first_value(id_post) over (
              partition by id_thread
              order by fecha_post asc nulls last, id_post asc
          )
      )                                          as post_padre
    , fecha_post
    , _loaded_at
from deduplicado
