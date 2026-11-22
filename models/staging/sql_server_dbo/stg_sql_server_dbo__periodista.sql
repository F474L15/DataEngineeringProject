{#
    Periodista. Entidad Periodista del modelo (ID_Periodista, Nombre, Apellidos,
    Email, Biografia). La clave ignora el orden de nombre y apellidos, porque en
    origen vienen intercambiados en algunas filas. Cada campo toma su valor más
    frecuente entre las filas del periodista. Los emails que no tienen formato
    válido (sin @, con '#', sin dominio) se descartan antes.
#}

with base as (

    {{ noticias_base() }}

)

select
      id_periodista
    , coalesce(mode({{ limpiar_texto('nombre_periodista') }}), ' ')      as nombre
    , coalesce(mode({{ limpiar_texto('apellidos_periodista') }}), ' ')   as apellidos
    , mode(
        case
            when regexp_like(lower(trim(email_periodista)), '[^@\\s]+@[^@\\s]+\\.[^@\\s]+')
            then lower(trim(email_periodista))
        end
      )                                                                  as email
    , coalesce(mode({{ recortar('biografia_periodista') }}), ' ')        as biografia
    , max(_loaded_at)                                                    as _loaded_at
from base
group by id_periodista
