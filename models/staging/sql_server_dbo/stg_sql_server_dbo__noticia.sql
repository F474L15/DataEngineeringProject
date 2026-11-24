{#
    Noticia limpia, fila a fila. Entidad Noticia del modelo. noticias.csv trae una
    fila por noticia y periodista. cuerpo es la columna `desarrollo` del CSV.

    Vista sin deduplicar ni agrupar, para que el filtro `_loaded_at` de Silver llegue
    a Bronze (ver stg_sql_server_dbo__post). La deduplicación por id_noticia
    (URL normalizada) vive en slv_noticia.
#}

with base as (

    {{ noticias_base() }}

),

categorias as (

    select id_categoria, categoria_clave from {{ ref('categorias') }}

)

select
      b.id_noticia
    , b.id_periodico
    , {{ texto_o_blanco(limpiar_texto('b.titular')) }}               as titular
    , {{ texto_o_blanco(limpiar_texto('b.subtitulo')) }}             as subtitulo
    , {{ texto_o_blanco(recortar(reparar_encoding('b.desarrollo'))) }}  as cuerpo
    , {{ texto_o_blanco(recortar('b.imagen')) }}                     as imagen
    , coalesce(c.id_categoria, sc.id_categoria)                      as id_categoria
    , {{ parse_fecha('b.fecha_publicacion') }}                       as fecha_publicacion
    , coalesce({{ clave_url('b.url') }}, 'NULL')                     as url
    , b._loaded_at
from base b
left join categorias c
    on c.categoria_clave = {{ clave_categoria('b.categoria') }}
-- Sin categoría o categoría no reconocida: la fila 'sin categoria' del seed.
left join categorias sc
    on sc.categoria_clave = 'sin categoria'