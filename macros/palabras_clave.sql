{#
    Palabras clave de los eventos. Una fila por (evento, palabra clave).

    Reglas:
      1. Salen del título del evento (evento_clave: minúsculas y sin tildes).
         Se parte por cualquier carácter que no sea letra o número, y se
         descartan las palabras de menos de 3 caracteres y las vacías
         (artículos, preposiciones...). Los años se conservan.
      2. La palabra '4chan' del título NO cuenta como palabra clave.
      3. La descripción no aporta palabras, salvo un único token '4chan' cuando
         la descripción contiene esa palabra.
      4. es_distintiva marca las palabras que identifican casi por sí solas al
         evento: 5 o más letras, no numéricas, y presentes en el título de no más
         de `palabras_clave_max_titulos` títulos distintos (1 por defecto, para
         no contar los eventos duplicados con otro id). Ejemplos: 'epstein',
         'vegas', 'fappening'. Las palabras de eventos genéricos repetidos cada
         año ('huelga', 'gredos') no lo son.

    Es el único sitio donde se decide el token: lo usan MEN y MET, así que el
    token es siempre el mismo en ambos. Devuelve un SELECT con
    (id_evento, palabras_clave, es_distintiva, _loaded_at). Uso:
        with tokens as ( {{ eventos_palabras_clave() }} )
#}

{% macro eventos_palabras_clave() -%}
    {%- set palabras_vacias = [
        'del', 'las', 'los', 'una', 'uno', 'unos', 'unas', 'por', 'con', 'sin',
        'que', 'para', 'sus', 'ante', 'entre', 'sobre', 'tras', 'desde', 'hasta',
        'como', 'mas', 'pero', 'muy', 'este', 'esta', 'estos', 'estas', 'ser'
    ] -%}
    {%- set palabras_del_titulo -%}
        select
              e.id_evento
            , e.evento_clave
            , t.value::varchar                              as palabras_clave
            , e._loaded_at
        from {{ ref('stg_sql_server_dbo__evento') }} e,
            lateral flatten(
                input => split(regexp_replace(e.evento_clave, '[^a-z0-9]+', ' '), ' ')
            ) t
        where length(t.value::varchar) >= 3
          and t.value::varchar <> '4chan'
          and t.value::varchar not in (
                {%- for p in palabras_vacias -%}'{{ p }}'{{ ', ' if not loop.last }}{%- endfor -%}
              )
    {%- endset -%}
    select distinct
          t.id_evento
        , t.palabras_clave
        , (    t.palabras_clave <> '4chan'
           and length(t.palabras_clave) >= 5
           and try_to_number(t.palabras_clave) is null
           and f.n_titulos <= {{ var('palabras_clave_max_titulos', 1) }})  as es_distintiva
        , t._loaded_at
    from (

        {{ palabras_del_titulo }}

        union all

        select
              id_evento
            , evento_clave
            , '4chan'
            , _loaded_at
        from {{ ref('stg_sql_server_dbo__evento') }}
        where contains(lower(coalesce(descripcion, '')), '4chan')

    ) t
    left join (

        select palabras_clave, count(distinct evento_clave) as n_titulos
        from (

            {{ palabras_del_titulo }}

        )
        group by palabras_clave

    ) f
        on f.palabras_clave = t.palabras_clave
{%- endmacro %}