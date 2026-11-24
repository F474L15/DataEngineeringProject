{#
    Evento limpio. Entidad Evento del modelo; hecho principal de Gold.

    - Deduplica por id_evento (los IDs 6 y 11 vienen repetidos) y se queda con la
      carga más reciente.
    - Después fusiona los eventos casi duplicados: mismo título (sin distinguir
      mayúsculas de minúsculas) y misma fecha, con IDs distintos. Se queda el de
      descripción más larga y, a igualdad, el de menor id_evento. Un título que
      difiere en algo más (tildes, palabras) NO se fusiona.
    - evento_clave: título sin mayúsculas ni tildes, para el cruce por palabras
      clave en Silver.
    - fecha_evento: NULL si el formato no es reconocible o la fecha no existe
      (31/02/2026, 2026-14-01). Aquí no se descarta nada por fecha: slv_evento
      elimina los eventos sin fecha válida.
#}

with src as (

    select * from {{ source('bronze', 'eventos') }}

),

categorias as (

    select id_categoria, categoria_clave from {{ ref('categorias') }}

),

por_id as (

select
      try_to_number(trim(s.id_evento))                              as id_evento
    , {{ texto_o_blanco(limpiar_texto('s.evento')) }}                as evento
    , {{ texto_o_blanco(clave_texto('s.evento')) }}                  as evento_clave
    , {{ parse_fecha('s.fecha_evento') }}                            as fecha_evento
    , {{ texto_o_blanco(recortar(reparar_encoding('s.descripcion'))) }}  as descripcion
    , coalesce(c.id_categoria, sc.id_categoria)                      as id_categoria
    , {{ texto_o_blanco(limpiar_ubicacion('s.ubicacion')) }}         as ubicacion
    , s._loaded_at
from src s
left join categorias c
    on c.categoria_clave = {{ clave_categoria('s.categoria') }}
-- Sin categoría o categoría no reconocida: la fila 'sin categoria' del seed.
left join categorias sc
    on sc.categoria_clave = 'sin categoria'
qualify row_number() over (
    partition by try_to_number(trim(s.id_evento))
    order by s._loaded_at desc, s.fecha_evento desc nulls last
           , s.evento, s.descripcion nulls last, s.ubicacion nulls last
) = 1

)

select * from por_id
qualify row_number() over (
    partition by lower(evento), fecha_evento
    order by length(trim(descripcion)) desc, id_evento
) = 1