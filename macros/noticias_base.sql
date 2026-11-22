{#
    Claves de negocio y base común de las entidades que salen de noticias.csv
    (noticia, periodico, periodista, escribe). Es un macro y no un modelo
    intermedio: cada modelo de staging lo expande como una CTE, de modo que los
    IDs se calculan igual en los cuatro y no hay tabla ni vista intermedia.
#}

{# URL normalizada: minúsculas, sin espacios, 'http:/' -> 'https://', sin '/' final. #}
{% macro clave_url(columna) -%}
    regexp_replace(regexp_replace(nullif(lower(trim({{ columna }})), ''), '^https?:/+', 'https://'), '/+$', '')
{%- endmacro %}


{# Periódico: clave sin tildes ni mayúsculas y sin el sufijo 'S.L.'. #}
{% macro clave_periodico(columna) -%}
    trim(regexp_replace({{ clave_texto(columna) }}, '\\s*s\\.l\\.?$', ''))
{%- endmacro %}


{#
    Periodista: nombre y apellidos como conjunto de palabras ordenadas, para que
    'Alba' + 'Montoro Pla' y 'Montoro Pla' + 'Alba' (campos intercambiados en
    origen) den la misma clave.
#}
{% macro clave_periodista(nombre, apellidos) -%}
    array_to_string(array_sort(split(
        {{ clave_texto("coalesce(" ~ nombre ~ ", '') || ' ' || coalesce(" ~ apellidos ~ ", '')") }}
    , ' ')), ' ')
{%- endmacro %}


{#
    Noticia: la URL normalizada. Si falta (25 filas), se usa titular + periódico +
    fecha, para que la fila no quede sin clave.
#}
{% macro clave_noticia(url, titular, periodico, fecha) -%}
    coalesce(
          {{ clave_url(url) }}
        , 'sin_url|' || coalesce({{ clave_texto(titular) }}, '')
                     || '|' || coalesce({{ clave_periodico(periodico) }}, '')
                     || '|' || coalesce(trim({{ fecha }}), '')
    )
{%- endmacro %}


{# Filas de Bronze con los tres IDs calculados. Uso: with base as ({{ noticias_base() }}) #}
{% macro noticias_base() -%}
    select
          abs(hash({{ clave_noticia('url', 'titular', 'nombre_periodico', 'fecha_publicacion') }}))   as id_noticia
        , abs(hash({{ clave_periodico('nombre_periodico') }}))                                          as id_periodico
        , abs(hash({{ clave_periodista('nombre_periodista', 'apellidos_periodista') }}))                as id_periodista
        , *
    from {{ source('bronze', 'noticias') }}
{%- endmacro %}
