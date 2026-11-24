{#
    Periódico, fila a fila: una fila por fila de noticias.csv (hay 10 grafías de
    5 periódicos; la clave las unifica). El nombre y la fecha de creación más
    frecuentes se eligen en slv_periodico, con un agregado sobre el lote.
#}

with base as (

    {{ noticias_base() }}

)

select
      id_periodico
    , {{ limpiar_texto('nombre_periodico') }}                as nombre
    , {{ parse_fecha('fecha_creacion_periodico') }}          as fecha_creacion
    , _loaded_at
from base