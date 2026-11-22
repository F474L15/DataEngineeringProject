{#
    Periodico · Silver. Tabla completa, no incremental: son 5 filas y su nombre y
    su fecha de creación son el valor más frecuente entre todas las noticias, un
    cálculo que necesita el histórico entero en cada ejecución.
#}

{{ config(materialized='table') }}

select
      id_periodico
    , nombre
    , fecha_creacion
    , _loaded_at
from {{ ref('stg_sql_server_dbo__periodico') }}
