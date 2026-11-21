{#
    Noticia limpia. Entidad Noticia del modelo. noticias.csv trae una fila por
    noticia y periodista, así que se deduplica por id_noticia (URL normalizada).
    cuerpo es la columna `desarrollo` del CSV.
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
    , {{ limpiar_texto('b.titular') }}                               as titular
    , {{ limpiar_texto('b.subtitulo') }}                             as subtitulo
    , {{ recortar(reparar_encoding('b.desarrollo')) }}               as cuerpo
    , {{ recortar('b.imagen') }}                                     as imagen
    , c.id_categoria
    , {{ parse_fecha('b.fecha_publicacion') }}                       as fecha_publicacion
    , {{ clave_url('b.url') }}                                       as url
    , b._loaded_at
from base b
left join categorias c
    on c.categoria_clave = {{ clave_categoria('b.categoria') }}
qualify row_number() over (partition by b.id_noticia order by b._loaded_at desc) = 1
