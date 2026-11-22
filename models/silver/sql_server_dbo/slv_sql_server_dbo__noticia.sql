{#
    Noticia · Silver. Incremental por id_noticia. Además de las columnas del
    modelo se conserva la url normalizada, que es la clave de negocio de la que
    sale id_noticia (sin ella el ID, que es un hash, no se puede trazar).
#}

{{ config(materialized='incremental', unique_key='id_noticia') }}

select
      id_noticia
    , id_periodico
    , titular
    , subtitulo
    , cuerpo
    , imagen
    , id_categoria
    , fecha_publicacion
    , url
    , _loaded_at
from {{ ref('stg_sql_server_dbo__noticia') }}
{{ filtro_incremental() }}
