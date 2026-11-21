{#
    Periódico. Entidad Periodico del modelo (ID_Periodico, Nombre, fecha_creacion).
    En origen hay 10 grafías de 5 periódicos (mayúsculas, espacios y sufijo S.L.).
    El nombre y la fecha de creación son los valores más frecuentes de cada uno.
#}

with base as (

    {{ noticias_base() }}

)

select
      id_periodico
    , mode({{ limpiar_texto('nombre_periodico') }})                      as nombre
    , mode({{ parse_fecha('fecha_creacion_periodico') }})                as fecha_creacion
    , max(_loaded_at)                                                    as _loaded_at
from base
group by id_periodico
