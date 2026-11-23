{#
    Periodista, fila a fila. La clave ignora el orden de nombre y apellidos,
    porque en origen vienen intercambiados en algunas filas. Los emails sin
    formato válido (sin @, con '#', sin dominio) se descartan aquí; el valor más
    frecuente de cada campo se elige en slv_periodista.
#}

with base as (

    {{ noticias_base() }}

)

select
      id_periodista
    , {{ limpiar_texto('nombre_periodista') }}               as nombre
    , {{ limpiar_texto('apellidos_periodista') }}            as apellidos
    , case
          when regexp_like(lower(trim(email_periodista)), '[^@\\s]+@[^@\\s]+\\.[^@\\s]+')
          then lower(trim(email_periodista))
      end                                                    as email
    , {{ recortar('biografia_periodista') }}                 as biografia
    , _loaded_at
from base