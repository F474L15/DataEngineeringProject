select
      n.id_noticia
    , n.id_periodico
    , p.nombre                        as nombre_periodico
    , n.titular
    , n.subtitulo
    , n.url
    , n.imagen
    , coalesce(n.id_categoria, -1)    as id_categoria
    , c.categoria                     as categoria_noticia
    , n.fecha_publicacion
    , {{ fecha_es_valida('n.fecha_publicacion') }} as fecha_publicacion_valida
from {{ ref('slv_sql_server_dbo__noticia') }} n
left join {{ ref('slv_sql_server_dbo__periodico') }} p on p.id_periodico = n.id_periodico
left join {{ ref('categorias') }} c on c.id_categoria = n.id_categoria
