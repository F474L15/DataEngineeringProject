{#
    Periodista · Silver. Tabla completa, no incremental, por el mismo motivo que
    Periodico: cada campo es el valor más frecuente entre todas sus filas.
#}

{{ config(materialized='table') }}

select
      id_periodista
    , nombre
    , apellidos
    , email
    , biografia
    , _loaded_at
from {{ ref('stg_sql_server_dbo__periodista') }}
order by id_periodista
