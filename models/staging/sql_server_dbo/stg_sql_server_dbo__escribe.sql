{#
    Escribe: relación noticia-periodista con la marca de autor principal.
    autor_principal llega con 11 grafías (TRUE, S, 1, verdadero, Sí...) y se
    convierte a boolean; un valor desconocido queda en NULL.
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
qualify row_number() over (
    partition by id_noticia, id_periodista
    order by _loaded_at desc
) = 1
