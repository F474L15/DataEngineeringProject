{#
    Macros de carga incremental. Diseñadas para ~7.000 posts y ~7.000 noticias
    cada 10 minutos (≈ 1 M filas al día de cada una).

    filtro_incremental(columna, marca)
      En la primera ejecución y con --full-refresh no filtra. En las siguientes deja
      pasar solo lo que tiene `columna` posterior a la última marca de la tabla,
      restando un margen (`incremental_margen_minutos`, 30 por defecto). El margen
      cubre cargas de Bronze que terminan después de otra posterior; es seguro
      porque todos los modelos hacen merge por clave (reprocesar no duplica).
      `marca` es la columna de la tabla destino de la que sale el máximo; por defecto
      la misma `columna`. El coalesce evita que `_loaded_at > NULL` descarte todo
      cuando la tabla existe pero está vacía.
      IMPORTANTE: el filtro tiene que llegar a Bronze. Los modelos de staging son
      vistas fila a fila (sin deduplicar ni agrupar) para que Snowflake pueda
      empujar este filtro hasta la tabla de origen.

    predicado_merge(dias)
      Para las tablas grandes (post, noticia, escribe y sus dimensiones). Limita las
      filas de la tabla destino que el merge compara a las cargadas en los últimos
      `merge_ventana_dias` (3 por defecto). Sin él, cada lote tocaría casi todas las
      particiones, porque el ID es un hash. Un duplicado que reaparezca pasada la
      ventana quedaría como fila nueva: lo detectan los tests de unicidad.
#}
{% macro filtro_incremental(columna='_loaded_at', marca=none) -%}
    {%- if is_incremental() -%}
    where {{ columna }} > dateadd(
        minute
      , -{{ var('incremental_margen_minutos', 30) }}
      , coalesce((select max({{ marca or columna }}) from {{ this }}), '1900-01-01'::timestamp_ltz)
    )
    {%- endif -%}
{%- endmacro %}


{% macro predicado_merge(dias=none) -%}
    {{ return(["DBT_INTERNAL_DEST._loaded_at > dateadd(day, -" ~ (dias or var('merge_ventana_dias', 3)) ~ ", current_timestamp())"]) }}
{%- endmacro %}
