{#
    Noticia · Silver. Incremental por id_noticia (merge).

    - Deduplica el lote por id_noticia (URL normalizada): gana la carga más
      reciente, luego la fecha más reciente y luego la fila con titular
      informado, para que una versión sin titular no pise a la que lo tiene.
    - Ventana de merge de `merge_ventana_dias` días (ver predicado_merge).
    Además de las columnas del modelo se conserva la url normalizada, que es la
    clave de negocio de la que sale id_noticia (sin ella el ID, que es un hash, no
    se puede trazar).
#}

{{ config(
    materialized='incremental',
    unique_key='id_noticia',
    incremental_predicates=predicado_merge()
) }}

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
qualify row_number() over (
    partition by id_noticia
    order by _loaded_at desc, fecha_publicacion desc nulls last
           , (titular = ' ') asc, titular
) = 1