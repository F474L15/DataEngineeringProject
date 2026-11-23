{#
    Grano: evento x post (palabras_clave = lista de las que aparecen). La unidad
    evaluada es el post; el thread se obtiene desde dim_post. Incremental por
    id_mep: recoge las parejas que Silver ha calculado desde la última ejecución,
    también las de eventos nuevos contra posts antiguos.
#}

{{ config(materialized='incremental', unique_key='id_mep') }}

select
      m.id_mep
    , m.id_evento
    , m.id_post
    , e.id_categoria
    , coalesce(to_number(to_char(m.fecha_post, 'YYYYMMDD')), 0)             as id_fecha
    , m.palabras_clave
    , m.fecha_post                                                           as fecha_mencion
    , p.fecha_post_valida                                                    as fecha_mencion_valida
    , case when e.fecha_evento_valida and p.fecha_post_valida
           then round(datediff('second', e.fecha_evento, m.fecha_post) / 60.0, 2) end as minutos_desde_evento
    , m._loaded_at
from {{ ref('slv_sql_server_dbo__menciona_evento_post') }} m
join {{ ref('dim_evento') }} e on e.id_evento = m.id_evento
join {{ ref('dim_post') }}   p on p.id_post   = m.id_post
{{ filtro_incremental('m._loaded_at', '_loaded_at') }}