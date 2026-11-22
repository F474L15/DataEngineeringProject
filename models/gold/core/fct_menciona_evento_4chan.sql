{# Grano: evento x thread (palabras_clave = lista de las que aparecen). La fecha es la del primer post que menciona. #}
select
      m.id_met
    , m.id_evento
    , m.id_thread
    , e.id_categoria
    , coalesce(to_number(to_char(m.fecha_primera_mencion, 'YYYYMMDD')), 0)  as id_fecha
    , m.palabras_clave
    , m.fecha_primera_mencion
    , {{ fecha_es_valida('m.fecha_primera_mencion') }}                       as fecha_primera_mencion_valida
    , m.n_posts_mencionan
    , case when e.fecha_evento_valida and {{ fecha_es_valida('m.fecha_primera_mencion') }}
           then round(datediff('second', e.fecha_evento, m.fecha_primera_mencion) / 60.0, 2) end as minutos_desde_evento
from {{ ref('slv_sql_server_dbo__menciona_evento_thread') }} m
join {{ ref('dim_evento') }} e on e.id_evento = m.id_evento
order by m.id_met
