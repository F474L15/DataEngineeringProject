{#
    Reglas de gobernanza (documentación del proyecto).

    texto_o_blanco(columna): un texto nulo pasa a ' ' (un espacio). Se aplica en
    staging, en el select final, DESPUÉS de calcular claves e ids, porque las
    claves necesitan el null para distinguir "sin dato". No se usa con ids,
    fechas ni booleanos: un ' ' no cabe en una columna numérica o de fecha.
#}

{% macro texto_o_blanco(columna) -%}
    coalesce({{ columna }}, ' ')
{%- endmacro %}
