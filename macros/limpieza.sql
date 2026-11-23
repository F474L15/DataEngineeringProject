{#
    Macros de limpieza para staging. Bronze guarda el dato crudo en varchar;
    aquí se normaliza texto, se repara la codificación y se tipan fechas y booleanos.
    Las columnas se pasan como texto: {{ limpiar_texto('titular') }}
#}

{# Recorta y colapsa espacios repetidos. Vacío -> NULL. #}
{% macro limpiar_texto(columna) -%}
    nullif(regexp_replace(trim({{ columna }}), '\\s+', ' '), '')
{%- endmacro %}


{# Solo recorta (conserva saltos de línea). Para cuerpos de noticia y comentarios. #}
{% macro recortar(columna) -%}
    nullif(trim({{ columna }}), '')
{%- endmacro %}


{# Clave de comparación: minúsculas, sin tildes ni espacios sobrantes. #}
{% macro clave_texto(columna) -%}
    translate(lower({{ limpiar_texto(columna) }}), 'áàäâéèëêíìïîóòöôúùüûñç', 'aaaaeeeeiiiioooouuuunc')
{%- endmacro %}


{# Repara texto con la codificación rota (UTF-8 leído como Latin-1: 'compaÃ±Ã­a'). #}
{% macro reparar_encoding(columna) -%}
    {%- set pares = [(195, 179, 'ó'), (195, 186, 'ú'), (195, 173, 'í'), (195, 169, 'é'),
                     (195, 161, 'á'), (195, 177, 'ñ'), (194, 191, '¿'), (195, 129, 'Á')] -%}
    {%- set ns = namespace(expr=columna) -%}
    {%- for a, b, r in pares -%}
        {%- set ns.expr = "replace(" ~ ns.expr ~ ", chr(" ~ a ~ ") || chr(" ~ b ~ "), '" ~ r ~ "')" -%}
    {%- endfor -%}
    {{ ns.expr }}
{%- endmacro %}


{# TRUE/FALSE, true, 1, 0, S, N, Sí, No, verdadero... -> boolean. Otro valor -> NULL. #}
{% macro a_booleano(columna) -%}
    case {{ clave_texto(columna) }}
        when 'true' then true
        when '1' then true
        when 's' then true
        when 'si' then true
        when 'verdadero' then true
        when 'false' then false
        when '0' then false
        when 'n' then false
        when 'no' then false
        when 'falso' then false
    end
{%- endmacro %}


{#
    Fecha en varchar -> timestamp_ntz. Cada formato lleva una guarda regexp_like
    para que 'YYYY-MM-DD' no capture '22-03-24' ni al revés. Si no encaja en
    ninguno (o la fecha no existe, como 31/02/2026) devuelve NULL.
    Zona horaria: no hay información salvo el sufijo Z (UTC) y la época Unix (UTC);
    todo se trata como hora UTC sin zona.
    Formatos vistos: noticias, posts y eventos.
#}
{% macro parse_fecha(columna) -%}
    {%- set c = "trim(" ~ columna ~ ")" -%}
    coalesce(
          case when regexp_like({{ c }}, '\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}')    then try_to_timestamp_ntz({{ c }}, 'YYYY-MM-DD HH24:MI:SS') end
        , case when regexp_like({{ c }}, '\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z')    then try_to_timestamp_ntz({{ c }}, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') end
        , case when regexp_like({{ c }}, '\\d{8}')                                        then try_to_timestamp_ntz({{ c }}, 'YYYYMMDD') end
        , case when regexp_like({{ c }}, '\\d{10}')                                       then to_timestamp_ntz(try_to_number({{ c }}), 0) end
        , case when regexp_like({{ c }}, '\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}')            then try_to_timestamp_ntz({{ c }}, 'DD/MM/YYYY HH24:MI') end
        , case when regexp_like({{ c }}, '\\d{2}/\\d{2}/\\d{4}')                          then try_to_timestamp_ntz({{ c }}, 'DD/MM/YYYY') end
        , case when regexp_like({{ c }}, '\\d{2}-\\d{2}-\\d{4}')                          then try_to_timestamp_ntz({{ c }}, 'DD-MM-YYYY') end
        , case when regexp_like({{ c }}, '\\d{2}-\\d{2}-\\d{2}')                          then try_to_timestamp_ntz({{ c }}, 'DD-MM-YY') end
        , case when regexp_like({{ c }}, '\\d{2} [A-Za-z]{3} \\d{4}')                     then try_to_timestamp_ntz({{ c }}, 'DD MON YYYY') end
        , case when regexp_like({{ c }}, '[A-Za-z]{3} \\d{2}, \\d{4} \\d{2}:\\d{2} (AM|PM)') then try_to_timestamp_ntz({{ c }}, 'MON DD, YYYY HH12:MI AM') end
        , case when regexp_like({{ c }}, '[A-Za-z]{3} \\d{2}, \\d{4}')                    then try_to_timestamp_ntz({{ c }}, 'MON DD, YYYY') end
        , case when regexp_like({{ c }}, '[A-Za-z]{4,9} \\d{2}, \\d{4}')                  then try_to_timestamp_ntz({{ c }}, 'MMMM DD, YYYY') end
        , case when regexp_like({{ c }}, '\\d{4}')                                        then try_to_timestamp_ntz({{ c }} || '-01-01', 'YYYY-MM-DD') end
    )
{%- endmacro %}


{# Ubicación: N/A y Desconocida -> NULL; ' - ' -> ', '; todo mayúsculas/minúsculas -> Initcap. #}
{% macro limpiar_ubicacion(columna) -%}
    {%- set v = "replace(" ~ limpiar_texto(columna) ~ ", ' - ', ', ')" -%}
    case
        when {{ clave_texto(columna) }} is null or {{ clave_texto(columna) }} in ('n/a', 'desconocida') then null
        when {{ v }} = upper({{ v }}) or {{ v }} = lower({{ v }}) then initcap({{ v }})
        else {{ v }}
    end
{%- endmacro %}


{#
    Clave de categoría para unir con el seed `categorias`. Reconduce a su
    categoría las variantes de eventos que no existen como categoría propia.
#}
{% macro clave_categoria(columna) -%}
    case {{ clave_texto(columna) }}
        when 'politica nacional'      then 'politica'
        when 'medioambiente'          then 'medio ambiente'
        when 'economia y empresas'    then 'economia'
        else {{ clave_texto(columna) }}
    end
{%- endmacro %}


{#
    Gobernanza: un texto nulo pasa a ' ' (un espacio). Se aplica en staging, en el
    select final, DESPUÉS de calcular claves e ids, porque las claves necesitan el
    null para distinguir "sin dato". No se usa con ids, fechas ni booleanos: un ' '
    no cabe en una columna numérica o de fecha. url y email se quedan en NULL.
#}
{% macro texto_o_blanco(columna) -%}
    coalesce({{ columna }}, ' ')
{%- endmacro %}


{# Una fecha es válida si existe, no es anterior a la fecha mínima ni futura.
   Mínima ajustable con --vars '{fecha_minima_valida: 2005-01-01}'. #}
{% macro fecha_es_valida(columna) -%}
    ({{ columna }} is not null
     and {{ columna }} >= '{{ var("fecha_minima_valida", "2009-01-01") }}'::timestamp_ntz
     and {{ columna }} <= sysdate())
{%- endmacro %}