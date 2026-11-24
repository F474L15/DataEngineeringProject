{#
    Evento · Silver. Incremental por id_evento. Pocas filas (unos 20 eventos al
    día), así que el merge compara contra toda la tabla, sin ventana.
    Elimina los eventos cuya fecha no es válida (ilegible, anterior a la fecha
    mínima o futura): sin fecha fiable no se pueden medir minutos ni sanearla.
    Los eventos casi duplicados ya se fusionan en staging.
#}

{{ config(materialized='incremental', unique_key='id_evento') }}

with validos as (

    select * from {{ ref('stg_sql_server_dbo__evento') }}
    where {{ fecha_es_valida('fecha_evento') }}

)

select
      id_evento
    , evento
    , fecha_evento
    , descripcion
    , id_categoria
    , ubicacion
    , _loaded_at
from validos
{{ filtro_incremental() }}