{# menciona_4chan responde a la pregunta 2: el propio texto del evento cita 4chan. #}
select
      id_evento
    , evento
    , descripcion
    , ubicacion
    , fecha_evento
    , {{ fecha_es_valida('fecha_evento') }}                                   as fecha_evento_valida
    , id_categoria
    , (contains(lower(coalesce(evento, '')), '4chan')
       or contains(lower(coalesce(descripcion, '')), '4chan'))                as menciona_4chan
from {{ ref('slv_sql_server_dbo__evento') }}
order by id_evento