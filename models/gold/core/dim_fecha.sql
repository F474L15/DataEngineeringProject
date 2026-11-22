{# Un día por fila de 2000 a 2030. Miembro desconocido: id_fecha = 0. #}
with dias as (
    select dateadd(day, row_number() over (order by seq4()) - 1, '2000-01-01'::date) as fecha
    from table(generator(rowcount => 11323))
)
select
      to_number(to_char(fecha, 'YYYYMMDD'))   as id_fecha
    , fecha
    , year(fecha)                             as anio
    , quarter(fecha)                          as trimestre
    , month(fecha)                            as mes
    , decode(month(fecha), 1,'enero',2,'febrero',3,'marzo',4,'abril',5,'mayo',6,'junio',
        7,'julio',8,'agosto',9,'septiembre',10,'octubre',11,'noviembre',12,'diciembre') as nombre_mes
    , day(fecha)                              as dia
    , dayofweekiso(fecha)                     as dia_semana
    , decode(dayofweekiso(fecha), 1,'lunes',2,'martes',3,'miércoles',4,'jueves',5,'viernes',6,'sábado',7,'domingo') as nombre_dia
    , dayofweekiso(fecha) >= 6                as es_fin_de_semana
from dias
union all
select 0, null, null, null, null, 'Sin fecha', null, null, 'Sin fecha', null
order by id_fecha
