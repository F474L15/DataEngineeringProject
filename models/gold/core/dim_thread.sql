select
      t.id_thread
    , t.titulo
    , t.id_tablon
    , b.name_tablon
    , b.siglas
from {{ ref('slv_sql_server_dbo__thread') }} t
left join {{ ref('tablones') }} b on b.id_tablon = t.id_tablon
