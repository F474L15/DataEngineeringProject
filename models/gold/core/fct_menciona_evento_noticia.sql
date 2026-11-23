{#
    Grano: evento x noticia (palabras_clave = lista de las que aparecen).
    Incremental por id_men: recoge las parejas que Silver ha calculado desde la
    última ejecución, también las de eventos nuevos contra noticias antiguas.
#}

{{ config(materialized='incremental', unique_key='id_men') }}

select
      m.id_men
    , m.id_evento
    , m.id_noticia
    , e.id_categoria
    , coalesce(to_number(to_char(n.fecha_publicacion, 'YYYYMMDD')), 0)    as id_fecha
    , m.palabras_clave
    , n.fecha_publicacion                                                  as fecha_mencion
    , n.fecha_publicacion_valida                                           as fecha_mencion_valida
    , case when e.fecha_evento_valida and n.fecha_publicacion_valida
           then round(datediff('second', e.fecha_evento, n.fecha_publicacion) / 60.0, 2) end as minutos_desde_evento
    , m._loaded_at
from {{ ref('slv_sql_server_dbo__menciona_evento_noticia') }} m
join {{ ref('dim_evento') }}  e on e.id_evento  = m.id_evento
join {{ ref('dim_noticia') }} n on n.id_noticia = m.id_noticia
{{ filtro_incremental('m._loaded_at', '_loaded_at') }}