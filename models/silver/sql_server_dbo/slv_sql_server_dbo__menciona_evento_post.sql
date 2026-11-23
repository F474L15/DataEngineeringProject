{#
    MEP · Silver (Menciona_Evento_Post). Una fila por pareja (evento, post).
    Incremental por id_mep. Es la tabla de menciones de 4chan: la unidad evaluada
    es el post, y el thread se obtiene desde el post (slv_post.id_thread), sin
    repetirlo aquí.

    Mismas reglas y mismos dos modos que MEN (ver slv_menciona_evento_noticia), con
    estas diferencias: el texto del post es el título de su thread más el
    comentario, y 4chan NO es obligatorio ni cuenta como palabra clave (el post ya
    está en 4chan).

    _loaded_at es el momento en que se calcula la pareja; _loaded_at_texto es la
    carga del post, de donde sale la marca del lote.
#}

{{ config(materialized='incremental', unique_key='id_mep') }}

{%- set eventos_nuevos = var('buscar_eventos_nuevos', false) -%}

with tokens as (

    select * from (

        {{ eventos_palabras_clave() }}

    )
    where palabras_clave <> '4chan'

),

n_tokens as (

    select id_evento, count(*) as n_tokens
    from tokens
    group by id_evento

),

tokens_a_cruzar as (

    select * from tokens
    {% if eventos_nuevos %}
    where id_evento in (
        select id_evento
        from {{ ref('stg_sql_server_dbo__evento') }}
        where _loaded_at >= dateadd(hour, -{{ var('eventos_nuevos_horas', 26) }}, current_timestamp())
    )
    {% endif %}

),

posts as (

    select
          p.id_post
        , coalesce(p.fecha_post, p._loaded_at)          as fecha_texto
        , p.fecha_post
        , ' ' || regexp_replace(
              coalesce({{ clave_texto("coalesce(t.titulo, '') || ' ' || coalesce(p.comment, '')") }}, '')
            , '[^a-z0-9]+', ' ') || ' '                  as texto
        , p._loaded_at
    from {{ ref('slv_sql_server_dbo__post') }} p
    join {{ ref('slv_sql_server_dbo__thread') }} t
        on t.id_thread = p.id_thread
    {% if eventos_nuevos %}
    where coalesce(p.fecha_post, p._loaded_at)
          >= dateadd(day, -{{ var('historico_dias_eventos_nuevos', 365) }}, current_timestamp())
    {% else %}
    {{ filtro_incremental('p._loaded_at', '_loaded_at_texto') }}
    {% endif %}

),

cruce as (

    select
          t.id_evento
        , p.id_post
        , p.fecha_post
        , t.palabras_clave
        , t.es_distintiva
        , p._loaded_at
    from tokens_a_cruzar t
    join posts p
        on contains(p.texto, ' ' || t.palabras_clave || ' ')
       and {{ ventana_evento('p.fecha_texto', 't.fecha_evento') }}

),

pares as (

    select
          c.id_evento
        , c.id_post
    from cruce c
    join n_tokens k
        on k.id_evento = c.id_evento
    group by c.id_evento, c.id_post, k.n_tokens
    having count(*) = k.n_tokens or count_if(c.es_distintiva) > 0

),

coincidencias as (

    select
          c.id_evento
        , c.id_post
        , max(c.fecha_post)                             as fecha_post
        , listagg(c.palabras_clave, ', ')
              within group (order by c.palabras_clave)  as palabras_clave
        , max(c._loaded_at)                             as _loaded_at_texto
    from cruce c
    join pares p
        on p.id_evento = c.id_evento
       and p.id_post = c.id_post
    group by c.id_evento, c.id_post

)

select
      abs(hash(id_evento, id_post))                     as id_mep
    , id_evento
    , id_post
    , palabras_clave
    , fecha_post
    , _loaded_at_texto
    , current_timestamp()                               as _loaded_at
from coincidencias
