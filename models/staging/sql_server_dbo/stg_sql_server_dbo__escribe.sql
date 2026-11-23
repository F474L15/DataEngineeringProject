{#
    Escribe, fila a fila: relación noticia-periodista con la marca de autor
    principal. autor_principal llega con 11 grafías (TRUE, S, 1, verdadero, Sí...)
    y se convierte a boolean; un valor desconocido queda en NULL. La
    deduplicación por (noticia, periodista) vive en slv_escribe.
#}

with base as (

    {{ noticias_base() }}

)

select
      abs(hash(id_noticia, id_periodista))                  as id_escribe
    , id_noticia
    , id_periodista
    , {{ a_booleano('autor_principal') }}                    as autor_principal
    , _loaded_at
from base