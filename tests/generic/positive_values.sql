{# Test genérico: falla con las filas en las que la columna es <= 0.
   Gobernanza: los ids numéricos son siempre positivos. Uso en YAML:
     tests:
       - positive_values #}
{% test positive_values(model, column_name) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} <= 0

{% endtest %}
