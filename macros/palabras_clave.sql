{#
    Token de palabras clave de un evento.

    PENDIENTE de definir. Es el único sitio donde se decide cómo se obtiene el
    token a partir del evento; lo usan menciona_evento_noticia (MEN) y
    menciona_evento_thread (MET), así que el token es siempre el mismo en ambos.
    Mientras devuelva NULL, los dos modelos salen vacíos.

    columna: normalmente 'evento_clave' (título sin mayúsculas ni tildes), que
    ya sale de stg_sql_server_dbo__evento.
#}
{% macro palabras_clave_evento(columna) -%}
    cast(null as varchar)
{%- endmacro %}

-- comprobar y estudiar como es la forma más efectiva después