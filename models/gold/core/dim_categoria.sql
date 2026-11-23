{# 'Sin categoría' (id 16) viene en el seed categorias. #}
select id_categoria, categoria, categoria_clave
from {{ ref('categorias') }}
order by id_categoria