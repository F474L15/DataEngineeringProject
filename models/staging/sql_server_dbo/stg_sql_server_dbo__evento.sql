{#
    Evento limpio. Entidad Evento del modelo; hecho principal de Gold.

    - Deduplica por id_evento (los IDs 6 y 11 vienen repetidos) y se queda con la
      carga más reciente. NO fusiona eventos casi duplicados con IDs distintos.
    - evento_clave: título sin mayúsculas ni tildes, para el cruce por palabras
      clave en Silver.
    - fecha_evento: NULL si el formato no es reconocible o la fecha no existe
      (31/02/2026, 2026-14-01). Las fechas futuras se conservan.
#}

with src as (

    select * from {{ source('bronze', 'eventos') }}

),

categorias as (

    select id_categoria, categoria_clave from {{ ref('categorias') }}

)

select
      try_to_number(trim(s.id_evento))                              as id_evento
    , {{ limpiar_texto('s.evento') }}                                as evento
    , {{ clave_texto('s.evento') }}                                  as evento_clave
    , {{ parse_fecha('s.fecha_evento') }}                            as fecha_evento
    , {{ recortar(reparar_encoding('s.descripcion')) }}              as descripcion
    , c.id_categoria
    , {{ limpiar_ubicacion('s.ubicacion') }}                         as ubicacion
    , s._loaded_at
from src s
left join categorias c
    on c.categoria_clave = {{ clave_categoria('s.categoria') }}
qualify row_number() over (
    partition by try_to_number(trim(s.id_evento))
    order by s._loaded_at desc
) = 1
