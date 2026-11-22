{#
    MET · Menciona_Evento_Thread. Relación entre un evento y los threads de 4chan
    que lo mencionan (ID_MET, ID_Thread, ID_Evento, Palabras_clave).

    Una fila por (evento, thread). id_met = abs(hash(id_evento, id_thread)): es
    siempre positivo y el mismo par da siempre el mismo id. palabras_clave es la
    lista de las palabras del evento que aparecen en los posts del thread,
    separadas por coma y en orden alfabético.
    No existe en Bronze: el texto está en los posts, así que la coincidencia se
    evalúa por post y se agrupa por thread.

    Regla: un post menciona un evento si, como palabras completas en
    titulo_thread + comment del post, aparecen TODAS sus palabras clave o al
    menos UNA palabra distintiva (es_distintiva en el macro: 'epstein',
    'vegas'...). Las palabras pueden repartirse entre título y comentario, pero
    no entre posts distintos. Un thread menciona el evento si lo hace alguno de
    sus posts. Se guardan solo las palabras que aparecen.

    El token '4chan' NO se exige aquí: todos los posts vienen de 4chan y ninguno
    lo nombra, así que exigirlo dejaría sin menciones a los eventos que lo
    llevan. Solo se exige en MEN (noticias).

    fecha_primera_mencion es la fecha del post más antiguo del thread que cumple
    la regla (min ignora nulos); n_posts_mencionan cuenta esos posts.

    _loaded_at es el más reciente de las filas que se cruzan, para que un
    incremental en Silver vuelva a evaluar el par cuando llegan posts nuevos.
#}

with tokens as (

    select id_evento, palabras_clave, es_distintiva, _loaded_at
    from (

        {{ eventos_palabras_clave() }}

    )
    where palabras_clave <> '4chan'

),

n_tokens as (

    select id_evento, count(*) as n_tokens
    from tokens
    group by id_evento

),

posts as (

    select
          id_post
        , id_thread
        , fecha_post
        , ' ' || regexp_replace(
              coalesce({{ clave_texto("coalesce(titulo_thread, '') || ' ' || coalesce(comment, '')") }}, '')
            , '[^a-z0-9]+', ' ') || ' '                  as texto
        , _loaded_at
    from {{ ref('stg_sql_server_dbo__post') }}

),

cruce as (

    select
          t.id_evento
        , p.id_post
        , p.id_thread
        , t.palabras_clave
        , t.es_distintiva
        , p.fecha_post
        , greatest(t._loaded_at, p._loaded_at)          as _loaded_at
    from tokens t
    join posts p
        on contains(p.texto, ' ' || t.palabras_clave || ' ')

),

posts_que_mencionan as (

    select
          c.id_evento
        , c.id_post
        , c.id_thread
        , c.palabras_clave
        , c.fecha_post
        , c._loaded_at
    from cruce c
    join n_tokens k
        on k.id_evento = c.id_evento
    qualify count(*) over (partition by c.id_evento, c.id_post) = k.n_tokens
         or sum(iff(c.es_distintiva, 1, 0)) over (partition by c.id_evento, c.id_post) > 0

),

coincidencias as (

    select
          id_evento
        , id_thread
        , listagg(distinct palabras_clave, ', ')
              within group (order by palabras_clave)    as palabras_clave
        , min(fecha_post)                               as fecha_primera_mencion
        , count(distinct id_post)                       as n_posts_mencionan
        , max(_loaded_at)                               as _loaded_at
    from posts_que_mencionan
    group by id_evento, id_thread

)

select
      abs(hash(id_evento, id_thread))                   as id_met
    , id_thread
    , id_evento
    , palabras_clave
    , fecha_primera_mencion
    , n_posts_mencionan
    , _loaded_at
from coincidencias
