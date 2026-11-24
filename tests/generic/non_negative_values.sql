{# Test genérico: falla con las filas en las que la columna es < 0.
   Para id_categoria e id_fecha, cuyo miembro "sin dato" tiene id 0. #}
{% test non_negative_values(model, column_name) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} < 0

{% endtest %}
