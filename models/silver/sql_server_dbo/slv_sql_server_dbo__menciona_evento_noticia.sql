{#
    MEN · Silver. Una fila por pareja (evento, noticia). Incremental por id_men.

    La coincidencia se calcula aquí, y no en staging, porque tiene que leer solo lo
    nuevo. Dos modos, que se eligen con una variable:

      Normal (cada 10 minutos)   Las noticias nuevas de Silver contra los eventos.
      buscar_eventos_nuevos      (job diario) Los eventos recién cargados contra las
         = true                  noticias ya guardadas, dentro de la ventana.

    Reglas (las mismas que antes): una noticia menciona un evento si contiene TODAS
    sus palabras clave o al menos UNA distintiva; si el evento tiene el token 4chan,
    la noticia debe contenerlo. Se añade la ventana temporal de ventana_evento().

    _loaded_at es el momento en que se calcula la pareja, para que Gold y otros
    incrementales la vean aunque la noticia sea antigua (modo de eventos nuevos).
    _loaded_at_texto es la carga de la noticia: de ahí sale la marca del lote, así
    que el filtro no depende de cuándo se calcularon las parejas.

    Límite conocido: si cambia la frecuencia de una palabra (llega un evento con una
    palabra de otro), las parejas antiguas de los demás eventos no se reevalúan.
#}

{{ config(materialized='incremental', unique_key='id_men') }}

{%- set eventos_nuevos = var('buscar_eventos_nuevos', false) -%}

with tokens as (

    {{ eventos_palabras_clave() }}

),

n_tokens as (

    select
          id_evento
        , count(*)                                      as n_tokens
        , count_if(palabras_clave = '4chan') > 0        as exige_4chan
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

noticias as (

    select
          id_noticia
        , coalesce(fecha_publicacion, _loaded_at)       as fecha_texto
        , ' ' || regexp_replace(
              coalesce({{ clave_texto("coalesce(titular, '') || ' ' || coalesce(subtitulo, '') || ' ' || coalesce(cuerpo, '')") }}, '')
            , '[^a-z0-9]+', ' ') || ' '                  as texto
        , _loaded_at
    from {{ ref('slv_sql_server_dbo__noticia') }}
    {% if eventos_nuevos %}
    where coalesce(fecha_publicacion, _loaded_at)
          >= dateadd(day, -{{ var('historico_dias_eventos_nuevos', 365) }}, current_timestamp())
    {% else %}
    {{ filtro_incremental('_loaded_at', '_loaded_at_texto') }}
    {% endif %}

),

cruce as (

    select
          t.id_evento
        , n.id_noticia
        , t.palabras_clave
        , t.es_distintiva
        , n._loaded_at
    from tokens_a_cruzar t
    join noticias n
        on contains(n.texto, ' ' || t.palabras_clave || ' ')
       and {{ ventana_evento('n.fecha_texto', 't.fecha_evento') }}

),

pares as (

    select
          c.id_evento
        , c.id_noticia
    from cruce c
    join n_tokens k
        on k.id_evento = c.id_evento
    group by c.id_evento, c.id_noticia, k.n_tokens, k.exige_4chan
    having (count(*) = k.n_tokens or count_if(c.es_distintiva) > 0)
       and (not k.exige_4chan or count_if(c.palabras_clave = '4chan') > 0)

),

coincidencias as (

    select
          c.id_evento
        , c.id_noticia
        , listagg(c.palabras_clave, ', ')
              within group (order by c.palabras_clave)  as palabras_clave
        , max(c._loaded_at)                             as _loaded_at_texto
    from cruce c
    join pares p
        on p.id_evento = c.id_evento
       and p.id_noticia = c.id_noticia
    group by c.id_evento, c.id_noticia

)

select
      abs(hash(id_evento, id_noticia))                  as id_men
    , id_evento
    , id_noticia
    , palabras_clave
    , _loaded_at_texto
    , current_timestamp()                               as _loaded_at
from coincidencias