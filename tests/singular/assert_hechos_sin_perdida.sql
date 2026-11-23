{#
    Cada hecho tiene tantas filas como su relación de Silver. Los hechos hacen
    inner join a las dimensiones: si una clave no existe en la dimensión, la fila
    se descarta sin error, y este test lo detecta.
#}

select 'fct_menciona_evento_noticia' as hecho, s.n as filas_silver, g.n as filas_gold
from (select count(*) as n from {{ ref('slv_sql_server_dbo__menciona_evento_noticia') }}) s
cross join (select count(*) as n from {{ ref('fct_menciona_evento_noticia') }}) g
where s.n <> g.n

union all

select 'fct_menciona_evento_4chan', s.n, g.n
from (select count(*) as n from {{ ref('slv_sql_server_dbo__menciona_evento_thread') }}) s
cross join (select count(*) as n from {{ ref('fct_menciona_evento_4chan') }}) g
where s.n <> g.n
