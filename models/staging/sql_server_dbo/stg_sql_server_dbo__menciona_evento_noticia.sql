{#
    MEN · Menciona_Evento_Noticia. Relación entre un evento y las noticias que lo
    mencionan (ID_MEN, ID_Evento, ID_Noticia, Palabras_clave).

    Una fila por (evento, noticia). id_men = abs(hash(id_evento, id_noticia)): es
    siempre positivo y el mismo par da siempre el mismo id (hash es determinista;
    un row_number cambiaría al entrar datos nuevos). palabras_clave es la lista
    de las palabras del evento que aparecen en la noticia, separadas por coma y
    en orden alfabético.
    No existe en Bronze: se construye comparando las palabras clave del evento
    (macro eventos_palabras_clave) con el texto de la noticia.

    Regla: una noticia menciona un evento si, como palabras completas en
    titular + subtitulo + cuerpo, aparecen TODAS sus palabras clave o al menos
    UNA palabra distintiva (es_distintiva en el macro: 'epstein', 'vegas'...).
    Si el evento tiene el token '4chan', la noticia también debe nombrarlo en
    cualquiera de los dos casos. Se guardan solo las palabras que aparecen.

    El texto se normaliza como las palabras clave (minúsculas, sin tildes) y se
    reduce a letras y números separados por un espacio, así ' vegas ' no
    coincide con 'vegasa' ni con 'las-vegas' mal partido.

    _loaded_at es el más reciente de las dos filas que se cruzan, para que un
    incremental en Silver vuelva a evaluar el par cuando llega un evento o una
    noticia nuevos.
#}

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

noticias as (

    select
          id_noticia
        , ' ' || regexp_replace(
              coalesce({{ clave_texto("coalesce(titular, '') || ' ' || coalesce(subtitulo, '') || ' ' || coalesce(cuerpo, '')") }}, '')
            , '[^a-z0-9]+', ' ') || ' '                  as texto
        , _loaded_at
    from {{ ref('stg_sql_server_dbo__noticia') }}

),

cruce as (

    select
          t.id_evento
        , n.id_noticia
        , t.palabras_clave
        , t.es_distintiva
        , greatest(t._loaded_at, n._loaded_at)          as _loaded_at
    from tokens t
    join noticias n
        on contains(n.texto, ' ' || t.palabras_clave || ' ')

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
        , max(c._loaded_at)                             as _loaded_at
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
    , _loaded_at
from coincidencias
