{#
    Cuadre de filas entre capas. Devuelve una fila por cada comparación que no
    cuadra (el test falla si hay alguna).

      Bronze -> Silver : las claves distintas de Bronze son las de Silver.
      Silver -> Gold   : cada dimensión tiene tantas filas como su Silver.

    Solo cuadra si Silver está al día con Bronze: tras cargar ficheros nuevos,
    ejecuta dbt antes de mirar este test.
#}

with bronze as (

    select 'post' as entidad, count(distinct id_post) as n
    from {{ source('bronze', 'posts_4chan') }}

    union all

    select 'evento', count(distinct try_to_number(trim(id_evento)))
    from {{ source('bronze', 'eventos') }}

    union all

    select 'noticia', count(distinct id_noticia)
    from ({{ noticias_base() }}) b

    union all

    select 'periodico', count(distinct id_periodico)
    from ({{ noticias_base() }}) b

    union all

    select 'periodista', count(distinct id_periodista)
    from ({{ noticias_base() }}) b

    union all

    select 'escribe', count(distinct id_noticia || '-' || id_periodista)
    from ({{ noticias_base() }}) b

),

silver as (

    select 'post' as entidad, count(distinct id_post) as n from {{ ref('slv_sql_server_dbo__post') }}
    union all
    select 'evento', count(distinct id_evento) from {{ ref('slv_sql_server_dbo__evento') }}
    union all
    select 'noticia', count(distinct id_noticia) from {{ ref('slv_sql_server_dbo__noticia') }}
    union all
    select 'periodico', count(distinct id_periodico) from {{ ref('slv_sql_server_dbo__periodico') }}
    union all
    select 'periodista', count(distinct id_periodista) from {{ ref('slv_sql_server_dbo__periodista') }}
    union all
    select 'escribe', count(distinct id_escribe) from {{ ref('slv_sql_server_dbo__escribe') }}

),

gold as (

    select 'post' as entidad, count(distinct id_post) as n from {{ ref('dim_post') }}
    union all
    select 'evento', count(distinct id_evento) from {{ ref('dim_evento') }}
    union all
    select 'noticia', count(distinct id_noticia) from {{ ref('dim_noticia') }}

),

hilos as (

    -- Los threads no existen en Bronze (se derivan de los posts): se cuadra
    -- Silver post -> Silver thread -> dim_thread.
    select 'thread' as entidad
         , (select count(distinct id_thread) from {{ ref('slv_sql_server_dbo__post') }})   as n_a
         , (select count(distinct id_thread) from {{ ref('slv_sql_server_dbo__thread') }}) as n_b
         , (select count(distinct id_thread) from {{ ref('dim_thread') }})                 as n_c

)

select 'bronze -> silver' as comparacion, b.entidad, b.n as esperado, s.n as obtenido
from bronze b
join silver s on s.entidad = b.entidad
where b.n <> s.n

union all

select 'silver -> gold', s.entidad, s.n, g.n
from silver s
join gold g on g.entidad = s.entidad
where s.n <> g.n

union all

select 'silver post -> silver thread', entidad, n_a, n_b from hilos where n_a <> n_b

union all

select 'silver thread -> dim_thread', entidad, n_b, n_c from hilos where n_b <> n_c
