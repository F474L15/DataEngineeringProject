select
      t.id_thread
    , t.titulo
    , t.id_tablon
    , coalesce(b.name_tablon, ' ')    as name_tablon
    , coalesce(b.siglas, ' ')         as siglas
from {{ ref('slv_sql_server_dbo__thread') }} t
left join {{ ref('tablones') }} b on b.id_tablon = t.id_tablon
order by t.id_thread
